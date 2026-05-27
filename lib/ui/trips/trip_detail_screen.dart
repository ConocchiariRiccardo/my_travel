import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../auth/auth_view_model.dart';
import '../../domain/models/attivita.dart';
import 'trip_detail_view_model.dart';

class TripDetailScreen extends StatefulWidget {
  final String viaggioId;
  final TripDetailViewModel? viewModel;

  const TripDetailScreen({
    super.key,
    required this.viaggioId,
    this.viewModel,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  late final TripDetailViewModel _viewModel;
  late final bool _ownsViewModel;
  final _uuid = const Uuid();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? TripDetailViewModel();
    final userId = context.read<AuthViewModel>().currentUser!.uid;
    _viewModel.inizializza(userId, widget.viaggioId);
  }

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _apriBooking(String destinazione) async {
    final query = Uri.encodeComponent(destinazione);
    final uri = Uri.parse('https://www.booking.com/search.html?ss=$query');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire Booking.'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _apriSkyscanner(String destinazione) async {
    final query = Uri.encodeComponent(destinazione);
    final uri = Uri.parse(
      'https://www.skyscanner.it/trasporti/voli/results/?query=$query',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire Skyscanner.'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _mostraDialogAggiungiAttivita() async {
    final controller = TextEditingController();
    final userId = context.read<AuthViewModel>().currentUser!.uid;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Nuova attività',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'es. Riunione con cliente',
              hintStyle: const TextStyle(color: textSecondary),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Annulla',
                style: TextStyle(color: textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Aggiungi'),
            ),
          ],
        );
      },
    );

    final testo = controller.text.trim();
    controller.dispose();

    if (testo.isEmpty) return;

    final nuovaAttivita = Attivita(id: _uuid.v4(), nome: testo);
    final success = await _viewModel.aggiungi(
      userId,
      widget.viaggioId,
      nuovaAttivita,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage ?? 'Errore sconosciuto.'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _confermaCompletamento() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Concludi viaggio',
            key: const Key('conclude-dialog-title'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          content: const Text(
            'Vuoi spostare questo viaggio nello storico? Non sarà più modificabile.',
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              key: const Key('conclude-cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Annulla',
                style: TextStyle(color: textSecondary),
              ),
            ),
            FilledButton(
              key: const Key('conclude-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Concludi'),
            ),
          ],
        );
      },
    );

    if (conferma != true) return;

    final userId = context.read<AuthViewModel>().currentUser!.uid;
    final success = await _viewModel.completa(userId, widget.viaggioId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaggio spostato nello storico! ✅'),
          backgroundColor: primaryColor,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage ?? 'Errore.'),
          backgroundColor: errorColor,
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
            backgroundColor: backgroundColor,
            body: Center(
              child: CircularProgressIndicator(key: const Key('trip-loading'), color: primaryColor),
            ),
          );
        }

        final viaggio = _viewModel.viaggio;
        if (viaggio == null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              title: const Text('Dettaglio viaggio'),
              centerTitle: true,
              elevation: 0,
              backgroundColor: backgroundColor,
              foregroundColor: textPrimary,
              surfaceTintColor: Colors.transparent,
            ),
            body: const Center(
              child: Text(
                'Viaggio non trovato.',
                style: TextStyle(color: textSecondary),
              ),
            ),
          );
        }

        final userId = context.read<AuthViewModel>().currentUser!.uid;
        final attivita = _viewModel.attivita;
        final percentuale = _viewModel.percentualeCompletamento;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text(
              'Dettaglio viaggio',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: backgroundColor,
            foregroundColor: textPrimary,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: textPrimary),
            actions: [
              TextButton(
                key: const Key('complete-trip-btn'),
                onPressed: _confermaCompletamento,
                child: const Text(
                  'Concludi',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            key: const Key('trip-scroll'),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _TripHeaderCard(
                nome: viaggio.nome,
                destinazione: viaggio.destinazione,
                dataInizio: viaggio.dataInizio,
                dataFine: viaggio.dataFine,
                giorniAllaPartenza: viaggio.giorniAllaPartenza,
                isInCorso: viaggio.isInCorso,
                dateFormat: _dateFormat,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Link utili'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionTile(
                      label: 'Booking',
                      icon: Icons.hotel_outlined,
                      onTap: () => _apriBooking(viaggio.destinazione),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionTile(
                      label: 'Skyscanner',
                      icon: Icons.flight_outlined,
                      onTap: () => _apriSkyscanner(viaggio.destinazione),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Attività'),
                  TextButton.icon(
                    key: const Key('add-activity-btn'),
                    onPressed: _mostraDialogAggiungiAttivita,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Aggiungi'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                    ),
                  ),
                ],
              ),
              if (attivita.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            key: const Key('trip-progress'),
                            value: percentuale,
                            backgroundColor: Colors.grey.shade200,
                            color: primaryColor,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(percentuale * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 12),
              if (attivita.isEmpty)
                _EmptyAttivita(
                  onAggiungi: _mostraDialogAggiungiAttivita,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: attivita.asMap().entries.map((entry) {
                      final index = entry.key;
                      final a = entry.value;

                      return Column(
                        children: [
                          _AttivitaTile(
                            attivita: a,
                            onToggle: () =>
                                _viewModel.toggle(userId, widget.viaggioId, a),
                            onDelete: () => _viewModel.elimina(
                                userId, widget.viaggioId, a.id),
                          ),
                          if (index != attivita.length - 1)
                            const Divider(height: 1, color: borderColor),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionTitle('Spese'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: ListTile(
                  key: const Key('manage-expenses-button'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Gestisci spese e scontrini',
                    style: TextStyle(
                      fontSize: 15,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: textSecondary,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/expenses',
                      arguments: widget.viaggioId,
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String titolo) {
    return Text(
      titolo,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _TripHeaderCard extends StatelessWidget {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final String nome;
  final String destinazione;
  final DateTime dataInizio;
  final DateTime dataFine;
  final int giorniAllaPartenza;
  final bool isInCorso;
  final DateFormat dateFormat;

  const _TripHeaderCard({
    required this.nome,
    required this.destinazione,
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
      countdownTesto = 'Partenza oggi';
      countdownColore = Colors.orange.shade700;
    } else if (giorniAllaPartenza > 0) {
      countdownTesto =
          'Tra $giorniAllaPartenza ${giorniAllaPartenza == 1 ? "giorno" : "giorni"}';
      countdownColore = primaryColor;
    } else {
      countdownTesto = 'Concluso';
      countdownColore = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.flight_rounded,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      key: const Key('trip-title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destinazione,
                            key: const Key('trip-destination'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoMiniBlock(
                  label: 'Partenza',
                  value: dateFormat.format(dataInizio),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoMiniBlock(
                  label: 'Ritorno',
                  value: dateFormat.format(dataFine),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: countdownColore.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              countdownTesto,
              key: const Key('trip-countdown'),
              style: TextStyle(
                color: countdownColore,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMiniBlock extends StatelessWidget {
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final String label;
  final String value;

  const _InfoMiniBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('quicklink-$label'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Apri',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttivitaTile extends StatelessWidget {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color errorColor = Color(0xFFF44336);

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: GestureDetector(
        key: Key('activity-toggle-${attivita.id}'),
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: attivita.isCompletata ? primaryColor : Colors.transparent,
            border: Border.all(
              color:
                  attivita.isCompletata ? primaryColor : Colors.grey.shade400,
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
        key: Key('activity-title-${attivita.id}'),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          decoration: attivita.isCompletata
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          color: attivita.isCompletata ? Colors.grey.shade400 : Colors.black87,
        ),
      ),
      trailing: IconButton(
        key: Key('activity-delete-${attivita.id}'),
        icon: const Icon(
          Icons.delete_outline,
          size: 20,
          color: errorColor,
        ),
        onPressed: onDelete,
      ),
    );
  }
}

class _EmptyAttivita extends StatelessWidget {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final VoidCallback onAggiungi;

  const _EmptyAttivita({required this.onAggiungi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.checklist_rounded, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          const Text(
            'Nessuna attività pianificata',
            key: const Key('empty-activities-title'),
            style: TextStyle(
              color: textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onAggiungi,
            child: const Text(
              '+ Aggiungi la prima attività',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
