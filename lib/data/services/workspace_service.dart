import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WorkspacePlace {
  final String placeId;
  final String nome;
  final String indirizzo;
  final LatLng posizione;
  final double? valutazione;
  final bool isAperto;
  final String tipo;
  final String? fotoReference;

  const WorkspacePlace({
    required this.placeId,
    required this.nome,
    required this.indirizzo,
    required this.posizione,
    this.valutazione,
    required this.isAperto,
    required this.tipo,
    this.fotoReference,
  });

  String get iconaTipo {
    switch (tipo) {
      case 'coworking':
        return '🏢';
      case 'cafe':
        return '☕';
      case 'library':
        return '📚';
      default:
        return '📍';
    }
  }
}

class WorkspaceService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  Future<List<WorkspacePlace>> cercaWorkspace({
    required LatLng posizione,
    int raggioMetri = 2000,
  }) async {
    final lat = posizione.latitude;
    final lon = posizione.longitude;

    // OTTMIZZAZIONE ARCHITETTO: Filtro Qualità
    // Le biblioteche e i coworking vengono presi sempre.
    // I caffè vengono presi SOLO se hanno il tag "internet_access" compilato.
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="library"](around:$raggioMetri,$lat,$lon);
  way["amenity"="library"](around:$raggioMetri,$lat,$lon);
  
  node["office"="coworking"](around:$raggioMetri,$lat,$lon);
  way["office"="coworking"](around:$raggioMetri,$lat,$lon);
  
  node["amenity"="coworking_space"](around:$raggioMetri,$lat,$lon);
  way["amenity"="coworking_space"](around:$raggioMetri,$lat,$lon);
  
  node["amenity"="cafe"]["internet_access"](around:$raggioMetri,$lat,$lon);
  way["amenity"="cafe"]["internet_access"](around:$raggioMetri,$lat,$lon);
);
out center;
''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {
          'User-Agent':
              'MyTravelApp/1.0 (Contatto: omar.rancitelli@univaq.student.it)'
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Overpass API non disponibile (HTTP ${response.statusCode}). Riprova più tardi.',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded['elements'] as List<dynamic>? ?? [];

      // DEBUG: Stampiamo in console quanti risultati veri ci manda OSM
      debugPrint(
          '🌍 OVERPASS API: Ricevuti ${elements.length} elementi grezzi da OSM.');

      final List<WorkspacePlace> risultati = [];

      for (final e in elements) {
        final tags = e['tags'] as Map<String, dynamic>? ?? {};

        // OTTMIZZAZIONE ARCHITETTO: Non scartiamo i luoghi senza nome!
        // Diamo un nome generico in base alla loro categoria.
        String? nome = tags['name'] as String?;
        if (nome == null || nome.trim().isEmpty) {
          if (tags['amenity'] == 'cafe') {
            nome = 'Caffè Locale';
          } else if (tags['amenity'] == 'library') {
            nome = 'Biblioteca Pubblica';
          } else {
            nome = 'Spazio Coworking';
          }
        }

        final double? elLat;
        final double? elLon;

        if (e['type'] == 'node') {
          elLat = (e['lat'] as num?)?.toDouble();
          elLon = (e['lon'] as num?)?.toDouble();
        } else {
          // way: le coordinate sono nel sotto-oggetto "center"
          final center = e['center'] as Map<String, dynamic>?;
          elLat = (center?['lat'] as num?)?.toDouble();
          elLon = (center?['lon'] as num?)?.toDouble();
        }

        // Salta elementi con coordinate malformate
        if (elLat == null || elLon == null) continue;

        final String id = '${e['type']}_${e['id']}';

        // Determina il tipo di luogo dai tag OSM
        String tipo = 'cafe';
        if (tags['amenity'] == 'library') tipo = 'library';
        if (tags['office'] == 'coworking' ||
            tags['amenity'] == 'coworking_space') {
          tipo = 'coworking';
        }

        // Indirizzo
        String indirizzo = 'Indirizzo sulla mappa';
        final strada = tags['addr:street'] as String?;
        final numero = tags['addr:housenumber'] as String?;
        final addrFull = tags['addr:full'] as String?;

        if (strada != null) {
          indirizzo = numero != null ? '$strada, $numero' : strada;
        } else if (addrFull != null) {
          indirizzo = addrFull;
        }

        risultati.add(
          WorkspacePlace(
            placeId: id,
            nome: nome.trim(),
            indirizzo: indirizzo,
            posizione: LatLng(elLat, elLon),
            valutazione: null,
            isAperto: true,
            tipo: tipo,
            fotoReference: null,
          ),
        );
      }

      return risultati;
    } catch (e) {
      debugPrint('WorkspaceService ERROR: $e');
      rethrow;
    }
  }

  String getFotoUrl(String photoReference, {int maxWidth = 400}) {
    return '';
  }
}
