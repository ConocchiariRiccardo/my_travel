import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../auth/auth_view_model.dart';
import '../../domain/models/spesa.dart';
import 'expense_view_model.dart';

class ExpenseScreen extends StatefulWidget {
  final String viaggioId;

  const ExpenseScreen({super.key, required this.viaggioId});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late final ExpenseViewModel _viewModel;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

  @override
  void initState() {
    super.initState();
    _viewModel = ExpenseViewModel();
    final userId = context.read<AuthViewModel>().currentUser!.uid;
    _viewModel.inizializza(userId, widget.viaggioId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // Icona per categoria spesa
  IconData _iconaCategoria(String categoria) {
    switch (categoria) {
      case 'Pasto':
        return Icons.restaurant_outlined;
      case 'Trasporto':
        return Icons.directions_car_outlined;
      case 'Alloggio':
        return Icons.hotel_outlined;
      case 'Carburante':
        return Icons.local_gas_station_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  // Colore per categoria
  Color _coloreCategoria(String categoria) {
    switch (categoria) {
      case 'Pasto':
        return Colors.orange.shade600;
      case 'Trasporto':
        return Colors.blue.shade600;
      case 'Alloggio':
        return Colors.purple.shade600;
      case 'Carburante':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _confermaElimina(
    BuildContext context,
    String userId,
    Spesa spesa,
  ) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina spesa'),
        content: Text('Eliminare "${spesa.descrizione}"?'),
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
    if (conferma == true) {
      await _viewModel.eliminaSpesa(userId, widget.viaggioId, spesa.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Spese Viaggio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Bottone genera PDF (Fase 6)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Genera PDF',
            onPressed: () => context.push('/trip/${widget.viaggioId}/pdf'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // --- Card riepilogo totale ---
              _buildRiepilogoTotale(),

              // --- Lista spese ---
              Expanded(
                child: _viewModel.spese.isEmpty
                    ? _buildStatoVuoto()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _viewModel.spese.length,
                        itemBuilder: (context, index) {
                          final spesa = _viewModel.spese[index];
                          return _buildSpesaTile(context, userId, spesa);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trip/${widget.viaggioId}/expenses/add'),
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
        label: const Text(
          'Aggiungi spesa',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRiepilogoTotale() {
    final totalePerCategoria = _viewModel.totalePerCategoria;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTALE SPESE',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _viewModel.totaleFormattato,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (totalePerCategoria.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: totalePerCategoria.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${e.key}: €${e.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpesaTile(
    BuildContext context,
    String userId,
    Spesa spesa,
  ) {
    final colore = _coloreCategoria(spesa.categoria);

    return Dismissible(
      key: Key(spesa.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        bool? conferma = false;
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Elimina spesa'),
            content: Text('Eliminare "${spesa.descrizione}"?'),
            actions: [
              TextButton(
                onPressed: () {
                  conferma = false;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () {
                  conferma = true;
                  Navigator.of(ctx).pop();
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Elimina'),
              ),
            ],
          ),
        );
        return conferma;
      },
      onDismissed: (_) =>
          _viewModel.eliminaSpesa(userId, widget.viaggioId, spesa.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colore.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconaCategoria(spesa.categoria),
              color: colore,
              size: 22,
            ),
          ),
          title: Text(
            spesa.descrizione,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${spesa.categoria} · ${_dateFormat.format(spesa.data)}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          trailing: Text(
            spesa.importoFormattato,
            style: TextStyle(
              color: colore,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatoVuoto() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna spesa registrata',
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fotografa uno scontrino per iniziare.',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
