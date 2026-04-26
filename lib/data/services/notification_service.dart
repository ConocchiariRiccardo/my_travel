import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inizializzato = false;

  Future<void> inizializza() async {
    if (_inizializzato) return;

    tz.initializeTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _inizializzato = true;
  }

  /// Chiede il permesso per le notifiche (Android 13+)
  Future<bool> richiediPermesso() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Schedula una notifica il giorno prima della partenza alle 9:00
  Future<void> schedulaNotificaPartenza({
    required int id,
    required String nomeViaggio,
    required String destinazione,
    required DateTime dataPartenza,
  }) async {
    await inizializza();

    // Notifica il giorno prima alle 9:00
    final giornoNotifica = dataPartenza.subtract(const Duration(days: 1));
    final orarioNotifica = tz.TZDateTime(
      tz.local,
      giornoNotifica.year,
      giornoNotifica.month,
      giornoNotifica.day,
      9,
      0,
    );

    // Se la data è già passata, non schedula
    if (orarioNotifica.isBefore(tz.TZDateTime.now(tz.local))) return;

    const androidDetails = AndroidNotificationDetails(
      'mytravel_partenze',
      'Partenze Viaggio',
      channelDescription: 'Notifiche di promemoria partenza trasferta',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      '✈️ Domani parti per $destinazione!',
      'Il tuo viaggio "$nomeViaggio" inizia domani. Tutto pronto?',
      orarioNotifica,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancella la notifica di un viaggio specifico
  Future<void> cancellaNotifica(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancella tutte le notifiche schedulate
  Future<void> cancellaTutte() async {
    await _plugin.cancelAll();
  }

  /// Genera un id intero deterministico da un viaggioId stringa
  int idDaViaggioId(String viaggioId) {
    return viaggioId.hashCode.abs() % 100000;
  }
}
