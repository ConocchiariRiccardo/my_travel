import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_view_model.dart';
import '../widgets/trip_card.dart';
import 'home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inizializza lo stream una sola volta, quando abbiamo l'userId
    if (!_isInitialized) {
      final userId = context.read<AuthViewModel>().currentUser?.uid;
      if (userId != null) {
        context.read<HomeViewModel>().inizializza(userId);
        _isInitialized = true;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // --- AppBar espandibile ---
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined,
                    color: Colors.white),
                tooltip: 'Calendario',
                onPressed: () => context.push('/calendar'),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: () {}, // Fase 8: profilo
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: const Text(
                'I miei viaggi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                ),
              ),
            ),
          ),

          // --- Barra di ricerca ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (testo) =>
                    context.read<HomeViewModel>().cercaViaggio(testo),
                decoration: InputDecoration(
                  hintText: 'Cerca per nome o destinazione...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<HomeViewModel>().cercaViaggio('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // --- Filtri chip ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 'tutti', 'Tutti', homeVm),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'in_corso', 'In corso', homeVm),
                    const SizedBox(width: 8),
                    _buildFilterChip(context, 'in_arrivo', 'In arrivo', homeVm),
                  ],
                ),
              ),
            ),
          ),

          // --- Contenuto principale ---
          if (homeVm.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (homeVm.errorMessage != null)
            SliverFillRemaining(
              child: _buildErrorState(homeVm.errorMessage!),
            )
          else if (homeVm.viaggi.isEmpty)
            const SliverFillRemaining(
              child: _EmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final viaggio = homeVm.viaggi[index];
                  return TripCard(
                    viaggio: viaggio,
                    onTap: () {
                      // Fase 3: naviga al dettaglio
                      context.push('/trip/${viaggio.id}');
                    },
                    onDelete: () => homeVm.eliminaViaggio(userId, viaggio.id),
                  );
                },
                childCount: homeVm.viaggi.length,
              ),
            ),

          // Spazio sotto l'ultima card (sopra il FAB)
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // --- FAB: aggiungi viaggio ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-trip'),
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuovo viaggio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String valore,
    String etichetta,
    HomeViewModel vm,
  ) {
    final isSelected = vm.filtroCorrente == valore;
    return FilterChip(
      label: Text(etichetta),
      selected: isSelected,
      onSelected: (_) => context.read<HomeViewModel>().impostaFiltro(valore),
      selectedColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white,
    );
  }

  Widget _buildErrorState(String messaggio) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(messaggio, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Widget separato e const per lo stato vuoto (ottimizza i rebuild)
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.luggage_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun viaggio in programma',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Premi il bottone + per aggiungere\nla tua prima trasferta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
