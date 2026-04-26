import 'dart:convert';
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
    int raggioMetri = 1500,
  }) async {
    final query = '''
      [out:json][timeout:25];
      (
        node["amenity"="cafe"](around:$raggioMetri,${posizione.latitude},${posizione.longitude});
        node["amenity"="library"](around:$raggioMetri,${posizione.latitude},${posizione.longitude});
        node["office"="coworking"](around:$raggioMetri,${posizione.latitude},${posizione.longitude});
      );
      out center;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
      );

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = decoded['elements'] as List<dynamic>? ?? [];

      return elements.map((e) {
        final tags = e['tags'] as Map<String, dynamic>? ?? {};
        final lat = e['lat'] as double;
        final lon = e['lon'] as double;
        final id = e['id'].toString();

        String tipo = 'cafe';
        if (tags['amenity'] == 'library') tipo = 'library';
        if (tags['office'] == 'coworking') tipo = 'coworking';

        return WorkspacePlace(
          placeId: id,
          nome: tags['name'] ?? 'Workspace Sconosciuto',
          indirizzo:
              tags['street'] ?? tags['addr:street'] ?? 'Indirizzo sulla mappa',
          posizione: LatLng(lat, lon),
          valutazione: 4.5,
          isAperto: true,
          tipo: tipo,
          fotoReference: null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String getFotoUrl(String photoReference, {int maxWidth = 400}) {
    return '';
  }
}
