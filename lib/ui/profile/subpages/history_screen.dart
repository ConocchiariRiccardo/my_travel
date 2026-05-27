import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../auth/auth_view_model.dart';
import '../../../data/repositories/viaggio_repository.dart';
import '../../../data/repositories/spesa_repository.dart';
import '../../../domain/models/viaggio.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final ViaggioRepository _viaggioRepo = ViaggioRepository();
  final SpesaRepository _spesaRepo = SpesaRepository();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser!.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Travel History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: StreamBuilder<List<Viaggio>>(
        stream: _viaggioRepo.streamCompletati(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Errore nel caricamento dello storico.',
                style: TextStyle(color: textSecondary),
              ),
            );
          }

          final viaggi = snapshot.data ?? [];

          if (viaggi.isEmpty) {
            return const _StatoVuotoStorico();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: viaggi.length,
            itemBuilder: (context, index) {
              final viaggio = viaggi[index];
              return _HistoryCard(
                viaggio: viaggio,
                userId: userId,
                spesaRepo: _spesaRepo,
                dateFormat: _dateFormat,
                onTap: () =>
                    Navigator.pushNamed(context, '/pdf', arguments: viaggio.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final Viaggio viaggio;
  final String userId;
  final SpesaRepository spesaRepo;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.viaggio,
    required this.userId,
    required this.spesaRepo,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final durata = viaggio.dataFine.difference(viaggio.dataInizio).inDays + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flight_land_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viaggio.nome,
                      style: const TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      viaggio.destinazione,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$durata ${durata == 1 ? "giorno" : "giorni"}',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.calendar_today_outlined,
                  'Periodo',
                  '${dateFormat.format(viaggio.dataInizio)}\n${dateFormat.format(viaggio.dataFine)}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<double>(
                  future: spesaRepo.getTotale(userId, viaggio.id),
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
          const SizedBox(height: 18),
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
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icona, String label, String valore) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icona,
          size: 16,
          color: primaryColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                valore,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatoVuotoStorico extends StatelessWidget {
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);

  const _StatoVuotoStorico();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nessun viaggio completato',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'I viaggi conclusi appariranno qui.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
