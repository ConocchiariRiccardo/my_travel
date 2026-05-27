import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_view_model.dart';
import '../widgets/trip_card.dart';
import 'home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color primaryColorDark = Color(0xFF233F95);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<HomeViewModel>()
            .inizializza(context.read<AuthViewModel>().currentUser!.uid);
      }
    });
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
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 165,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.location_on_outlined, color: Colors.white),
                tooltip: 'Workspace Finder',
                onPressed: () => Navigator.pushNamed(context, '/workspace'),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined,
                    color: Colors.white),
                tooltip: 'Calendario',
                onPressed: () => Navigator.pushNamed(context, '/calendar'),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                tooltip: 'Profilo',
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'I miei viaggi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestisci trasferte, attività e spese in un unico posto',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColorDark,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 30,
                      child: Icon(
                        Icons.flight_rounded,
                        size: 72,
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (testo) {
                  setState(() {});
                  context.read<HomeViewModel>().cercaViaggio(testo);
                },
                decoration: InputDecoration(
                  hintText: 'Cerca per nome o destinazione...',
                  hintStyle: const TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: textSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                            context.read<HomeViewModel>().cercaViaggio('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Text(
                'Trasferte attive',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          if (homeVm.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final viaggio = homeVm.viaggi[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TripCard(
                        viaggio: viaggio,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/trip',
                            arguments: viaggio.id,
                          );
                        },
                        onDelete: () => homeVm.elimina(userId, viaggio.id),
                      ),
                    );
                  },
                  childCount: homeVm.viaggi.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-trip'),
        backgroundColor: primaryColor,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuovo viaggio',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
      showCheckmark: false,
      selectedColor: primaryColor.withOpacity(0.12),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? primaryColor : borderColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  Widget _buildErrorState(String messaggio) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Connessione non disponibile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              messaggio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);

  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.luggage_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nessun viaggio in programma',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Premi “Nuovo viaggio” per aggiungere la tua prima trasferta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
