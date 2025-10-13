// lib/services/workmanager_service.dart
import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'alarm_manager_service.dart';
//import 'package:eyyubiye_personel_takip/services/UserServiceApi.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("=== WorkManager Başladı => \$task / inputData=\$inputData ===");

    // Gerekli ise bildirim servisini başlatıyoruz
    await NotificationService().initNotifications();

    final sp = await SharedPreferences.getInstance();
    final userId = sp.getInt('user_id');
    if (userId == null) {
      print("[WorkManager] => Kullanıcı ID bulunamadı, işlem durduruluyor.");
      return Future.value(true);
    }

    // Öncelikle, uygulama tarafından pause kaydı kontrol ediliyor
    bool pauseActive = sp.getBool('pauseActive') ?? false;
    if (pauseActive) {
      int pauseDuration = sp.getInt('pauseDuration') ?? 60;
      print("[WorkManager] => Pause aktif durumda. Görevler iptal ediliyor. Süre: \$pauseDuration dakika");
      await WorkmanagerService.cancelAllTasks();
      
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        print("[DEBUG] BFS servisi durduruluyor...");
        service.invoke("stopService");
      }
      
      print("[DEBUG] AlarmManager ile duraklatma planlanıyor... Süre: \$pauseDuration dakika");
      await AlarmManagerService.scheduleResumeAlarm(pauseDuration);
      return Future.value(true);
    }

    // Backend’den komut alınıyor ve işleniyor
    try {
      final url = Uri.parse("\${Constants.baseUrl}/workmanager/command");
      print("[WorkManager] => API'ye komut için istek gönderiliyor. userId: \$userId");
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"user_id": userId}),
      );

      print("[WorkManager] => API yanıtı alındı, Status Code: \${response.statusCode}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        bool pause = result['pause'] == 1;
        int pauseDuration = result['pause_duration'] is int ? result['pause_duration'] : 60;

        if (pause) {
          print("[WorkManager] => **PAUSE KOMUTU ALINDI!** WorkManager durduruluyor...");          
          await sp.setBool('pauseActive', true);
          await sp.setInt('pauseDuration', pauseDuration);

          await WorkmanagerService.cancelAllTasks();
          final service = FlutterBackgroundService();
          if (await service.isRunning()) {
            print("[DEBUG] BFS servisi durduruluyor...");
            service.invoke("stopService");
          }          
          print("[DEBUG] AlarmManager ile duraklatma planlanıyor... Süre: \$pauseDuration dakika");
          await AlarmManagerService.scheduleResumeAlarm(pauseDuration);
          return Future.value(true);
        } else {
          print("[WorkManager] => **RESUME KOMUTU ALINDI!** WorkManager yeniden başlatılıyor...");
          await sp.setBool('pauseActive', false);
          // WorkManager görevlerini yeniden planla
          await WorkmanagerService.schedulePeriodicTask();
          // BFS (background service) de yeniden başlatılsın
          final service = FlutterBackgroundService();
          if (!await service.isRunning()) {
            print("[DEBUG] BFS servisi çalışmıyor, yeniden başlatılıyor...");
            await service.startService();
          } else {
            print("[DEBUG] BFS servisi zaten çalışıyor.");
          }
        }
      }
    } catch (e) {
      print("[WorkManager] => API isteğinde hata oluştu: \$e");
    }

    
    // BFS (background service) çalışıyor mu kontrol ediliyor, çalışmıyorsa başlatılıyor
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
      print("[DEBUG] BFS background servisi başlatıldı.");
    }

    // İsteğe bağlı: Konum güncelleme işlemleri burada gerçekleştirilebilir.
    print("[WorkManager] => Konum güncelleme işlemleri tamamlandı.");

    return Future.value(true);
  });
}

class WorkmanagerService {
  static Future<void> initializeWorkmanager() async {
    await Workmanager().initialize(
      workmanagerCallbackDispatcher,
      isInDebugMode: false,
    );
    print("[WorkmanagerService] => WorkManager başlatıldı.");
  }

  static Future<void> schedulePeriodicTask() async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool('pauseActive') == true) {
      print("[WorkmanagerService] => Pause aktif, periyodik görev planlanmıyor.");
      return;
    }
    await Workmanager().registerPeriodicTask(
      "locationTask",      // Benzersiz görev ID'si
      "fetchLocation",     // Görev adı
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
    print("[DEBUG] WorkManager periyodik görev planlandı.");
  }

  static Future<void> cancelAllTasks() async {
    print("[DEBUG] WorkManager görevleri iptal ediliyor...");
    await Workmanager().cancelAll();
  }
}
