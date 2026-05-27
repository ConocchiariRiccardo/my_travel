import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';
import '../../data/repositories/spesa_repository.dart';
import '../../data/repositories/viaggio_repository.dart';
import '../../data/services/pdf_service.dart';
import '../../domain/models/spesa.dart';
import '../../domain/models/viaggio.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String viaggioId;

  const PdfPreviewScreen({
    super.key,
    required this.viaggioId,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color cardColor = Colors.white;

  final SpesaRepository _spesaRepo = SpesaRepository();
  final ViaggioRepository _viaggioRepo = ViaggioRepository();
  final PdfService _pdfService = PdfService();

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfBytesCache;
  Viaggio? _viaggio;
  List<Spesa> _spese = [];

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    try {
      final userId = context.read<AuthViewModel>().currentUser!.uid;
      final nomeUtente =
          context.read<AuthViewModel>().currentUser?.email ?? 'Utente';

      final risultati = await Future.wait([
        _viaggioRepo.streamAttivi(userId).first,
        _spesaRepo.getSpese(userId, widget.viaggioId),
      ]);

      final listaViaggi = risultati[0] as List<Viaggio>;
      _spese = risultati[1] as List<Spesa>;

      Viaggio? viaggioTrovato;

      try {
        viaggioTrovato = listaViaggi.firstWhere(
          (v) => v.id == widget.viaggioId,
        );
      } catch (_) {
        final storico = await _viaggioRepo.streamCompletati(userId).first;
        try {
          viaggioTrovato = storico.firstWhere(
            (v) => v.id == widget.viaggioId,
          );
        } catch (_) {
          throw Exception('Viaggio non trovato.');
        }
      }

      _viaggio = viaggioTrovato;

      final bytes = await _pdfService.generaReportSpese(
        viaggio: _viaggio!,
        spese: _spese,
        nomeUtente: nomeUtente,
      );

      _pdfBytesCache = Uint8List.fromList(bytes);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Errore nella generazione del report PDF.';
        _isLoading = false;
      });
    }
  }

  Future<void> _riprova() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pdfBytesCache = null;
      _viaggio = null;
      _spese = [];
    });

    await _caricaDati();
  }

  Future<void> _condividiPdf() async {
    if (_pdfBytesCache == null || _viaggio == null) return;

    try {
      await Printing.sharePdf(
        bytes: _pdfBytesCache!,
        filename:
            'report_${_sanitizeFileName(_viaggio!.destinazione)}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nella condivisione del report.'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  String _sanitizeFileName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  double get _totaleSpese {
    return _spese.fold<double>(0.0, (sum, item) => sum + item.importo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Report Spese',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildSectionTitle('Report'),
          const SizedBox(height: 12),
          _buildStatusCard(
            icon: Icons.picture_as_pdf_outlined,
            iconColor: primaryColor,
            title: 'Preparazione del report in corso',
            subtitle:
                'Stiamo generando il PDF e raccogliendo i dati delle spese del viaggio.',
            child: const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(color: primaryColor),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildSectionTitle('Report'),
          const SizedBox(height: 12),
          _buildStatusCard(
            icon: Icons.error_outline_rounded,
            iconColor: errorColor,
            title: 'Impossibile generare il report',
            subtitle:
                'Si è verificato un problema durante il caricamento dei dati necessari.',
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _riprova,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Riprova',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _buildSectionTitle('Riepilogo report'),
        const SizedBox(height: 12),
        _buildSummaryCard(),
        const SizedBox(height: 20),
        _buildSectionTitle('Anteprima spese'),
        const SizedBox(height: 12),
        _buildReportPreviewCard(),
        const SizedBox(height: 20),
        _buildInfoCard(),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _condividiPdf,
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text(
              'Condividi report PDF',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final viaggio = _viaggio!;
    final durata = viaggio.dataFine.difference(viaggio.dataInizio).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: primaryColor,
                  size: 22,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      viaggio.destinazione,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Periodo',
                  value:
                      '${_dateFormat.format(viaggio.dataInizio)} - ${_dateFormat.format(viaggio.dataFine)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Durata',
                  value: '$durata ${durata == 1 ? 'giorno' : 'giorni'}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  label: 'Spese',
                  value: '${_spese.length}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  label: 'Totale',
                  value: '€ ${_totaleSpese.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dettaglio spese',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Una vista rapida dei movimenti inclusi nel report.',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_spese.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: textSecondary,
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Nessuna spesa presente',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Il report PDF verrà comunque generato con i dati disponibili.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._spese.asMap().entries.map((entry) {
              final index = entry.key;
              final spesa = entry.value;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForCategory(spesa.categoria),
                          color: primaryColor,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spesa.descrizione,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${spesa.categoria} • ${_dateFormat.format(spesa.data)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '€ ${spesa.importo.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (index != _spese.length - 1) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: borderColor),
                    const SizedBox(height: 14),
                  ],
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: primaryColor,
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Questa schermata mostra un’anteprima leggibile delle spese incluse nel report. Per esportare il documento completo in PDF, usa il pulsante in basso.',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  IconData _iconForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'trasporto':
        return Icons.directions_car_outlined;
      case 'alloggio':
        return Icons.hotel_outlined;
      case 'pasto':
        return Icons.restaurant_outlined;
      case 'taxi':
        return Icons.local_taxi_outlined;
      case 'volo':
        return Icons.flight_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
