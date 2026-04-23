import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_view_model.dart';
import 'home_view_model.dart';
import '../widgets/trip_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Inizializza lo stream dei viaggi appena la schermata si monta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUser!.uid;
      context.read<HomeViewModel>().inizializza(userId);
    });
  }

  Future<void> _confermaEliminazione(
    BuildContext context,
    String userId,
    String viaggioId,
    String nomeViaggio,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina viaggio'),
        content: Text(
            'Sei sicuro di voler eliminare "$nomeViaggio"? L\'azione è irreversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (conferma == true && mounted) {
      await context.read<HomeViewModel>().eliminaViaggio(userId, viaggioId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final homeViewModel = context.watch<HomeViewModel>();
    final userId = authViewModel.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'MyTravel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Bottone Calendario
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Calendario',
            onPressed: () => context.push('/calendar'),
          ),
          // Bottone Profilo
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profilo',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),

      // --- FAB per aggiungere viaggio ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-trip'),
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuovo Viaggio',
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          // --- Barra di ricerca e filtri ---
          _SearchAndFilterBar(
            onSearch: homeViewModel.cercaViaggio,
            filtroCorrente: homeViewModel.filtroCorrente,
            onFiltro: homeViewModel.impostaFiltro,
          ),

          // --- Lista Viaggi ---
          Expanded(
            child: _buildBody(context, homeViewModel, userId),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HomeViewModel vm,
    String userId,
  ) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(vm.errorMessage!),
          ],
        ),
      );
    }

    if (vm.viaggi.isEmpty) {
      return _EmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: vm.viaggi.length,
      itemBuilder: (context, index) {
        final viaggio = vm.viaggi[index];
        return TripCard(
          viaggio: viaggio,
          onTap: () => context.push('/trip/${viaggio.id}'),
          onDelete: () => _confermaEliminazione(
            context,
            userId,
            viaggio.id,
            viaggio.nome,
          ),
        );
      },
    );
  }
}

// --- Widget barra ricerca + chip filtri ---
class _SearchAndFilterBar extends StatelessWidget {
  final ValueChanged<String> onSearch;
  final String filtroCorrente;
  final ValueChanged<String> onFiltro;

  const _SearchAndFilterBar({
    required this.onSearch,
    required this.filtroCorrente,
    required this.onFiltro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Campo di ricerca
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Cerca per nome o destinazione...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),

          const SizedBox(height: 10),

          // Chip filtri
          Row(
            children: [
              _FilterChip(
                label: 'Tutti',
                value: 'tutti',
                filtroCorrente: filtroCorrente,
                onSelected: onFiltro,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '● In corso',
                value: 'in_corso',
                filtroCorrente: filtroCorrente,
                onSelected: onFiltro,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'In arrivo',
                value: 'in_arrivo',
                filtroCorrente: filtroCorrente,
                onSelected: onFiltro,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String filtroCorrente;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.filtroCorrente,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = filtroCorrente == value;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// --- Stato vuoto quando non ci sono viaggi ---
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flight_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun viaggio in programma',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Premi il bottone + per aggiungere\nla tua prima trasferta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
