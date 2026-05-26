import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_view_model.dart';
import '../auth/auth_view_model.dart';
import 'subpages/edit_profile_screen.dart';
import 'subpages/settings_screen.dart';
import 'subpages/notification_settings_screen.dart';
import 'subpages/support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewModel>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profilo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: profileVm.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                _buildHeaderCard(profileVm),
                const SizedBox(height: 28),
                _buildSectionLabel('Account'),
                const SizedBox(height: 12),
                _buildMenuGroup([
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notification',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionLabel('Supporto'),
                const SizedBox(height: 12),
                _buildMenuGroup([
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Travel history',
                    onTap: () => Navigator.pushNamed(context, '/history'),
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'FAQ',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SupportScreen(section: SupportSection.faq),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'About App',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SupportScreen(section: SupportSection.about),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 32),
                _buildLogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildHeaderCard(ProfileViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: primaryColor,
            backgroundImage: vm.utente?.fotoProfiloUrl != null
                ? CachedNetworkImageProvider(vm.utente!.fotoProfiloUrl!)
                : null,
            child: vm.utente?.fotoProfiloUrl == null
                ? const Icon(Icons.person, size: 36, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.utente?.nomeCompleto?.trim().isNotEmpty == true
                      ? vm.utente!.nomeCompleto!
                      : 'Utente',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Icon(
        icon,
        color: Colors.black87,
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: Color(0xFF9E9E9E),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: _confermaLogout,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: const Icon(
          Icons.logout,
          color: Color(0xFFF44336),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFF44336),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 20,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  Future<void> _confermaLogout() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Logout'),
        content: const Text('Vuoi uscire dall\'account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Annulla',
              style: TextStyle(color: Color(0xFF757575)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Esci'),
          ),
        ],
      ),
    );

    if (conferma == true && mounted) {
      await context.read<AuthViewModel>().logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}
