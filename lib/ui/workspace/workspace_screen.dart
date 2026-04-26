import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'workspace_view_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/services/workspace_service.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late final WorkspaceViewModel _viewModel;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _viewModel = WorkspaceViewModel();
    _viewModel.inizializza();
    _viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Quando il ViewModel aggiorna la posizione,
  // centra la mappa automaticamente
  void _onViewModelChange() {
    if (_viewModel.posizioneUtente != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          _viewModel.posizioneUtente!,
          14.5,
        ),
      );
    }
  }

  // Centra la mappa su un luogo selezionato
  void _centraSuLuogo(WorkspacePlace luogo) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(luogo.posizione, 16),
    );
    _viewModel.selezionaLuogo(luogo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Finder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Rcentra su di me',
            onPressed: () {
              if (_viewModel.posizioneUtente != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    _viewModel.posizioneUtente!,
                    14.5,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          switch (_viewModel.stato) {
            case WorkspaceStato.iniziale:
            case WorkspaceStato.caricamento:
              return const _LoadingState();

            case WorkspaceStato.permessoNegato:
              return _PermessoNegatoState(
                messaggio: _viewModel.messaggioErrore ?? '',
              );

            case WorkspaceStato.errore:
              return _ErroreState(
                messaggio: _viewModel.messaggioErrore ?? '',
                onRiprova: _viewModel.ricarica,
              );

            case WorkspaceStato.successo:
              return _buildContenuto();
          }
        },
      ),
    );
  }

  Widget _buildContenuto() {
    final posizioneIniziale = _viewModel.posizioneUtente ??
        const LatLng(41.9028, 12.4964); // Roma come fallback

    return Column(
      children: [
        // --- Filtri ---
        _buildFiltri(),

        // --- Mappa ---
        Expanded(
          flex: 5,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: posizioneIniziale,
              zoom: 14.5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _viewModel.marker,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),

        // --- Lista luoghi / Card selezionata ---
        Expanded(
          flex: 4,
          child: _viewModel.luoghi.isEmpty
              ? const _NessunRisultato()
              : _viewModel.luogoSelezionato != null
                  ? _buildCardDettaglio(_viewModel.luogoSelezionato!)
                  : _buildListaLuoghi(),
        ),
      ],
    );
  }

  Widget _buildFiltri() {
    final filtri = [
      ('tutti', 'Tutti', '📍'),
      ('cafe', 'Caffè', '☕'),
      ('coworking', 'Coworking', '🏢'),
      ('library', 'Biblioteche', '📚'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filtri.map((f) {
            final isSelected = _viewModel.filtroTipo == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Text(f.$3),
                label: Text(f.$2),
                selected: isSelected,
                onSelected: (_) => _viewModel.impostaFiltro(f.$1),
                selectedColor: const Color(0xFF1E3A8A),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                checkmarkColor: Colors.white,
                backgroundColor: Colors.grey.shade100,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListaLuoghi() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _viewModel.luoghi.length,
      itemBuilder: (context, index) {
        final luogo = _viewModel.luoghi[index];
        return _WorkspaceTile(
          luogo: luogo,
          onTap: () => _centraSuLuogo(luogo),
        );
      },
    );
  }

  Widget _buildCardDettaglio(WorkspacePlace luogo) {
    return GestureDetector(
      onTap: () => _viewModel.selezionaLuogo(null),
      child: Container(
        color: const Color(0xFFF5F7FA),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      luogo.iconaTipo,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            luogo.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            luogo.indirizzo,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _viewModel.selezionaLuogo(null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Badge aperto/chiuso
                    _buildBadge(
                      luogo.isAperto ? '● Aperto' : '● Chiuso',
                      luogo.isAperto
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    // Badge tipo
                    _buildBadge(
                      luogo.tipo.toUpperCase(),
                      const Color(0xFF1E3A8A),
                    ),
                    if (luogo.valutazione != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        luogo.valutazione!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Bottone "Apri in Maps"
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _apriInMaps(luogo),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Indicazioni stradali'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String testo, Color colore) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colore.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colore.withOpacity(0.3)),
      ),
      child: Text(
        testo,
        style: TextStyle(
          color: colore,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _apriInMaps(WorkspacePlace luogo) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${luogo.posizione.latitude},${luogo.posizione.longitude}'
      '&destination_place_id=${luogo.placeId}',
    );
    // Riusiamo url_launcher già presente nel progetto
    // ignore: deprecated_member_use
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Widget estratti ─────────────────────────────────────────────────────────

class _WorkspaceTile extends StatelessWidget {
  final WorkspacePlace luogo;
  final VoidCallback onTap;

  const _WorkspaceTile({required this.luogo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(luogo.iconaTipo, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    luogo.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    luogo.indirizzo,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (luogo.valutazione != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        luogo.valutazione!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: luogo.isAperto
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    luogo.isAperto ? 'Aperto' : 'Chiuso',
                    style: TextStyle(
                      color: luogo.isAperto
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF1E3A8A)),
          SizedBox(height: 20),
          Text(
            'Ricerca workspace nelle vicinanze...',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermessoNegatoState extends StatelessWidget {
  final String messaggio;

  const _PermessoNegatoState({required this.messaggio});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_outlined,
                size: 72, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Posizione non disponibile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              messaggio,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Apri Impostazioni'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErroreState extends StatelessWidget {
  final String messaggio;
  final VoidCallback onRiprova;

  const _ErroreState({
    required this.messaggio,
    required this.onRiprova,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              messaggio,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRiprova,
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
}

class _NessunRisultato extends StatelessWidget {
  const _NessunRisultato();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Nessun workspace trovato\nnelle vicinanze.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
