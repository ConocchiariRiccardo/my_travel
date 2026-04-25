import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../domain/models/viaggio.dart';
import '../../domain/models/spesa.dart';

class PdfService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'it_IT');

  // Colori del brand
  static const PdfColor _bluPrimario = PdfColor.fromInt(0xFF1E3A8A);
  static const PdfColor _bluChiaro = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor _sfondoRiga = PdfColor.fromInt(0xFFF5F7FA);
  static const PdfColor _grigio = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _bordoTabella = PdfColor.fromInt(0xFFE5E7EB);

  /// Genera il documento PDF e restituisce i byte pronti per la stampa/share.
  Future<List<int>> generaReportSpese({
    required Viaggio viaggio,
    required List<Spesa> spese,
    required String nomeUtente,
  }) async {
    final doc = pw.Document();

    // Calcola totali per categoria
    final Map<String, double> totaliCategoria = {};
    for (final spesa in spese) {
      totaliCategoria[spesa.categoria] =
          (totaliCategoria[spesa.categoria] ?? 0) + spesa.importo;
    }
    final double totaleGenerale =
        spese.fold<double>(0.0, (s, e) => s + e.importo);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(viaggio, nomeUtente),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          // --- Riepilogo viaggio ---
          _buildRiepilogoViaggio(viaggio),
          pw.SizedBox(height: 20),
          // --- Tabella spese ---
          _buildTitoloSezione('Dettaglio Spese'),
          pw.SizedBox(height: 8),
          if (spese.isEmpty)
            _buildNessunaSpesa()
          else
            _buildTabellaSpese(spese),
          pw.SizedBox(height: 20),
          // --- Riepilogo per categoria ---
          if (spese.isNotEmpty) ...[
            _buildTitoloSezione('Riepilogo per Categoria'),
            pw.SizedBox(height: 8),
            _buildTabellaCategorie(totaliCategoria, totaleGenerale),
            pw.SizedBox(height: 20),
            // --- Totale finale evidenziato ---
            _buildTotaleFinale(totaleGenerale),
          ],
          pw.SizedBox(height: 24),
          // --- Nota rimborso ---
          _buildNotaRimborso(nomeUtente),
        ],
      ),
    );

    return doc.save();
  }

  // ─── Widget privati del PDF ───────────────────────────────────────────────

  pw.Widget _buildHeader(Viaggio viaggio, String nomeUtente) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _bluPrimario, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MyTravel',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _bluPrimario,
                ),
              ),
              pw.Text(
                'Report Spese Trasferta',
                style: pw.TextStyle(fontSize: 11, color: _grigio),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                nomeUtente,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generato il ${_dateFormat.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: _grigio),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _bordoTabella, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento generato automaticamente da MyTravel',
            style: pw.TextStyle(fontSize: 8, color: _grigio),
          ),
          pw.Text(
            'Pagina ${context.pageNumber} di ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _grigio),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRiepilogoViaggio(Viaggio viaggio) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _sfondoRiga,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _bordoTabella),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            viaggio.nome,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _bluPrimario,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoChip('Destinazione', viaggio.destinazione),
              pw.SizedBox(width: 20),
              _buildInfoChip(
                'Periodo',
                '${_dateFormat.format(viaggio.dataInizio)} → '
                    '${_dateFormat.format(viaggio.dataFine)}',
              ),
              pw.SizedBox(width: 20),
              _buildInfoChip(
                'Durata',
                '${viaggio.dataFine.difference(viaggio.dataInizio).inDays + 1} giorni',
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoChip(String label, String valore) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7,
            color: _grigio,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          valore,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTitoloSezione(String titolo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: _bluPrimario,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        titolo.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _buildTabellaSpese(List<Spesa> spese) {
    // Intestazioni colonne
    final intestazioni = ['#', 'Data', 'Descrizione', 'Categoria', 'Importo'];
    final larghezze = [
      pw.FlexColumnWidth(0.4),
      pw.FlexColumnWidth(1.2),
      pw.FlexColumnWidth(2.8),
      pw.FlexColumnWidth(1.4),
      pw.FlexColumnWidth(1.0),
    ];

    return pw.Table(
      columnWidths: {
        0: larghezze[0],
        1: larghezze[1],
        2: larghezze[2],
        3: larghezze[3],
        4: larghezze[4],
      },
      border: pw.TableBorder.all(color: _bordoTabella, width: 0.5),
      children: [
        // Riga intestazione
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _bluPrimario),
          children: intestazioni
              .map(
                (h) => pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        // Righe dati
        ...spese.asMap().entries.map((entry) {
          final index = entry.key;
          final spesa = entry.value;
          final isDispari = index.isOdd;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isDispari ? _sfondoRiga : PdfColors.white,
            ),
            children: [
              _buildCellaTabella('${index + 1}', centrato: true),
              _buildCellaTabella(_dateFormat.format(spesa.data)),
              _buildCellaTabella(spesa.descrizione),
              _buildCellaTabella(spesa.categoria),
              _buildCellaTabella(
                '€ ${spesa.importo.toStringAsFixed(2)}',
                grassetto: true,
                centrato: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildCellaTabella(
    String testo, {
    bool grassetto = false,
    bool centrato = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        testo,
        textAlign: centrato ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: grassetto ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildTabellaCategorie(
    Map<String, double> totali,
    double totaleGenerale,
  ) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      border: pw.TableBorder.all(color: _bordoTabella, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _sfondoRiga),
          children: ['Categoria', 'Importo', '% sul totale']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _bluPrimario,
                      ),
                    ),
                  ))
              .toList(),
        ),
        ...totali.entries.map((e) {
          final percentuale = totaleGenerale > 0
              ? (e.value / totaleGenerale * 100).toStringAsFixed(1)
              : '0.0';
          return pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children: [
              _buildCellaTabella(e.key),
              _buildCellaTabella('€ ${e.value.toStringAsFixed(2)}',
                  grassetto: true),
              _buildCellaTabella('$percentuale%', centrato: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTotaleFinale(double totale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [_bluPrimario, _bluChiaro],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TOTALE DA RIMBORSARE',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          pw.Text(
            '€ ${totale.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 20,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNessunaSpesa() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      child: pw.Center(
        child: pw.Text(
          'Nessuna spesa registrata per questo viaggio.',
          style: pw.TextStyle(color: _grigio, fontSize: 10),
        ),
      ),
    );
  }

  pw.Widget _buildNotaRimborso(String nomeUtente) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _bordoTabella),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NOTE PER IL RIMBORSO',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _grigio,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Il sottoscritto $nomeUtente dichiara che tutte le spese '
            'riportate nel presente documento sono state sostenute '
            'nell\'interesse dell\'attività lavorativa e ne richiede '
            'il rimborso secondo le policy aziendali vigenti.',
            style: pw.TextStyle(fontSize: 9, color: _grigio),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 120,
                    height: 0.5,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Firma',
                    style: pw.TextStyle(fontSize: 8, color: _grigio),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
