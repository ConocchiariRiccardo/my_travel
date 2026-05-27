import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_travel/data/repositories/spesa_repository.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../auth/auth_view_model.dart';
import '../../data/services/ocr_service.dart';
import '../../domain/models/spesa.dart';

class AddExpenseScreen extends StatefulWidget {
  final String viaggioId;
  final SpesaRepository? spesaRepository;

  const AddExpenseScreen({
    super.key,
    required this.viaggioId,
    this.spesaRepository,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  final _formKey = GlobalKey<FormState>();
  final _descrizioneController = TextEditingController();
  final _importoController = TextEditingController();
  late final SpesaRepository _spesaRepo;
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
  void initState() {
    super.initState();
    _spesaRepo = widget.spesaRepository ?? SpesaRepository();
  }

  @override
  void dispose() {
    _descrizioneController.dispose();
    _importoController.dispose();
    super.dispose();
  }

  Future<void> _selezionaImmagine(ImageSource sorgente) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: sorgente,
      imageQuality: 70,
      maxWidth: 800,
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
            content: Text('Dati estratti dallo scontrino. Verifica e salva.'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final erroreStringa = e.toString().toLowerCase();

        final bool isQuotaError = erroreStringa.contains('quota') ||
            erroreStringa.contains('rate') ||
            erroreStringa.contains('limit');

        final String messaggioUtente = isQuotaError
            ? 'Limite richieste AI raggiunto. Riprova tra qualche minuto o inserisci i dati manualmente.'
            : 'Estrazione automatica non riuscita. Inserisci i dati manualmente.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messaggioUtente),
            backgroundColor: const Color(0xFFF59E0B),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOcrLoading = false);
    }
  }

  void _mostraSceltaSorgente() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aggiungi scontrino',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: primaryColor,
                  ),
                ),
                title: const Text('Fotocamera'),
                subtitle: const Text('Fotografa lo scontrino'),
                onTap: () {
                  Navigator.pop(ctx);
                  _selezionaImmagine(ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: primaryColor,
                  ),
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
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _dataSelezionata = picked);
    }
  }

  Future<void> _salvaSpesa() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = context.read<AuthViewModel>().currentUser!.uid;
      final spesaId = _uuid.v4();

      final importo = double.tryParse(
            _importoController.text.replaceAll(',', '.'),
          ) ??
          0.0;

      String? immagineUrl;

      if (_immagineSelezionata != null) {
        immagineUrl = await _spesaRepo.caricaScontrino(
            userId: userId,
            viaggioId: widget.viaggioId,
            spesaId: spesaId,
            immagine: _immagineSelezionata!);
      }

      final nuovaSpesa = Spesa(
        id: spesaId,
        viaggioId: widget.viaggioId,
        descrizione: _descrizioneController.text.trim(),
        importo: importo,
        categoria: _categoriaSelezionata,
        data: _dataSelezionata,
        immagineScontrinoUrl: immagineUrl,
      );

      await _spesaRepo.aggiungi(userId, widget.viaggioId, nuovaSpesa);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spesa salvata con scontrino allegato.'),
          backgroundColor: Color(0xFF1E3A8A),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il salvataggio. Riprova.'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSave = !_isSaving && !_isOcrLoading;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Aggiungi spesa',
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
            child: _isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        key: Key('addexpense-loading'),
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  )
                : TextButton(
                    key: const Key('addexpense-save-btn'),
                    onPressed: canSave ? _salvaSpesa : null,
                    child: Text(
                      'Salva',
                      style: TextStyle(
                        color: canSave ? primaryColor : Colors.grey,
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
            _buildSectionTitle('Scontrino'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _mostraSceltaSorgente,
              child: Container(
                key: const Key('addexpense-photo-area'),
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: _isOcrLoading
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryColor),
                          SizedBox(height: 16),
                          Text(
                            'Analisi AI in corso...',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : _immagineSelezionata != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  _immagineSelezionata!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 800,
                                ),
                                Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
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
                            children: const [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 42,
                                color: primaryColor,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Fotografa lo scontrino',
                                key: const Key('addexpense-photo-title'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'I dati verranno compilati automaticamente',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Dettagli spesa'),
            const SizedBox(height: 12),
            _buildLabeledField(
              fieldKey: const Key('addexpense-description'),
              label: 'Descrizione',
              controller: _descrizioneController,
              hintText: 'es. Cena cliente, Taxi aeroporto',
              icon: Icons.edit_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            _buildLabeledField(
              fieldKey: const Key('addexpense-amount'),
              label: 'Importo (€)',
              controller: _importoController,
              hintText: 'es. 24,50',
              icon: Icons.euro_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Inserisci l\'importo';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Importo non valido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Categoria'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categorie.map((cat) {
                final isSelected = _categoriaSelezionata == cat;
                return GestureDetector(
                  onTap: () => setState(() => _categoriaSelezionata = cat),
                  child: Container(
                    key: Key('addexpense-category-${cat.toLowerCase()}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? primaryColor : borderColor,
                        width: isSelected ? 1.4 : 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? primaryColor : textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Data'),
            const SizedBox(height: 12),
            _buildDateCard(),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: canSave ? _salvaSpesa : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salva spesa',
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
    Key? fieldKey,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
          key: fieldKey,
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            fontSize: 15,
            color: textPrimary,
          ),
          decoration: _fieldDecoration(
            hintText: hintText,
            icon: icon,
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard() {
    return Material(
      key: const Key('addexpense-date'),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _selezionaData,
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
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data spesa',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormat.format(_dataSelezionata),
                        style: const TextStyle(
                          fontSize: 15,
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
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
