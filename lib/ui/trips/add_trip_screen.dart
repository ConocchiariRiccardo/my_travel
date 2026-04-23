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
  final _nuovaAttivitaController = TextEditingController();
  final _uuid = const Uuid();
  final _tripService = TripService();

  DateTime? _dataInizio;
  DateTime? _dataFine;
  final List<Attivita> _attivita = [];
  bool _isSaving = false;

  final _dateFormat = DateFormat('dd/MM/yyyy', 'it_IT');

  @override
  void dispose() {
    _nomeController.dispose();
    _destinazioneController.dispose();
    _nuovaAttivitaController.dispose();
    super.dispose();
  }

  // Apre il date picker e salva la data scelta
  Future<void> _selezionaData({required bool isInizio}) async {
    final oggi = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isInizio ? (_dataInizio ?? oggi) : (_dataFine ?? oggi),
      firstDate: oggi,
      lastDate: DateTime(oggi.year + 5),
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
        // Se la data fine è prima della nuova data inizio, resettiamola
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
    final testo = _nuovaAttivitaController.text.trim();
    if (testo.isEmpty) return;

    setState(() {
      _attivita.add(
        Attivita(
          id: _uuid.v4(),
          nome: testo,
        ),
      );
      _nuovaAttivitaController.clear();
    });
  }

  // Rimuove un'attività dalla lista locale
  void _rimuoviAttivita(int index) {
    setState(() => _attivita.removeAt(index));
  }

  // Salva il viaggio su Firestore
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

    setState(() => _isSaving = true);

    try {
      final userId = context.read<AuthViewModel>().currentUser!.uid;

      final nuovoViaggio = Viaggio(
        id: '', // Firestore assegnerà l'ID reale
        userId: userId,
        nome: _nomeController.text.trim(),
        destinazione: _destinazioneController.text.trim(),
        dataInizio: _dataInizio!,
        dataFine: _dataFine!,
      );

      // Salva il viaggio e ottieni l'ID generato
      final viaggioId = await _tripService.creaViaggio(userId, nuovoViaggio);

      // Salva le attività come sub-collection
      for (final attivita in _attivita) {
        await _tripService.aggiungiAttivita(userId, viaggioId, attivita);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viaggio creato con successo! 🎉'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Nuovo Viaggio'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _salvaViaggio,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Sezione Info Base ---
              _SectionTitle(title: 'Informazioni viaggio'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nomeController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome viaggio',
                  hintText: 'es. Conferenza Milano',
                  prefixIcon: Icon(Icons.work_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _destinazioneController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Destinazione',
                  hintText: 'es. Milano, Roma...',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
              ),

              const SizedBox(height: 24),

              // --- Sezione Date ---
              _SectionTitle(title: 'Date'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Data inizio',
                      data: _dataInizio,
                      dateFormat: _dateFormat,
                      onTap: () => _selezionaData(isInizio: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'Data fine',
                      data: _dataFine,
                      dateFormat: _dateFormat,
                      onTap: () => _selezionaData(isInizio: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Sezione Attività ---
              _SectionTitle(title: 'Attività pianificate (opzionale)'),
              const SizedBox(height: 12),

              // Campo input nuova attività
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nuovaAttivitaController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _aggiungiAttivita(),
                      decoration: const InputDecoration(
                        labelText: 'Aggiungi attività',
                        hintText: 'es. Riunione ore 10:00',
                        prefixIcon: Icon(Icons.checklist_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _aggiungiAttivita,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Lista attività aggiunte
              if (_attivita.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nessuna attività aggiunta.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _attivita.length,
                  itemBuilder: (context, index) {
                    final attivita = _attivita[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.radio_button_unchecked,
                          color: Color(0xFF1E3A8A),
                        ),
                        title: Text(attivita.nome),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _rimuoviAttivita(index),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget helper per i titoli di sezione
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E3A8A),
      ),
    );
  }
}

// Widget helper per il campo data con tap
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? data;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.data,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF1E3A8A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data != null ? dateFormat.format(data!) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: data != null ? Colors.black87 : Colors.grey.shade500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
