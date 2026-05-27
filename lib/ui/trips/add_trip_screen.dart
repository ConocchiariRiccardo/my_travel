import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../auth/auth_view_model.dart';
import '../../domain/models/viaggio.dart';
import '../../domain/models/attivita.dart';
import '../../data/repositories/viaggio_repository.dart';
import '../../data/services/notification_service.dart';

class AddTripScreen extends StatefulWidget {
  final ViaggioRepository? viaggioRepository;

  const AddTripScreen({
    super.key,
    this.viaggioRepository,
  });

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _destinazioneController = TextEditingController();
  final _attivitaController = TextEditingController();
  late final ViaggioRepository _viaggioRepo;
  final _uuid = const Uuid();

  DateTime? _dataInizio;
  DateTime? _dataFine;
  final List<Attivita> _attivita = [];
  bool _isLoading = false;

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'it_IT');

  @override
  void initState() {
    super.initState();
    _viaggioRepo = widget.viaggioRepository ?? ViaggioRepository();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _destinazioneController.dispose();
    _attivitaController.dispose();
    super.dispose();
  }

  Future<void> _selezionaData({required bool isInizio}) async {
    final oggi = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isInizio ? oggi : (_dataInizio ?? oggi),
      firstDate: oggi,
      lastDate: DateTime(oggi.year + 3),
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isInizio) {
        _dataInizio = picked;
        if (_dataFine != null && _dataFine!.isBefore(picked)) {
          _dataFine = null;
        }
      } else {
        _dataFine = picked;
      }
    });
  }

  void _aggiungiAttivita() {
    final testo = _attivitaController.text.trim();
    if (testo.isEmpty) return;

    setState(() {
      _attivita.add(
        Attivita(
          id: _uuid.v4(),
          nome: testo,
        ),
      );
      _attivitaController.clear();
    });
  }

  void _rimuoviAttivita(String id) {
    setState(() {
      _attivita.removeWhere((a) => a.id == id);
    });
  }

  Future<void> _salvaViaggio() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataInizio == null || _dataFine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona le date di inizio e fine viaggio.'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthViewModel>().currentUser!.uid;

      final nuovoViaggio = Viaggio(
        id: '',
        userId: userId,
        nome: _nomeController.text.trim(),
        destinazione: _destinazioneController.text.trim(),
        dataInizio: _dataInizio!,
        dataFine: _dataFine!,
      );

      final viaggioId = await _viaggioRepo.crea(userId, nuovoViaggio);

      final notifService = NotificationService();
      await notifService.schedulaNotificaPartenza(
        userId: userId,
        id: notifService.idDaViaggioId(viaggioId),
        nomeViaggio: nuovoViaggio.nome,
        destinazione: nuovoViaggio.destinazione,
        dataPartenza: nuovoViaggio.dataInizio,
      );

      for (final attivita in _attivita) {
        await _viaggioRepo.aggiungi(userId, viaggioId, attivita);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaggio creato con successo! ✈️'),
          backgroundColor: primaryColor,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il salvataggio. Riprova.'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Nuovo Viaggio',
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _salvaViaggio,
                    child: const Text(
                      'Salva',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            _buildSectionTitle('Informazioni viaggio'),
            const SizedBox(height: 12),
            _buildLabeledField(
              label: 'Nome viaggio',
              controller: _nomeController,
              hintText: 'es. Trasferta Milano Q1',
              icon: Icons.work_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 14),
            _buildLabeledField(
              label: 'Destinazione',
              controller: _destinazioneController,
              hintText: 'es. Milano, Roma, Berlino',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Date'),
            const SizedBox(height: 12),
            _buildDateCard(
              label: 'Data inizio',
              icon: Icons.flight_takeoff_rounded,
              data: _dataInizio,
              onTap: () => _selezionaData(isInizio: true),
            ),
            const SizedBox(height: 12),
            _buildDateCard(
              label: 'Data fine',
              icon: Icons.flight_land_rounded,
              data: _dataFine,
              onTap: () => _selezionaData(isInizio: false),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Attività pianificate'),
            const SizedBox(height: 4),
            const Text(
              'Opzionale',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _attivitaController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _fieldDecoration(
                      hintText: 'Aggiungi un\'attività...',
                      icon: Icons.checklist_rounded,
                    ),
                    onSubmitted: (_) => _aggiungiAttivita(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  width: 52,
                  child: ElevatedButton(
                    onPressed: _aggiungiAttivita,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            if (_attivita.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: _attivita.asMap().entries.map((entry) {
                    final index = entry.key;
                    final a = entry.value;

                    return Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.radio_button_unchecked,
                              size: 18,
                              color: primaryColor,
                            ),
                          ),
                          title: Text(
                            a.nome,
                            style: const TextStyle(
                              fontSize: 15,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: errorColor,
                            ),
                            onPressed: () => _rimuoviAttivita(a.id),
                          ),
                        ),
                        if (index != _attivita.length - 1)
                          const Divider(height: 1, color: borderColor),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvaViaggio,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Crea viaggio',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: primaryColor,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            fontSize: 15,
            color: textPrimary,
          ),
          decoration: _fieldDecoration(
            hintText: hintText,
            icon: icon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateCard({
    required String label,
    required IconData icon,
    required DateTime? data,
    required VoidCallback onTap,
  }) {
    final hasValue = data != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasValue ? _dateFormat.format(data) : 'Seleziona data',
                        style: TextStyle(
                          fontSize: 15,
                          color: hasValue ? textPrimary : textSecondary,
                          fontWeight:
                              hasValue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: textSecondary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
    );
  }
}
