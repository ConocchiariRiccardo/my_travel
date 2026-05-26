import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/viaggio_repository.dart';
import '../../../data/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  bool _isLoading = true;
  bool _isSaving = false;

  bool _tripReminders = true;
  bool _expenseUpdates = true;
  bool _appNews = false;

  bool _initialTripReminders = true;

  final ViaggioRepository _viaggioRepository = ViaggioRepository();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _rischedulaViaggiFuturi() async {
    final viaggi = await _viaggioRepository.getViaggiFuturi(_uid);

    for (final viaggio in viaggi) {
      await NotificationService().schedulaNotificaPartenza(
        userId: _uid,
        id: NotificationService().idDaViaggioId(viaggio.id),
        nomeViaggio: viaggio.nome,
        destinazione: viaggio.destinazione,
        dataPartenza: viaggio.dataInizio,
      );
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _tripReminders = data['tripReminders'] ?? true;
          _expenseUpdates = data['expenseUpdates'] ?? true;
          _appNews = data['appNews'] ?? false;
          _initialTripReminders = _tripReminders;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nel caricamento delle preferenze notifiche.'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('notifications')
          .set({
        'tripReminders': _tripReminders,
        'expenseUpdates': _expenseUpdates,
        'appNews': _appNews,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!_tripReminders) {
        await NotificationService().cancellaTutte();
      }

      if (!_initialTripReminders && _tripReminders) {
        await _rischedulaViaggiFuturi();
      }

      _initialTripReminders = _tripReminders;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferenze notifiche aggiornate.'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore durante il salvataggio.'),
          backgroundColor: Color(0xFFF44336),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSectionLabel(String title) {
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: Colors.black87, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF757575),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifiche',
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
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePreferences,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  )
                : const Text(
                    'Salva',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _buildSectionLabel('Preferenze'),
                const SizedBox(height: 12),
                _buildSwitchTile(
                  icon: Icons.flight_takeoff_outlined,
                  title: 'Promemoria viaggi',
                  subtitle:
                      'Ricevi un avviso prima della partenza dei tuoi viaggi.',
                  value: _tripReminders,
                  onChanged: (value) {
                    setState(() => _tripReminders = value);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Aggiornamenti spese',
                  subtitle:
                      'Ricevi notifiche legate a spese, inserimenti o riepiloghi.',
                  value: _expenseUpdates,
                  onChanged: (value) {
                    setState(() => _expenseUpdates = value);
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.campaign_outlined,
                  title: 'Novità app',
                  subtitle:
                      'Ricevi comunicazioni su aggiornamenti e nuove funzioni.',
                  value: _appNews,
                  onChanged: (value) {
                    setState(() => _appNews = value);
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Le modifiche influiscono sulle notifiche future. Le notifiche già programmate potrebbero richiedere una nuova sincronizzazione.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
