import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/services/workspace_service.dart';

enum WorkspaceStato { iniziale, caricamento, successo, errore, permessoNegato }

class WorkspaceViewModel extends ChangeNotifier {
  final WorkspaceService _service = WorkspaceService();

  WorkspaceStato _stato = WorkspaceStato.iniziale;
  List<WorkspacePlace> _luoghi = [];
  List<WorkspacePlace> _luoghiFiltrati = [];
  LatLng? _posizioneUtente;
  String? _messaggioErrore;
  String _filtroTipo = 'tutti'; // 'tutti' | 'cafe' | 'coworking' | 'library'
  WorkspacePlace? _luogoSelezionato;
  Set<Marker> _marker = {};

  // --- Getters ---
  WorkspaceStato get stato => _stato;
  List<WorkspacePlace> get luoghi => _luoghiFiltrati;
  LatLng? get posizioneUtente => _posizioneUtente;
  String? get messaggioErrore => _messaggioErrore;
  String get filtroTipo => _filtroTipo;
  WorkspacePlace? get luogoSelezionato => _luogoSelezionato;
  Set<Marker> get marker => _marker;

  /// Entry point: chiede i permessi e avvia la ricerca
  Future<void> inizializza() async {
    _stato = WorkspaceStato.caricamento;
    notifyListeners();

    final permesso = await _richiestaPermesso();
    if (!permesso) {
      _stato = WorkspaceStato.permessoNegato;
      notifyListeners();
      return;
    }

    await _cercaWorkspace();
  }

  Future<bool> _richiestaPermesso() async {
    bool servizioAbilitato = await Geolocator.isLocationServiceEnabled();
    if (!servizioAbilitato) {
      _messaggioErrore = 'Il GPS è disattivato. Abilitalo nelle impostazioni.';
      return false;
    }

    LocationPermission permesso = await Geolocator.checkPermission();
    if (permesso == LocationPermission.denied) {
      permesso = await Geolocator.requestPermission();
      if (permesso == LocationPermission.denied) {
        _messaggioErrore = 'Permesso di geolocalizzazione negato.';
        return false;
      }
    }

    if (permesso == LocationPermission.deniedForever) {
      _messaggioErrore =
          'Permesso negato permanentemente. Abilitalo nelle impostazioni.';
      return false;
    }

    return true;
  }

  Future<void> _cercaWorkspace() async {
    try {
      final posizione = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _posizioneUtente = LatLng(
        posizione.latitude,
        posizione.longitude,
      );

      _luoghi = await _service.cercaWorkspace(
        posizione: _posizioneUtente!,
      );

      _applicaFiltro();
      _costruisciMarker();

      _stato = WorkspaceStato.successo;
      notifyListeners();
    } catch (e) {
      _messaggioErrore =
          'Impossibile trovare workspace nelle vicinanze. Riprova.';
      _stato = WorkspaceStato.errore;
      notifyListeners();
    }
  }

  void impostaFiltro(String tipo) {
    _filtroTipo = tipo;
    _applicaFiltro();
    _costruisciMarker();
    notifyListeners();
  }

  void selezionaLuogo(WorkspacePlace? luogo) {
    _luogoSelezionato = luogo;
    notifyListeners();
  }

  void _applicaFiltro() {
    if (_filtroTipo == 'tutti') {
      _luoghiFiltrati = List.from(_luoghi);
    } else {
      _luoghiFiltrati = _luoghi.where((l) => l.tipo == _filtroTipo).toList();
    }
  }

  void _costruisciMarker() {
    _marker = _luoghiFiltrati.map((luogo) {
      return Marker(
        markerId: MarkerId(luogo.placeId),
        position: luogo.posizione,
        infoWindow: InfoWindow(
          title: '${luogo.iconaTipo} ${luogo.nome}',
          snippet: luogo.indirizzo,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _huePerTipo(luogo.tipo),
        ),
        onTap: () => selezionaLuogo(luogo),
      );
    }).toSet();
  }

  double _huePerTipo(String tipo) {
    switch (tipo) {
      case 'coworking':
        return BitmapDescriptor.hueBlue;
      case 'library':
        return BitmapDescriptor.hueViolet;
      case 'cafe':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Future<void> ricarica() async {
    _luoghi = [];
    _luoghiFiltrati = [];
    _luogoSelezionato = null;
    _messaggioErrore = null;
    await inizializza();
  }
}
