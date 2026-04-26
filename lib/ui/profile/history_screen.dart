import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../auth/auth_view_model.dart';
import '../../data/services/trip_service.dart';
import '../../data/services/expense_service.dart';
import '../../domain/models/viaggio.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TripService _tripService = TripService();
  final ExpenseService _expenseService = ExpenseService();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Storico Viaggi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Viaggio>>(
        stream: _tripService.streamViaggiCompletati(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Errore nel caricamento dello storico.'),
            );
          }

          final viaggi = snapshot.data ?? [];

          if (viaggi.isEmpty) {
            return const _StatoVuotoStorico();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viaggi.length,
            itemBuilder: (context, index) {
              final viaggio = viaggi[index];
              return _HistoryCard(
                viaggio: viaggio,
                userId: userId,
                expenseService: _expenseService,
                dateFormat: _dateFormat,
                onTap: () => context.push('/trip/${viaggio.id}/pdf'),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Viaggio viaggio;
  final String userId;
  final ExpenseService expenseService;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.viaggio,
    required this.userId,
    required this.expenseService,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final durata = viaggio.dataFine.difference(viaggio.dataInizio).inDays + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        children: [
          // --- Header card ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF374151), Color(0xFF6B7280)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.flight_land_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viaggio.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        viaggio.destinazione,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$durata ${durata == 1 ? "giorno" : "giorni"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Body card ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.calendar_today_outlined,
                      'Periodo',
                      '${dateFormat.format(viaggio.dataInizio)}\n→ ${dateFormat.format(viaggio.dataFine)}',
                    ),
                    const SizedBox(width: 16),
                    // Totale spese asincrono
                    Expanded(
                      child: FutureBuilder<double>(
                        future:
                            expenseService.getTotaleSpese(userId, viaggio.id),
                        builder: (context, snap) {
                          final totale = snap.data ?? 0.0;
                          return _buildInfoItem(
                            Icons.euro_outlined,
                            'Totale spese',
                            snap.connectionState == ConnectionState.waiting
                                ? '...'
                                : '€ ${totale.toStringAsFixed(2)}',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Bottone PDF (sola lettura)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 18,
                    ),
                    label: const Text('Visualizza Report PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3A8A),
                      side: const BorderSide(
                        color: Color(0xFF1E3A8A),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icona, String label, String valore) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icona, size: 16, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valore,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatoVuotoStorico extends StatelessWidget {
  const _StatoVuotoStorico();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun viaggio completato',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I viaggi conclusi appariranno qui.',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
