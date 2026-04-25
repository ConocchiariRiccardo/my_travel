import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../auth/auth_view_model.dart';
import '../../data/services/expense_service.dart';
import '../../data/services/trip_service.dart';
import '../../data/services/pdf_service.dart';
import '../../domain/models/viaggio.dart';
import '../../domain/models/spesa.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';

class PdfPreviewScreen extends StatefulWidget {
  final String viaggioId;

  const PdfPreviewScreen({super.key, required this.viaggioId});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final TripService _tripService = TripService();
  final PdfService _pdfService = PdfService();

  bool _isLoading = true;
  String? _errorMessage;
  List<int>? _pdfBytes;
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

      // Carica viaggio e spese in parallelo
      final risultati = await Future.wait([
        _tripService.streamViaggioAttivi(userId).first,
        _expenseService.getSpese(userId, widget.viaggioId),
      ]);

      final listaViaggi = risultati[0] as List<Viaggio>;
      _spese = risultati[1] as List<Spesa>;

      // Cerca anche nello storico se non trovato negli attivi
      Viaggio? viaggioTrovato;
      try {
        viaggioTrovato =
            listaViaggi.firstWhere((v) => v.id == widget.viaggioId);
      } catch (_) {
        final storico = await _tripService.streamViaggiCompletati(userId).first;
        try {
          viaggioTrovato = storico.firstWhere((v) => v.id == widget.viaggioId);
        } catch (_) {
          throw Exception('Viaggio non trovato.');
        }
      }

      _viaggio = viaggioTrovato;

      // Genera il PDF
      _pdfBytes = await _pdfService.generaReportSpese(
        viaggio: _viaggio!,
        spese: _spese,
        nomeUtente: nomeUtente,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nella generazione del PDF: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Report Spese'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading && _pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Condividi o Salva',
              onPressed: _condividiPdf,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            SizedBox(height: 20),
            Text(
              'Generazione report in corso...',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _caricaDati();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Anteprima PDF interattiva (zoom, scroll, condivisione nativa)
    return PdfPreview(
      build: (_) async => Uint8List.fromList(_pdfBytes!),
      allowPrinting: true,
      allowSharing: true,
      canChangeOrientation: false,
      canChangePageFormat: false,
      initialPageFormat: PdfPageFormat.a4,
      pdfPreviewPageDecoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _condividiPdf,
          icon: const Icon(Icons.ios_share_outlined),
          tooltip: 'Condividi',
        ),
      ],
    );
  }

  Future<void> _condividiPdf() async {
    if (_pdfBytes == null || _viaggio == null) return;

    try {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(_pdfBytes!),
        filename: 'report_${_viaggio!.destinazione.toLowerCase()}'
            '_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella condivisione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
