// lib/services/bg_geolocation_service.dart

/*import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
as bg;
import 'package:flutter/material.dart';

class BGGeolocationService {
  /// 1) Başlangıçta bir kez çağır: arka plan konum ayarlarını, callback'lerini tanımla
  static Future<void> initialize() async {
    // Konum event'i
    bg.BackgroundGeolocation.onLocation(
          (bg.Location location) {
        debugPrint("[BGGeolocation] location: $location");
        // Burada konumu log'a basabilir, server’a atabilir vs.
      },
          (bg.LocationError error) {
        debugPrint("[BGGeolocation] location ERROR: $error");
      },
    );

    // Hareket (motion) değişimi
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      debugPrint("[BGGeolocation] motionchange => isMoving=${location.isMoving}");
    });

    // GPS/Network provider değişimi (kapatma vb.)
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      debugPrint("[BGGeolocation] providerChange => $event");
    });

    // Config => temel ayarlar
    await bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 50.0,
        stopOnTerminate: false, // uygulama kapansa da durmasın
        startOnBoot: true,      // cihaz reboot edince başlasın
        debug: true,            // debug iken bildirim vs.
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        foregroundService: true,
        enableHeadless: true,
      ),
    ).then((bg.State state) {
      debugPrint("[BGGeolocationService] ready => enabled=${state.enabled}");
      // İstersen burada otomatik startTracking() yapabilirsin:
      // if (!state.enabled) {
      //   startTracking();
      // }
    }).catchError((error) {
      debugPrint("[BGGeolocationService] ready ERROR => $error");
    });
  }

  /// 2) Servisi Başlat
  static Future<void> startTracking() async {
    await bg.BackgroundGeolocation.start().then((bg.State state) {
      debugPrint("[BGGeolocationService] start => $state");
    }).catchError((error) {
      debugPrint("[BGGeolocationService] start ERROR => $error");
    });
  }

  /// 3) Servisi Durdur
  static Future<void> stopTracking() async {
    await bg.BackgroundGeolocation.stop().then((bg.State state) {
      debugPrint("[BGGeolocationService] stop => $state");
    });
  }
}
*/