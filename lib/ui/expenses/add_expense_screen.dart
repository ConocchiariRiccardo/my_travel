import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../auth/auth_view_model.dart';
import '../../data/services/expense_service.dart';
import '../../data/services/ocr_service.dart';
import '../../domain/models/spesa.dart';

class AddExpenseScreen extends StatefulWidget {
  final String viaggioId;

  const AddExpenseScreen({super.key, required this.viaggioId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descrizioneController = TextEditingController();
  final _importoController = TextEditingController();
  final _expenseService = ExpenseService();
  final _ocrService = OcrService();
  final _uuid = const Uuid();
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'it_IT');

  File? _immagineSelezionata;
  String _categoriaSelezionata = 'Altro';
  DateTime _dataSelezionata = DateTime.now();
  bool _isOcrLoading = false;
  bool _isSaving = false;

  static const List<String> _categorie = [
    'Pasto',
    'Trasporto',
    'Alloggio',
    'Carburante',
    'Altro',
  ];

  @override
  void dispose() {
    _descrizioneController.dispose();
    _importoController.dispose();
    super.dispose();
  }

  // Apre fotocamera o galleria e lancia l'OCR
  Future<void> _selezionaImmagine(ImageSource sorgente) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: sorgente,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (picked == null) return;

    setState(() {
      _immagineSelezionata = File(picked.path);
      _isOcrLoading = true;
    });

    try {
      final risultato =
          await _ocrService.analizzaScontrino(_immagineSelezionata!);

      setState(() {
        _descrizioneController.text = risultato.descrizione;
        if (risultato.importo != null) {
          _importoController.text = risultato.importo!.toStringAsFixed(2);
        }
        if (_categorie.contains(risultato.categoria)) {
          _categoriaSelezionata = risultato.categoria;
        }
        if (risultato.data != null) {
          _dataSelezionata = risultato.data!;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dati estratti dallo scontrino. Verifica e salva.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Estrazione automatica fallita. Inserisci i dati manualmente.\n$e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOcrLoading = false);
    }
  }

  // Mostra il bottom sheet per scegliere fotocamera o galleria
  void _mostraSceltaSorgente() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aggiungi scontrino',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1E3A8A),
                  child: Icon(Icons.camera_alt_outlined, color: Colors.white),
                ),
                title: const Text('Fotocamera'),
                subtitle: const Text('Fotografa lo scontrino'),
                onTap: () {
                  Navigator.pop(ctx);
                  _selezionaImmagine(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF3B82F6),
                  child:
                      Icon(Icons.photo_library_outlined, color: Colors.white),
                ),
                title: const Text('Galleria'),
                subtitle: const Text('Scegli dalla libreria foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _selezionaImmagine(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selezionaData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelezionata,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('it', 'IT'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E3A8A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataSelezionata = picked);
  }

  Future<void> _salvaSpesa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = context.read<AuthViewModel>().currentUser!.uid;

      final importo = double.tryParse(
            _importoController.text.replaceAll(',', '.'),
          ) ??
          0.0;

      final nuovaSpesa = Spesa(
        id: _uuid.v4(),
        viaggioId: widget.viaggioId,
        descrizione: _descrizioneController.text.trim(),
        importo: importo,
        categoria: _categoriaSelezionata,
        data: _dataSelezionata,
      );

      await _expenseService.aggiungiSpesa(userId, widget.viaggioId, nuovaSpesa);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spesa salvata! 💾'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Aggiungi Spesa'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: (_isSaving || _isOcrLoading) ? null : _salvaSpesa,
              child: _isSaving
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
            // --- Area scontrino / OCR ---
            GestureDetector(
              onTap: _mostraSceltaSorgente,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: _isOcrLoading
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF1E3A8A),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Analisi AI in corso...',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : _immagineSelezionata != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _immagineSelezionata!,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Tocca per cambiare',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 48,
                                color: const Color(0xFF1E3A8A).withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Fotografa lo scontrino',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "L'AI estrarrà i dati automaticamente",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Dettagli spesa'),
            const SizedBox(height: 12),

            // --- Form dati spesa ---
            _buildCard(children: [
              TextFormField(
                controller: _descrizioneController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: InputBorder.none,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obbligatorio'
                    : null,
              ),
              const Divider(height: 1),
              TextFormField(
                controller: _importoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Importo (€)',
                  prefixIcon: Icon(Icons.euro_outlined),
                  border: InputBorder.none,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Inserisci l\'importo';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Importo non valido';
                  return null;
                },
              ),
            ]),

            const SizedBox(height: 16),

            // --- Categoria ---
            _buildCard(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoria',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categorie.map((cat) {
                        final isSelected = _categoriaSelezionata == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _categoriaSelezionata = cat),
                          selectedColor: const Color(0xFF1E3A8A),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // --- Data ---
            _buildCard(children: [
              ListTile(
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF1E3A8A),
                ),
                title: const Text('Data spesa'),
                subtitle: Text(
                  _dateFormat.format(_dataSelezionata),
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selezionaData,
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
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
}
