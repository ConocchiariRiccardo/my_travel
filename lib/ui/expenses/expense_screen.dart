import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../auth/auth_view_model.dart';
import '../../domain/models/spesa.dart';
import 'expense_view_model.dart';

class ExpenseScreen extends StatefulWidget {
  final String viaggioId;
  final ExpenseViewModel? viewModel;

  const ExpenseScreen({
    super.key,
    required this.viaggioId,
    this.viewModel,
  });

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  static const List<String> _categorie = [
    'Pasto',
    'Trasporto',
    'Alloggio',
    'Carburante',
    'Altro',
  ];

  late final ExpenseViewModel _viewModel;
  late final bool _ownsViewModel;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'it_IT');

  @override
  void initState() {
    super.initState();
    _ownsViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? ExpenseViewModel();
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

  IconData _iconaCategoria(String categoria) {
    switch (categoria) {
      case 'Pasto':
        return Icons.restaurant_outlined;
      case 'Trasporto':
        return Icons.directions_car_outlined;
      case 'Alloggio':
        return Icons.hotel_outlined;
      case 'Carburante':
        return Icons.local_gas_station_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color _coloreCategoria(String categoria) {
    switch (categoria) {
      case 'Pasto':
        return const Color(0xFFD97706);
      case 'Trasporto':
        return const Color(0xFF2563EB);
      case 'Alloggio':
        return const Color(0xFF7C3AED);
      case 'Carburante':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _apriModificaSpesa(String userId, Spesa spesa) async {
    final formKey = GlobalKey<FormState>();
    final descrizioneController =
        TextEditingController(text: spesa.descrizione);
    final importoController = TextEditingController(
      text: spesa.importo.toStringAsFixed(2).replaceAll('.', ','),
    );

    String categoriaSelezionata = spesa.categoria;
    DateTime dataSelezionata = spesa.data;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> selezionaData() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dataSelezionata,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
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

              if (picked != null) {
                setModalState(() {
                  dataSelezionata = picked;
                });
              }
            }

            Future<void> salvaModifiche() async {
              if (!formKey.currentState!.validate()) return;

              setModalState(() => isSaving = true);

              final importo = double.tryParse(
                    importoController.text.replaceAll(',', '.'),
                  ) ??
                  0.0;

              final spesaAggiornata = Spesa(
                id: spesa.id,
                viaggioId: spesa.viaggioId,
                descrizione: descrizioneController.text.trim(),
                importo: importo,
                categoria: categoriaSelezionata,
                data: dataSelezionata,
                immagineScontrinoUrl: spesa.immagineScontrinoUrl,
              );

              final ok = await _viewModel.aggiorna(
                userId,
                widget.viaggioId,
                spesaAggiornata,
              );

              if (!mounted) return;

              setModalState(() => isSaving = false);

              if (ok) {
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Spesa aggiornata con successo.'),
                    backgroundColor: primaryColor,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _viewModel.errorMessage ??
                          'Impossibile aggiornare la spesa.',
                    ),
                    backgroundColor: errorColor,
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SafeArea(
                top: false,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Modifica spesa',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Aggiorna i dati della spesa direttamente da questa schermata.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFieldLabel('Descrizione'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descrizioneController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                            hintText: 'es. Taxi aeroporto',
                            icon: Icons.edit_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Campo obbligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('Importo'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: importoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            hintText: 'es. 18,50',
                            icon: Icons.euro_outlined,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Inserisci l\'importo';
                            }
                            final numero =
                                double.tryParse(v.replaceAll(',', '.'));
                            if (numero == null || numero <= 0) {
                              return 'Importo non valido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('Categoria'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categorie.map((cat) {
                            final isSelected = categoriaSelezionata == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) {
                                setModalState(() {
                                  categoriaSelezionata = cat;
                                });
                              },
                              selectedColor: primaryColor,
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected ? primaryColor : borderColor,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        _buildFieldLabel('Data spesa'),
                        const SizedBox(height: 6),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: selezionaData,
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 20,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _dateFormat.format(dataSelezionata),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
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
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.of(sheetContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  side: const BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Annulla',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : salvaModifiche,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  elevation: 0,
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Salva modifiche',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    descrizioneController.dispose();
    importoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser!.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Spese viaggio',
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
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Genera PDF',
            onPressed: () => Navigator.pushNamed(context, '/pdf',
                arguments: widget.viaggioId),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          return Column(
            children: [
              _buildRiepilogoTotale(),
              Expanded(
                child: _viewModel.spese.isEmpty
                    ? _buildStatoVuoto()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: _viewModel.spese.length,
                        itemBuilder: (context, index) {
                          final spesa = _viewModel.spese[index];
                          return _buildSpesaTile(context, userId, spesa);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          '/expenses/add',
          arguments: widget.viaggioId,
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Aggiungi spesa',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildRiepilogoTotale() {
    final totalePerCategoria = _viewModel.totalePerCategoria;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riepilogo spese',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _viewModel.totaleFormattato,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Totale registrato per questo viaggio',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          if (totalePerCategoria.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: totalePerCategoria.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${e.key}: €${e.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpesaTile(
    BuildContext context,
    String userId,
    Spesa spesa,
  ) {
    final colore = _coloreCategoria(spesa.categoria);

    return Dismissible(
      key: Key(spesa.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _apriModificaSpesa(userId, spesa);
          return false;
        }

        bool? conferma = false;

        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Elimina spesa'),
            content: Text('Eliminare "${spesa.descrizione}"?'),
            actions: [
              TextButton(
                onPressed: () {
                  conferma = false;
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  'Annulla',
                  style: TextStyle(color: textSecondary),
                ),
              ),
              FilledButton(
                onPressed: () {
                  conferma = true;
                  Navigator.of(ctx).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: errorColor,
                ),
                child: const Text('Elimina'),
              ),
            ],
          ),
        );

        return conferma;
      },
      onDismissed: (_) =>
          _viewModel.elimina(userId, widget.viaggioId, spesa.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Modifica',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colore.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconaCategoria(spesa.categoria),
              color: colore,
              size: 21,
            ),
          ),
          title: Text(
            spesa.descrizione,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${spesa.categoria} · ${_dateFormat.format(spesa.data)}',
              style: const TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spesa.immagineScontrinoUrl != null) ...[
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: Color(0xFF1E3A8A),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                spesa.importoFormattato,
                style: TextStyle(
                  color: colore,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatoVuoto() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nessuna spesa registrata',
              style: TextStyle(
                fontSize: 17,
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Aggiungi la prima spesa del viaggio per iniziare a tenere traccia dei costi.',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration({
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
