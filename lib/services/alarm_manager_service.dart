import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:eyyubiye_personel_takip/services/workmanager_service.dart';

class AlarmManagerService {
  static const int _alarmId = 12345; // Benzersiz alarm ID'si

  /// pauseDuration: dakikalar cinsinden
  static Future<void> scheduleResumeAlarm(int pauseDuration) async {
    try {
      final duration = Duration(minutes: pauseDuration);
      // Tek seferlik alarm kuruyoruz
      await AndroidAlarmManager.oneShot(
        duration,
        _alarmId,
        _resumeBackgroundServices,
        exact: true,
        wakeup: true,
      );
      print("[AlarmManagerService] Alarm ayarlandı: $pauseDuration dakika sonra yeniden başlatma");
    } catch (e) {
      print("[AlarmManagerService] Alarm ayarlanırken hata: $e");
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _resumeBackgroundServices() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('pauseActive', false);
    print("[AlarmManagerService] Resume alarm tetiklendi. pauseActive false olarak ayarlandı.");

    // WorkManager görevlerini yeniden planla
    await WorkmanagerService.schedulePeriodicTask();

    // Flutter Background Service çalışmıyorsa başlat
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
      print("[AlarmManagerService] Background service başlatıldı.");
    }
  }
}
