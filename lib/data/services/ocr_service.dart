import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

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
  // Incolla qui la tua chiave gratuita presa da Google AI Studio
  static const String _apiKey = 'AIzaSyB3zcBXBQ3sTvvNYFZJ199U5p7vFPcNmg8';

  Future<OcrResult> analizzaScontrino(File immagine) async {
    // Configura il modello Gemini imponendogli di sputare solo JSON
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final bytes = await immagine.readAsBytes();
    final mimeType = immagine.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    
    final promptTesto = TextPart('''Analizza questo scontrino/ricevuta e restituisci 
SOLO un oggetto JSON valido con questi campi esatti, senza aggiungere altro testo:
{
  "descrizione": "descrizione sintetica della spesa (es. Pranzo, Hotel, Taxi)",
  "importo": 12.50,
  "categoria": "una di queste: Pasto | Trasporto | Alloggio | Carburante | Altro",
  "data": "YYYY-MM-DD oppure null se non leggibile"
}''');

    final promptImmagine = DataPart(mimeType, bytes);

    try {
      // Invia il colpo all'AI
      final response = await model.generateContent([
        Content.multi([promptTesto, promptImmagine])
      ]);

      final testoRisposta = response.text;
      if (testoRisposta == null || testoRisposta.isEmpty) {
        throw Exception('Risposta vuota dall\'AI');
      }

      // Parliamo col JSON
      final datiEstratti = jsonDecode(testoRisposta) as Map<String, dynamic>;

      // Parse chirurgico della data
      DateTime? dataEstratta;
      if (datiEstratti['data'] != null && datiEstratti['data'].toString() != 'null') {
        try {
          dataEstratta = DateTime.parse(datiEstratti['data'].toString());
        } catch (_) {
          dataEstratta = null;
        }
      }

      // Parse chirurgico dell'importo
      double? importoEstratto;
      if (datiEstratti['importo'] != null) {
        importoEstratto = (datiEstratti['importo'] as num).toDouble();
      }

      return OcrResult(
        descrizione: datiEstratti['descrizione']?.toString() ?? 'Spesa generica',
        importo: importoEstratto,
        categoria: datiEstratti['categoria']?.toString() ?? 'Altro',
        data: dataEstratta,
      );
      
    } catch (e) {
      throw Exception('Errore durante l\'analisi AI: $e');
    }
  }
}