import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Risultato dell'estrazione OCR dallo scontrino
class OcrResult {
  final String descrizione;
  final double? importo;
  final String categoria;
  final DateTime? data;

  const OcrResult({
    required this.descrizione,
    this.importo,
    required this.categoria,
    this.data,
  });
}

class OcrService {
  static const String _apiKey = 'AIzaSyC16NdBax9Pr-VuEJhW7NQJfyEI_VTILWc';

  // Chiamata diretta all'endpoint v1
  // con il modello gemini-1.5-flash che supporta immagini sul free tier
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.5-flash:generateContent?key=$_apiKey';

  Future<OcrResult> analizzaScontrino(File immagine) async {
    // Legge i byte e li converte in base64 per il payload JSON
    final bytes = await immagine.readAsBytes();
    final base64Immagine = base64Encode(bytes);

    final mimeType = immagine.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    // Payload conforme alle specifiche REST di Gemini v1
    final payload = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': '''Analizza questo scontrino/ricevuta e restituisci 
SOLO un oggetto JSON valido con questi campi esatti, senza testo aggiuntivo:
{
  "descrizione": "descrizione sintetica della spesa (es. Pranzo, Hotel, Taxi)",
  "importo": 12.50,
  "categoria": "una di queste: Pasto | Trasporto | Alloggio | Carburante | Altro",
  "data": "YYYY-MM-DD oppure null se non leggibile"
}'''
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Immagine,
              }
            }
          ]
        }
      ],
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode != 200) {
      // Proviamo a estrarre il messaggio di errore da Google
      String messaggioErrore = 'HTTP ${response.statusCode}';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        final errore = errJson['error'] as Map<String, dynamic>?;
        messaggioErrore = errore?['message'] as String? ?? messaggioErrore;
      } catch (_) {}
      throw Exception('Errore API Gemini: $messaggioErrore');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // Naviga la struttura di risposta REST di Gemini v1
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Nessuna risposta generata dal modello AI.');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final testoRisposta = parts?[0]['text'] as String?;

    if (testoRisposta == null || testoRisposta.trim().isEmpty) {
      throw Exception('Risposta vuota dall\'AI.');
    }

    // Pulizia difensiva: rimuove eventuali backtick markdown
    // nel caso il modello li includa nonostante il response_mime_type
    final testoJson =
        testoRisposta.replaceAll('```json', '').replaceAll('```', '').trim();

    final datiEstratti = jsonDecode(testoJson) as Map<String, dynamic>;

    // Parse chirurgico della data
    DateTime? dataEstratta;
    final dataRaw = datiEstratti['data'];
    if (dataRaw != null && dataRaw.toString() != 'null') {
      try {
        dataEstratta = DateTime.parse(dataRaw.toString());
      } catch (_) {
        dataEstratta = null;
      }
    }

    // Parse chirurgico dell'importo
    double? importoEstratto;
    final importoRaw = datiEstratti['importo'];
    if (importoRaw != null) {
      importoEstratto = (importoRaw as num).toDouble();
    }

    return OcrResult(
      descrizione: datiEstratti['descrizione']?.toString() ?? 'Spesa generica',
      importo: importoEstratto,
      categoria: datiEstratti['categoria']?.toString() ?? 'Altro',
      data: dataEstratta,
    );
  }
}
