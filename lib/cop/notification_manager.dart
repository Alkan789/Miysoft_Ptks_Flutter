/*import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class CustomNotificationManager {
  static final CustomNotificationManager _singleton =
  CustomNotificationManager._internal();
  factory CustomNotificationManager() => _singleton;
  CustomNotificationManager._internal();

  Timer? _timer;
  bool isTrackingActive = true;

  Future<void> startDailyCheck() async {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      if (!isTrackingActive) return;

      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;

      // 21:30 sonrası kapat
      if (currentHour >= 1 && currentMinute >= 30) {
        isTrackingActive = false;
        return;
      }

      // Örnek kontroller
      await _checkMorningNotification(now);
      await _checkEntranceNotification(now);
      await _checkLateEntranceNotification(now);
      await _checkAfternoonNotifications(now);
      await _checkEveningNotification(now);
    });
  }

  Future<void> resetFlagsForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('didCheckIn', false);
    await prefs.setBool('didCheckOut', false);
    await prefs.setBool('didShowMorningNotif', false);
    await prefs.setBool('didShow16_55Notif', false);
    await prefs.setBool('didShow17_20Notif', false);
    await prefs.setBool('didShow20Notif', false);
    isTrackingActive = true;
  }

  Future<void> _checkMorningNotification(DateTime now) async {
    // vs. ...
  }

  Future<void> _checkEntranceNotification(DateTime now) async {
    // vs. ...
  }

  Future<void> _checkLateEntranceNotification(DateTime now) async {
    // vs. ...
  }

  Future<void> _checkAfternoonNotifications(DateTime now) async {
    // vs. ...
  }

  Future<void> _checkEveningNotification(DateTime now) async {
    // vs. ...
  }

  void dispose() {
    _timer?.cancel();
  }
}
*/