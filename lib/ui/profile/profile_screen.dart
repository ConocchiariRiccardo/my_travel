import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_view_model.dart';
import 'profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nomeController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvaModifiche() async {
    final vm = context.read<ProfileViewModel>();
    await vm.aggiornaNome(_nomeController.text);

    if (!mounted) return;

    if (vm.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.successMessage!),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isEditing = false);
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
    vm.clearMessages();
  }

  Future<void> _confermaLogout() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Vuoi uscire dall\'account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Esci'),
          ),
        ],
      ),
    );

    if (conferma == true && mounted) {
      await context.read<AuthViewModel>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profilo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifica nome',
              onPressed: () {
                _nomeController.text = profileVm.utente?.nomeCompleto ?? '';
                setState(() => _isEditing = true);
              },
            )
          else
            TextButton(
              onPressed: profileVm.isSaving ? null : _salvaModifiche,
              child: profileVm.isSaving
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
                      ),
                    ),
            ),
        ],
      ),
      body: profileVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Avatar ---
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFF1E3A8A),
                        backgroundImage: profileVm.utente?.fotoProfiloUrl !=
                                null
                            ? NetworkImage(profileVm.utente!.fotoProfiloUrl!)
                            : null,
                        child: profileVm.utente?.fotoProfiloUrl == null
                            ? Text(
                                _iniziali(
                                  profileVm.utente?.nomeCompleto ??
                                      profileVm.email,
                                ),
                                style: const TextStyle(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profileVm.utente?.nomeCompleto ?? 'Profilo',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profileVm.email,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // --- Modifica nome (visibile solo in editing) ---
                if (_isEditing) ...[
                  _buildSectionTitle('Modifica nome'),
                  const SizedBox(height: 8),
                  _buildCard(children: [
                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: InputBorder.none,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],

                // --- Dati account ---
                _buildSectionTitle('Account'),
                const SizedBox(height: 8),
                _buildCard(children: [
                  _buildInfoRow(
                    Icons.email_outlined,
                    'Email',
                    profileVm.email,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    Icons.badge_outlined,
                    'Nome',
                    profileVm.utente?.nomeCompleto ?? 'Non impostato',
                  ),
                ]),

                const SizedBox(height: 20),

                // --- Navigazione ---
                _buildSectionTitle('Sezioni'),
                const SizedBox(height: 8),
                _buildCard(children: [
                  ListTile(
                    leading: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text('Storico viaggi'),
                    subtitle: const Text('Consulta le trasferte passate'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/history'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF1E3A8A),
                    ),
                    title: const Text('Notifiche'),
                    subtitle:
                        const Text('Promemoria partenza automatici attivi'),
                    trailing: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // --- Bottone logout ---
                _buildSectionTitle('Sessione'),
                const SizedBox(height: 8),
                _buildCard(children: [
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Esci dall\'account',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _confermaLogout,
                  ),
                ]),

                const SizedBox(height: 40),

                // --- Version footer ---
                Center(
                  child: Text(
                    'MyTravel v1.0.0 · Progetto Accademico',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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

  Widget _buildInfoRow(IconData icona, String label, String valore) {
    return ListTile(
      leading: Icon(icona, color: const Color(0xFF1E3A8A)),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      subtitle: Text(
        valore,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _iniziali(String testo) {
    final parole = testo.trim().split(' ');
    if (parole.length >= 2) {
      return '${parole[0][0]}${parole[1][0]}'.toUpperCase();
    }
    return testo.isNotEmpty ? testo[0].toUpperCase() : '?';
  }
}
