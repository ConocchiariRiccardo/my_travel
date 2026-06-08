import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  Future<OcrResult> analizzaScontrino(File immagine) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY non valorizzata');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-2.5-flash:generateContent?key=$_apiKey',
    );

    final bytes = await immagine.readAsBytes();
    final base64Immagine = base64Encode(bytes);

    final mimeType = immagine.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    final payload = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  '''Analizza questo scontrino/ricevuta e restituisci SOLO un oggetto JSON valido con questi campi esatti, senza testo aggiuntivo:
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
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Errore API Gemini (${response.statusCode}) - ${response.reasonPhrase ?? 'senza dettagli'} - ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

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

    final testoJson =
        testoRisposta.replaceAll('```json', '').replaceAll('```', '').trim();

    final datiEstratti = jsonDecode(testoJson) as Map<String, dynamic>;

    DateTime? dataEstratta;
    final dataRaw = datiEstratti['data'];
    if (dataRaw != null && dataRaw.toString() != 'null') {
      try {
        dataEstratta = DateTime.parse(dataRaw.toString());
      } catch (_) {
        dataEstratta = null;
      }
    }

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
