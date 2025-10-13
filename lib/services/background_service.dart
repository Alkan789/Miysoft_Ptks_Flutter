// lib/services/background_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Proje içi servisler ve yardımcı dosyalar
import 'notification_service.dart';
import 'package:eyyubiye_personel_takip/services/location_save_service.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart';

/// Global konum izleme değişkenleri
StreamSubscription<Position>? _positionStreamSubscription;
double? gCurrentLat;
double? gCurrentLng;

/// Konum izni kontrolü ve talep edilmesi
Future<void> _checkPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      debugPrint("[BGService] Konum izni reddedildi.");
      return;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    debugPrint("[BGService] Konum izni kalıcı reddedildi.");
    return;
  }
}

/// Konum takibini başlatır (stream üzerinden güncel konum güncellemesi)
Future<void> _startTracking() async {
  await _checkPermission();

  int distanceFilter = 0;
  int intervalSec = 120;

  final androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: distanceFilter,
    intervalDuration: Duration(seconds: intervalSec),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: "Arka Planda Konum Servisi",
      notificationText: "Her şey yolunda",
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    ),
  );

  final iosSettings = AppleSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: distanceFilter,
    allowBackgroundLocationUpdates: true,
    showBackgroundLocationIndicator: false,
  );

  LocationSettings locationSettings;
  if (Platform.isAndroid) {
    locationSettings = androidSettings;
  } else if (Platform.isIOS) {
    locationSettings = iosSettings;
  } else {
    locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 500,
    );
  }

  // Önce mevcut konum dinleyiciyi iptal ediyoruz
  await _positionStreamSubscription?.cancel();

  // Yeni konum stream'i başlatıyoruz
  _positionStreamSubscription = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen((pos) {
    gCurrentLat = pos.latitude;
    gCurrentLng = pos.longitude;
    debugPrint("[BGService] Konum => lat=${pos.latitude}, lng=${pos.longitude}");
  });
}

/// Background service yapılandırmasını başlatır
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStartService, // Servis başladığında çalışacak fonksiyon
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'critical_channel', // Kritik bildirim kanalı ID
      initialNotificationTitle: 'Background Service',
      initialNotificationContent: 'Konum servisi başlatılıyor...',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStartService,
      onBackground: _iosBackgroundHandler,
    ),
  );
  debugPrint("[BGService] Configure tamamlandı");
}

/// iOS için background handler
@pragma('vm:entry-point')
Future<bool> _iosBackgroundHandler(ServiceInstance service) async {
  debugPrint("[BGService] iOS background fetch çalıştı");
  return true;
}

/// Servis başladığında çalışacak ana fonksiyon (background isolate içinde çalışır)
@pragma('vm:entry-point')
void onStartService(ServiceInstance service) async {
  // Flutter binding'lerin initialize edilmesi
  WidgetsFlutterBinding.ensureInitialized();

  // NOT: FlutterBackgroundServiceAndroid.registerWith() çağrısını kaldırdık,
  // çünkü bu çağrı yalnızca ana izolate içindir.
  
  // Bildirim servisini başlatıyoruz
  await NotificationService().initNotifications();

  // Android servis için foreground moda geçiş ve bildirim ayarları
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Arka Plan Konum Servisi",
      content: "Her şey yolunda",
    );
  }

  final sp = await SharedPreferences.getInstance();

  // 'pauseActive' kontrolü: Eğer true ise servisi sonlandırıyoruz
  if (sp.getBool('pauseActive') == true) {
    debugPrint("[BGService] Pause aktif, servis sonlandırılıyor.");
    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
    return;
  }

  // Konum takibini başlatıyoruz
  await _startTracking();

  /// --- PERİYODİK İŞLEMLER ---

  // 1. Konum verisini belirli aralıklarla alıp veritabanına kaydeden timer (15 dk aralık)
  const locationUpdateInterval = Duration(minutes: 1);
  Timer.periodic(locationUpdateInterval, (timer) async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool('pauseActive') == true) {
      debugPrint("[BGService] Pause tespit edildi, konum update timer iptal ediliyor.");
      timer.cancel();
      return;
    }
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      bool saved = await LocationSaveService().saveLocation(pos.latitude, pos.longitude);
      if (saved) {
        debugPrint("[BGService] Konum update başarılı: (${pos.latitude}, ${pos.longitude})");
      } else {
        debugPrint("[BGService] Konum update başarısız.");
      }
    } catch (e) {
      debugPrint("[BGService] Konum update sırasında hata: $e");
    }
  });

  // 2. Her saat başı API'ye temel istek göndererek check_in/check_out verilerini güncelleyen timer
  Timer.periodic(Duration(hours: 1), (timer) async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool('pauseActive') == true) {
      debugPrint("[BGService] Pause tespit edildi, saatlik API isteği iptal ediliyor.");
      timer.cancel();
      return;
    }
    int? userId = sp.getInt('user_id');
    if (userId == null) {
      debugPrint("[BGService] Kullanıcı ID bulunamadı, API isteği yapılmıyor.");
      return;
    }
    var url = Uri.parse("${Constants.baseUrl}/update-location");
    try {
      var response = await http.post(url, body: {'user_id': userId.toString()});
      debugPrint("[BGService] Saatlik API isteği gönderildi. Status code: ${response.statusCode}");
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['check_in_location'] != null) {
          await sp.setString('bg_check_in_location', data['check_in_location']);
          debugPrint("[BGService] bg_check_in_location güncellendi: ${data['check_in_location']}");
        }
        if (data['check_out_location'] != null) {
          await sp.setString('bg_check_out_location', data['check_out_location']);
          debugPrint("[BGService] bg_check_out_location güncellendi: ${data['check_out_location']}");
        }
      } else {
        debugPrint("[BGService] API isteği başarısız: ${response.body}");
      }
    } catch (e) {
      debugPrint("[BGService] Saatlik API isteği sırasında hata: $e");
    }
  });

  // 3. 10 dakikada bir detaylı konum kontrolü yapan timer (08:00-17:00 arası aktif)
  Timer.periodic(Duration(minutes: 10), (timer) async {
    final sp = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    DateTime periodStart = DateTime(now.year, now.month, now.day, 8, 0, 0);
    DateTime periodEnd = DateTime(now.year, now.month, now.day, 17, 0, 0);
    if (now.isBefore(periodStart) || now.isAfter(periodEnd)) return;

    if (sp.getBool('pauseActive') == true) {
      debugPrint("[BGService] Pause tespit edildi, detaylı kontrol timer iptal ediliyor.");
      timer.cancel();
      return;
    }

    String? storedLocation = sp.getString('bg_check_in_location');
    if (storedLocation == null || storedLocation.isEmpty) {
      debugPrint("[BGService] bg_check_in_location bulunamadı, detaylı kontrol yapılamıyor.");
      return;
    }
    List<String> parts = storedLocation.split(',');
    double storedLat = double.parse(parts[0]);
    double storedLng = double.parse(parts[1]);

    if (gCurrentLat == null || gCurrentLng == null) {
      debugPrint("[BGService] Güncel konum alınamadı, detaylı kontrol yapılamıyor.");
      return;
    }
    double distance = Geolocator.distanceBetween(storedLat, storedLng, gCurrentLat!, gCurrentLng!);
    debugPrint("[BGService] Detaylı kontrol: Mesafe = $distance metre");

    bool isMorning = now.hour < 12;
    String departureReason = isMorning ? "morning_departure" : "afternoon_departure";
    String arrivalReason = isMorning ? "morning_arrival" : "afternoon_arrival";

    bool departureNotified = sp.getBool('bg_departure_notified') ?? false;
    bool arrivalNotified = sp.getBool('bg_arrival_notified') ?? false;
    int userId = sp.getInt('user_id') ?? 0;
    var url = Uri.parse("${Constants.baseUrl}/update-location");

    if (distance > 200 && (!departureNotified || (departureNotified && arrivalNotified))) {
      try {
        await http.post(url, body: {
          'user_id': userId.toString(),
          'request_reason': departureReason,
          'current_location': "${gCurrentLat},${gCurrentLng}",
        });
        await sp.setBool('bg_departure_notified', true);
        await sp.setBool('bg_arrival_notified', false);
        debugPrint("[BGService] $departureReason API isteği gönderildi.");
      } catch (e) {
        debugPrint("[BGService] $departureReason API isteği sırasında hata: $e");
      }
    } else if (distance <= 200 && departureNotified && !arrivalNotified) {
      try {
        await http.post(url, body: {
          'user_id': userId.toString(),
          'request_reason': arrivalReason,
          'current_location': "${gCurrentLat},${gCurrentLng}",
        });
        await sp.setBool('bg_arrival_notified', true);
        debugPrint("[BGService] $arrivalReason API isteği gönderildi.");
      } catch (e) {
        debugPrint("[BGService] $arrivalReason API isteği sırasında hata: $e");
      }
    }
  });

  // 4. Her dakika servis durumunu ve pause kontrolünü yapan timer
  Timer.periodic(Duration(minutes: 1), (timer) async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool('pauseActive') == true) {
      debugPrint("[BGService] Pause tespit edildi, service state timer iptal ediliyor ve servis durduruluyor.");
      timer.cancel();
      if (service is AndroidServiceInstance) {
        service.stopSelf();
      }
      return;
    }
    bool isRunning = true;
    try {
      isRunning = await FlutterBackgroundService().isRunning();
    } catch (e) {
      debugPrint("[BGService] isRunning() kontrolü sırasında hata: $e");
    }
    if (!isRunning) {
      debugPrint("[BGService] Servis çalışmıyor, service state timer iptal ediliyor.");
      timer.cancel();
      if (service is AndroidServiceInstance) {
        service.stopSelf();
      }
      return;
    }
  });

  /// --- MESAJ LİSTENLERİ ---

  // "stopService" mesajı alındığında konum dinleyiciyi iptal edip servisi sonlandır
  service.on('stopService').listen((event) async {
    debugPrint("[BGService] 'stopService' mesajı alındı, konum dinleyici iptal ediliyor.");
    await _positionStreamSubscription?.cancel();
    if (service is AndroidServiceInstance) {
      service.stopSelf();
    }
  });

  // "resumeService" mesajı alındığında konum takibini yeniden başlat
  service.on('resumeService').listen((event) async {
    debugPrint("[BGService] 'resumeService' mesajı alındı, konum takibi yeniden başlatılıyor.");
    await _startTracking();
  });
}
