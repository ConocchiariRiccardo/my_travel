import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPreferencesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, bool>> getPreferences(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications')
        .get();

    final data = doc.data() ?? {};

    return {
      'tripReminders': data['tripReminders'] ?? true,
      'expenseUpdates': data['expenseUpdates'] ?? true,
      'appNews': data['appNews'] ?? false,
    };
  }

  Future<bool> areTripRemindersEnabled(String userId) async {
    final prefs = await getPreferences(userId);
    return prefs['tripReminders'] ?? true;
  }

  Future<bool> areExpenseUpdatesEnabled(String userId) async {
    final prefs = await getPreferences(userId);
    return prefs['expenseUpdates'] ?? true;
  }

  Future<bool> areAppNewsEnabled(String userId) async {
    final prefs = await getPreferences(userId);
    return prefs['appNews'] ?? false;
  }
}
