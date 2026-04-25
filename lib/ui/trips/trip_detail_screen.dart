import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../auth/auth_view_model.dart';
import '../../domain/models/attivita.dart';
import 'trip_detail_view_model.dart';

class TripDetailScreen extends StatefulWidget {
  final String viaggioId;

  const TripDetailScreen({super.key, required this.viaggioId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late final TripDetailViewModel _viewModel;
  final _uuid = const Uuid();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

  @override
  void initState() {
    super.initState();
    _viewModel = TripDetailViewModel();
    final userId = context.read<AuthViewModel>().currentUser!.uid;
    _viewModel.inizializza(userId, widget.viaggioId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // Apre Booking con la destinazione precompilata
  Future<void> _apriBooking(String destinazione) async {
    final query = Uri.encodeComponent(destinazione);
    final uri = Uri.parse(
      'https://www.booking.com/search.html?ss=$query',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire Booking.')),
        );
      }
    }
  }

  // Apre Skyscanner con la destinazione precompilata
  Future<void> _apriSkyscanner(String destinazione) async {
    final query = Uri.encodeComponent(destinazione);
    final uri = Uri.parse(
      'https://www.skyscanner.it/trasporti/voli/results/?query=$query',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire Skyscanner.')),
        );
      }
    }
  }

  // Dialog per aggiungere una nuova attività
  Future<void> _mostraDialogAggiungiAttivita() async {
    final controller = TextEditingController();
    final userId = context.read<AuthViewModel>().currentUser!.uid;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuova attività'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'es. Riunione con cliente',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    final testo = controller.text.trim();
    if (testo.isEmpty) return;

    final nuovaAttivita = Attivita(id: _uuid.v4(), nome: testo);
    final success = await _viewModel.aggiungiAttivita(
      userId,
      widget.viaggioId,
      nuovaAttivita,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage ?? 'Errore sconosciuto.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    controller.dispose();
  }

  // Dialog conferma completamento viaggio
  Future<void> _confermaCompletamento() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Concludi viaggio'),
        content: const Text(
          'Vuoi spostare questo viaggio nello Storico? '
          'Non sarà più modificabile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            child: const Text('Concludi'),
          ),
        ],
      ),
    );

    if (conferma != true) return;

    final userId = context.read<AuthViewModel>().currentUser!.uid;
    final success = await _viewModel.completaViaggio(userId, widget.viaggioId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaggio spostato nello storico! ✅'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage ?? 'Errore.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final viaggio = _viewModel.viaggio;
        if (viaggio == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dettaglio')),
            body: const Center(child: Text('Viaggio non trovato.')),
          );
        }

        final userId = context.read<AuthViewModel>().currentUser!.uid;
        final attivita = _viewModel.attivita;
        final percentuale = _viewModel.percentualeCompletamento;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: CustomScrollView(
            slivers: [
              // --- AppBar con gradiente ---
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF1E3A8A),
                leading: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    tooltip: 'Concludi viaggio',
                    onPressed: _confermaCompletamento,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viaggio.nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            viaggio.destinazione,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.flight_rounded,
                        size: 80,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Card info date + countdown ---
                      _InfoCard(
                        dataInizio: viaggio.dataInizio,
                        dataFine: viaggio.dataFine,
                        giorniAllaPartenza: viaggio.giorniAllaPartenza,
                        isInCorso: viaggio.isInCorso,
                        dateFormat: _dateFormat,
                      ),

                      const SizedBox(height: 20),

                      // --- Quick Links: Booking + Skyscanner ---
                      _buildSectionTitle('Prenota rapidamente'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickLinkButton(
                              label: 'Booking',
                              icon: Icons.hotel_outlined,
                              colore: const Color(0xFF003580),
                              onTap: () => _apriBooking(viaggio.destinazione),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickLinkButton(
                              label: 'Skyscanner',
                              icon: Icons.flight_outlined,
                              colore: const Color(0xFF0770E3),
                              onTap: () =>
                                  _apriSkyscanner(viaggio.destinazione),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // --- Sezione Attività ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Attività'),
                          TextButton.icon(
                            onPressed: _mostraDialogAggiungiAttivita,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Aggiungi'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),

                      // Barra progresso attività
                      if (attivita.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentuale,
                                  backgroundColor: Colors.grey.shade200,
                                  color: const Color(0xFF1E3A8A),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(percentuale * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Lista attività
                      if (attivita.isEmpty)
                        _EmptyAttivita(
                          onAggiungi: _mostraDialogAggiungiAttivita,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: attivita.map((a) {
                              return _AttivitaTile(
                                attivita: a,
                                onToggle: () => _viewModel.toggleAttivita(
                                    userId, widget.viaggioId, a),
                                onDelete: () => _viewModel.eliminaAttivita(
                                    userId, widget.viaggioId, a.id),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // --- Bottone Spese ---
                      _buildSectionTitle('Spese'),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Fase 5: gestione spese
                            context.push('/trip/${widget.viaggioId}/expenses');
                          },
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Gestisci spese e scontrini'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF1E3A8A)),
                            foregroundColor: const Color(0xFF1E3A8A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String titolo) {
    return Text(
      titolo.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget estratti (const dove possibile)
// ─────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final DateTime dataInizio;
  final DateTime dataFine;
  final int giorniAllaPartenza;
  final bool isInCorso;
  final DateFormat dateFormat;

  const _InfoCard({
    required this.dataInizio,
    required this.dataFine,
    required this.giorniAllaPartenza,
    required this.isInCorso,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    String countdownTesto;
    Color countdownColore;

    if (isInCorso) {
      countdownTesto = 'In corso';
      countdownColore = Colors.green.shade600;
    } else if (giorniAllaPartenza == 0) {
      countdownTesto = 'Partenza oggi!';
      countdownColore = Colors.orange.shade700;
    } else if (giorniAllaPartenza > 0) {
      countdownTesto =
          'Tra $giorniAllaPartenza ${giorniAllaPartenza == 1 ? "giorno" : "giorni"}';
      countdownColore = const Color(0xFF1E3A8A);
    } else {
      countdownTesto = 'Viaggio concluso';
      countdownColore = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partenza',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  dateFormat.format(dataInizio),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ritorno',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  dateFormat.format(dataFine),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: countdownColore.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              countdownTesto,
              style: TextStyle(
                color: countdownColore,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color colore;
  final VoidCallback onTap;

  const _QuickLinkButton({
    required this.label,
    required this.icon,
    required this.colore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colore,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colore.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttivitaTile extends StatelessWidget {
  final Attivita attivita;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AttivitaTile({
    required this.attivita,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: attivita.isCompletata
                ? const Color(0xFF1E3A8A)
                : Colors.transparent,
            border: Border.all(
              color: attivita.isCompletata
                  ? const Color(0xFF1E3A8A)
                  : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: attivita.isCompletata
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        ),
      ),
      title: Text(
        attivita.nome,
        style: TextStyle(
          decoration: attivita.isCompletata
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          color: attivita.isCompletata ? Colors.grey.shade400 : Colors.black87,
        ),
      ),
      trailing: IconButton(
        icon:
            const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
        onPressed: onDelete,
      ),
      dense: true,
    );
  }
}

class _EmptyAttivita extends StatelessWidget {
  final VoidCallback onAggiungi;

  const _EmptyAttivita({required this.onAggiungi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.checklist_rounded, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            'Nessuna attività pianificata',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAggiungi,
            child: const Text('+ Aggiungi la prima attività'),
          ),
        ],
      ),
    );
  }
}
