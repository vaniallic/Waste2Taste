import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models.dart';
import '../data/sample_data.dart';

/// Expiry reminders: a notification the day before an ingredient goes bad.
/// Works on the phone apps (iOS / Android). On the web it quietly does nothing.
class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get supported => !kIsWeb;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiry',
      'Expiry reminders',
      channelDescription: 'A heads-up before food in your fridge goes bad',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> _init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // We ask for permission ourselves (when the user turns reminders on), not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Shows the system "Allow notifications?" popup. Returns true if the user allowed it.
  static Future<bool> askPermission() async {
    if (!supported) return false;
    try {
      await _init();
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('reminders: $e');
    }
    return false;
  }

  /// Plans one reminder per fridge item: 09:00 the day before it expires.
  /// Called every time the fridge changes, so it starts from a clean slate.
  static Future<void> sync(List<FridgeItem> fridge, {required bool enabled}) async {
    if (!supported) return;
    try {
      await _init();
      await _plugin.cancelAll();
      if (!enabled) return;

      final now = DateTime.now();
      for (final item in fridge) {
        final ing = catalogById[item.ingredientId];
        if (ing == null || ing.isPantry) continue; // salt and sauces don't spoil in a week

        final e = item.expiresAt;
        final when = DateTime(e.year, e.month, e.day, 9).subtract(const Duration(days: 1));
        if (!when.isAfter(now)) continue; // too late for a heads-up, the Home screen already shows it in red

        await _plugin.zonedSchedule(
          id: item.ingredientId.hashCode & 0x7fffffff,
          title: '${ing.name} is about to go bad',
          body: 'Use it up by tomorrow. Open Waste2Taste to see what you can cook.',
          // Same moment, written in UTC, so we don't need to know the phone's time zone name.
          scheduledDate: tz.TZDateTime.from(when, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('reminders: $e');
    }
  }

  /// Sends a notification right now, to check that everything works.
  static Future<bool> sendTest() async {
    if (!await askPermission()) return false;
    try {
      await _plugin.show(
        id: 0,
        title: 'Test reminder',
        body: 'Reminders are working.',
        notificationDetails: _details,
      );
      return true;
    } catch (e) {
      debugPrint('reminders: $e');
      return false;
    }
  }
}
