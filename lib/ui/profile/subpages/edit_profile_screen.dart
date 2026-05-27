import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../profile_view_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color disabledFillColor = Color(0xFFF5F5F5);

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();

  final TextEditingController giornoController = TextEditingController();
  final TextEditingController meseController = TextEditingController();
  final TextEditingController annoController = TextEditingController();

  bool isEditing = false;

  String selectedCountryId = 'IT';

  final List<Map<String, String>> countryCodes = const [
    {'id': 'IT', 'label': 'IT (+39)', 'code': '+39'},
    {'id': 'FR', 'label': 'FR (+33)', 'code': '+33'},
    {'id': 'DE', 'label': 'DE (+49)', 'code': '+49'},
    {'id': 'ES', 'label': 'ES (+34)', 'code': '+34'},
    {'id': 'PT', 'label': 'PT (+351)', 'code': '+351'},
    {'id': 'GB', 'label': 'GB (+44)', 'code': '+44'},
    {'id': 'IE', 'label': 'IE (+353)', 'code': '+353'},
    {'id': 'US', 'label': 'US (+1)', 'code': '+1'},
    {'id': 'CA', 'label': 'CA (+1)', 'code': '+1'},
    {'id': 'CH', 'label': 'CH (+41)', 'code': '+41'},
    {'id': 'AT', 'label': 'AT (+43)', 'code': '+43'},
    {'id': 'BE', 'label': 'BE (+32)', 'code': '+32'},
    {'id': 'NL', 'label': 'NL (+31)', 'code': '+31'},
    {'id': 'LU', 'label': 'LU (+352)', 'code': '+352'},
    {'id': 'GR', 'label': 'GR (+30)', 'code': '+30'},
  ];

  @override
  void initState() {
    super.initState();
    final vm = context.read<ProfileViewModel>();

    nomeController.text = vm.utente?.nomeCompleto ?? '';
    emailController.text = vm.email;
    _setPhoneControllers(vm.utente?.telefono);
    _setBirthDateControllers(vm.utente?.dataNascita);
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefonoController.dispose();
    giornoController.dispose();
    meseController.dispose();
    annoController.dispose();
    super.dispose();
  }

  void _setPhoneControllers(String? fullPhone) {
    telefonoController.clear();
    selectedCountryId = 'IT';

    if (fullPhone == null || fullPhone.trim().isEmpty) return;

    final clean = fullPhone.trim();

    for (final item in countryCodes) {
      final code = item['code']!;
      if (clean.startsWith(code)) {
        selectedCountryId = item['id']!;
        telefonoController.text = clean.substring(code.length).trim();
        return;
      }
    }

    telefonoController.text = clean;
  }

  void _setBirthDateControllers(String? birthDate) {
    giornoController.clear();
    meseController.clear();
    annoController.clear();

    if (birthDate == null || birthDate.trim().isEmpty) return;

    final parts = birthDate.split('/');
    if (parts.length == 3) {
      giornoController.text = parts[0];
      meseController.text = parts[1];
      annoController.text = parts[2];
    }
  }

  String? _composePhoneNumber() {
    final localNumber = telefonoController.text.trim();

    if (localNumber.isEmpty) return null;

    final selectedItem = countryCodes.firstWhere(
      (item) => item['id'] == selectedCountryId,
    );

    return '${selectedItem['code']} $localNumber';
  }

  String? _composeBirthDate() {
    final day = giornoController.text.trim();
    final month = meseController.text.trim();
    final year = annoController.text.trim();

    if (day.isEmpty && month.isEmpty && year.isEmpty) return null;

    if (day.isEmpty || month.isEmpty || year.isEmpty) {
      return '';
    }

    return '${day.padLeft(2, '0')}/${month.padLeft(2, '0')}/$year';
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(value)) {
      return 'Data inserita in modo non corretto.';
    }

    final parts = value.split('/');
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return 'Data inserita in modo non corretto.';
    }

    final now = DateTime.now();

    final isDayOutOfRange = day < 1 || day > 31;
    final isMonthOutOfRange = month < 1 || month > 12;
    final isYearOutOfRange = year < 1900 || year > now.year;

    int errorCount = 0;
    if (isDayOutOfRange) errorCount++;
    if (isMonthOutOfRange) errorCount++;
    if (isYearOutOfRange) errorCount++;

    if (errorCount >= 2) {
      return 'Data inserita in modo non corretto.';
    }

    if (isDayOutOfRange) {
      return 'Il giorno inserito non è valido.';
    }

    if (isMonthOutOfRange) {
      return 'Il mese inserito non è valido.';
    }

    if (isYearOutOfRange) {
      return 'L\'anno inserito non è valido.';
    }

    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    if (day > lastDayOfMonth) {
      return 'Il giorno inserito non è valido.';
    }

    final parsedDate = DateTime(year, month, day);
    if (parsedDate.isAfter(now)) {
      return 'La data di nascita non può essere nel futuro.';
    }

    return null;
  }

  void annullaModifiche(ProfileViewModel vm) {
    setState(() {
      nomeController.text = vm.utente?.nomeCompleto ?? '';
      emailController.text = vm.email;
      _setPhoneControllers(vm.utente?.telefono);
      _setBirthDateControllers(vm.utente?.dataNascita);
      isEditing = false;
    });
  }

  Future<void> salva(ProfileViewModel vm) async {
    final birthDate = _composeBirthDate();
    final birthDateError = _validateBirthDate(birthDate);

    if (birthDate == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa giorno, mese e anno della data di nascita.'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    if (birthDateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(birthDateError),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    await vm.salvaDatiProfilo(
      nome: nomeController.text.trim(),
      nascita: birthDate,
      telefono: _composePhoneNumber(),
    );

    if (!mounted) return;

    if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profilo aggiornato con successo.'),
        backgroundColor: primaryColor,
      ),
    );
  }

  Future<void> selezionaFoto(ProfileViewModel vm) async {
    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: primaryColor),
              title: const Text('Scegli dalla galleria'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (file != null && mounted) {
                  await vm.aggiornaFotoProfilo(File(file.path));
                }
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: primaryColor),
              title: const Text('Scatta una foto'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (file != null && mounted) {
                  await vm.aggiornaFotoProfilo(File(file.path));
                }
              },
            ),
            if (vm.utente?.fotoProfiloUrl != null &&
                vm.utente!.fotoProfiloUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: errorColor),
                title: const Text(
                  'Rimuovi foto',
                  style: TextStyle(color: errorColor),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await vm.rimuoviFotoProfilo();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: errorColor,
        ),
      );
    } else if (vm.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.successMessage!),
          backgroundColor: primaryColor,
        ),
      );
      vm.clearMessages();
    }
  }

  InputDecoration fieldDecoration({
    required bool enabled,
    String? hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: enabled ? Colors.white : disabledFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
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

  Widget buildLabeledField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
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
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            color: enabled ? textPrimary : textSecondary,
          ),
          decoration: fieldDecoration(enabled: enabled),
        ),
      ],
    );
  }

  Widget buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of birth',
          style: const TextStyle(
            fontSize: 13,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: giornoController,
                enabled: isEditing,
                keyboardType: TextInputType.number,
                maxLength: 2,
                style: TextStyle(
                  fontSize: 15,
                  color: isEditing ? textPrimary : textSecondary,
                ),
                decoration: fieldDecoration(
                  enabled: isEditing,
                  hintText: 'GG',
                ).copyWith(counterText: ''),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: meseController,
                enabled: isEditing,
                keyboardType: TextInputType.number,
                maxLength: 2,
                style: TextStyle(
                  fontSize: 15,
                  color: isEditing ? textPrimary : textSecondary,
                ),
                decoration: fieldDecoration(
                  enabled: isEditing,
                  hintText: 'MM',
                ).copyWith(counterText: ''),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: annoController,
                enabled: isEditing,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: TextStyle(
                  fontSize: 15,
                  color: isEditing ? textPrimary : textSecondary,
                ),
                decoration: fieldDecoration(
                  enabled: isEditing,
                  hintText: 'AAAA',
                ).copyWith(counterText: ''),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile number',
          style: const TextStyle(
            fontSize: 13,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: DropdownButtonFormField<String>(
                value: selectedCountryId,
                isExpanded: true,
                selectedItemBuilder: (context) {
                  return countryCodes.map((item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item['code']!,
                        overflow: TextOverflow.visible,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 14,
                          color: isEditing ? textPrimary : textSecondary,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: countryCodes.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text(
                      item['label']!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: isEditing
                    ? (value) {
                        if (value == null) return;
                        setState(() {
                          selectedCountryId = value;
                        });
                      }
                    : null,
                decoration: fieldDecoration(enabled: isEditing),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                dropdownColor: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: telefonoController,
                enabled: isEditing,
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontSize: 15,
                  color: isEditing ? textPrimary : textSecondary,
                ),
                decoration: fieldDecoration(
                  enabled: isEditing,
                  hintText: 'Numero di telefono',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildProfilePhotoEditor(ProfileViewModel vm) {
    final fotoUrl = vm.utente?.fotoProfiloUrl;

    return GestureDetector(
      onTap: isEditing ? () => selezionaFoto(vm) : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: primaryColor,
            backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                ? CachedNetworkImageProvider(fotoUrl)
                : null,
            child: fotoUrl == null || fotoUrl.isEmpty
                ? const Icon(Icons.person, size: 48, color: Colors.white)
                : null,
          ),
          if (isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: backgroundColor, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: textPrimary),
        actions: [
          if (!isEditing)
            IconButton(
              key: const Key('edit-profile-btn'),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifica profilo',
            )
          else ...[
            TextButton(
              key: const Key('edit-cancel-btn'),
              onPressed: () => annullaModifiche(vm),
              child: const Text(
                'Annulla',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            vm.isSaving
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
                    key: const Key('edit-save-btn'),
                    onPressed: () => salva(vm),
                    child: const Text(
                      'Salva',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ],
      ),
      body: vm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                const SizedBox(height: 10),
                Center(child: buildProfilePhotoEditor(vm)),
                const SizedBox(height: 32),
                buildSectionTitle('Basic Detail'),
                const SizedBox(height: 14),
                buildLabeledField(
                  label: 'Full name',
                  controller: nomeController,
                  enabled: isEditing,
                ),
                const SizedBox(height: 14),
                buildDateField(),
                const SizedBox(height: 24),
                buildSectionTitle('Contact Detail'),
                const SizedBox(height: 14),
                buildLabeledField(
                  label: 'Email',
                  controller: emailController,
                  enabled: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                buildPhoneField(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
