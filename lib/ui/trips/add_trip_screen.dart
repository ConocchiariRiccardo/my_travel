import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../auth/auth_view_model.dart';
import '../home/home_view_model.dart';
import '../../domain/models/viaggio.dart';
import '../../domain/models/attivita.dart';
import '../../data/services/trip_service.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _destinazioneController = TextEditingController();
  final _attivitaController = TextEditingController();
  final _tripService = TripService();
  final _uuid = const Uuid();

  DateTime? _dataInizio;
  DateTime? _dataFine;
  final List<Attivita> _attivita = [];
  bool _isLoading = false;

  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'it_IT');

  @override
  void dispose() {
    _nomeController.dispose();
    _destinazioneController.dispose();
    _attivitaController.dispose();
    super.dispose();
  }

  // Apre il DatePicker e salva la data selezionata
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
              primary: Color(0xFF1E3A8A),
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
        // Se la data di fine è precedente alla nuova data di inizio, resettala
        if (_dataFine != null && _dataFine!.isBefore(picked)) {
          _dataFine = null;
        }
      } else {
        _dataFine = picked;
      }
    });
  }

  // Aggiunge un'attività alla lista locale
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

  // Rimuove un'attività dalla lista locale
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
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = context.read<AuthViewModel>().currentUser!.uid;

      final nuovoViaggio = Viaggio(
        id: '', // Firestore assegnerà l'id reale
        userId: userId,
        nome: _nomeController.text.trim(),
        destinazione: _destinazioneController.text.trim(),
        dataInizio: _dataInizio!,
        dataFine: _dataFine!,
      );

      // Salva il viaggio e ottieni l'id generato da Firestore
      final viaggioId = await _tripService.creaViaggio(userId, nuovoViaggio);

      // Salva le attività nella sub-collection
      for (final attivita in _attivita) {
        await _tripService.aggiungiAttivita(userId, viaggioId, attivita);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaggio creato con successo! ✈️'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il salvataggio. Riprova.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Nuovo Viaggio'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _salvaViaggio,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Salva',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Sezione Informazioni Base ---
            _buildSectionTitle('Informazioni viaggio'),
            const SizedBox(height: 12),

            _buildCard(
              children: [
                TextFormField(
                  controller: _nomeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome viaggio',
                    hintText: 'es. Trasferta Milano Q1',
                    prefixIcon: Icon(Icons.work_outline),
                    border: InputBorder.none,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obbligatorio'
                      : null,
                ),
                const Divider(height: 1),
                TextFormField(
                  controller: _destinazioneController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Destinazione',
                    hintText: 'es. Milano, Roma, Berlino',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: InputBorder.none,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obbligatorio'
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Sezione Date ---
            _buildSectionTitle('Date'),
            const SizedBox(height: 12),

            _buildCard(
              children: [
                _buildDateRow(
                  label: 'Data inizio',
                  icon: Icons.flight_takeoff_rounded,
                  data: _dataInizio,
                  onTap: () => _selezionaData(isInizio: true),
                ),
                const Divider(height: 1),
                _buildDateRow(
                  label: 'Data fine',
                  icon: Icons.flight_land_rounded,
                  data: _dataFine,
                  onTap: () => _selezionaData(isInizio: false),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Sezione Attività ---
            _buildSectionTitle('Attività pianificate (opzionale)'),
            const SizedBox(height: 12),

            // Campo aggiunta attività
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _attivitaController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Aggiungi un\'attività...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _aggiungiAttivita(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _aggiungiAttivita,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            // Lista attività aggiunte
            if (_attivita.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildCard(
                children: _attivita
                    .map(
                      (a) => ListTile(
                        leading: const Icon(
                          Icons.radio_button_unchecked,
                          color: Color(0xFF1E3A8A),
                        ),
                        title: Text(a.nome),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _rimuoviAttivita(a.id),
                        ),
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- Widget helper privati ---

  Widget _buildSectionTitle(String titolo) {
    return Text(
      titolo.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildDateRow({
    required String label,
    required IconData icon,
    required DateTime? data,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A8A)),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        data != null ? _dateFormat.format(data) : 'Seleziona data',
        style: TextStyle(
          color: data != null ? const Color(0xFF1E3A8A) : Colors.grey,
          fontWeight: data != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
