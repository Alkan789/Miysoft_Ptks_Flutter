/*import 'dart:math' show cos, sin, sqrt, atan2;
import 'package:eyyubiye_personel_takip/cop/UserServiceApi.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Mesai bayrağı + special hours

class UserService {
  /// 1) Sabah 06:00 => dailyCheck
  static Future<void> handleMorningCheck(int userId) async {
    final now = DateTime.now();
    final totalMin = now.hour * 60 + now.minute;
    // 06:00 => 360 dk, 08:10 => 490 dk

    if (totalMin < 360 || totalMin > 490) {
      // 06:00..08:10 dışında => tablo oluşturma atlanıyor
      print("[handleMorningCheck] => 06:00..08:10 dışında => tablo oluşturma atlanıyor");
      return;
    }
    // Bu noktada 06:00..08:10 arasındayız
    print("[handleMorningCheck] => 06..08:10 arasındayız => dailyCheck çağrılıyor");

    final dailyResp = await UserServiceApi.dailyCheck(userId);
    if (dailyResp == null) return;

    final startVal = dailyResp['start'] ?? 1;  // 0 => tatil/izin/haftasonu, 1 => normal gün
    final msg = dailyResp['message'] ?? "";

    if (startVal == 0) {
      // tatil/izin/hafta sonu vs. => tablo yok
      await NotificationService().showNotificationCustom(
        "Bilgi",
        msg.isNotEmpty ? msg : "Bugün çalışma yok",
      );
      print("[handleMorningCheck] => startVal=0 => tablo oluşturma yok");
    } else {
      // Normal gün => tablo oluştur + sabah günaydın
     // await UserServiceApi.createDailyRecords(userId);
      await UserServiceApi.updateLogs(userId, "sendMorningGunaydin");
      print("[handleMorningCheck] => TABLO OLUŞTU + sendMorningGunaydin");

      // Kullanıcının özel saat tanımlaması var mı? => hasSpecialHoursToday
      final hasSpecialHours = await UserServiceApi.hasUserHours(userId);
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('hasSpecialHoursToday', hasSpecialHours);
    }
  }

  /// 2) Her saat => workmanager_situation => is_active=1, active_hours=HH:mm, location_info= lat,lng
  static Future<void> handleSituationHourly({
    required int userId,
    required double? currentLat,
    required double? currentLng,
  }) async {
    final now = DateTime.now();
    final hourStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    String? locationInfo;
    if (currentLat != null && currentLng != null) {
      locationInfo = "$currentLat,$currentLng";
    }

    await UserServiceApi.storeSituationData(
      userId: userId,
      activeHours: hourStr,
      isActive: 1,
      locationInfo: locationInfo,
    );
  }

  /// 3) Giriş / Çıkış bildirimleri
  ///    - 16:30 => mesai kontrol
  ///    - Sabah ofise yaklaşma bildirimleri (08:40,10:40,12:20 vb.)
  ///    - Akşam çıkış uyarıları (16:40,17:10,17:30)
  ///    - 21:30 => checkNoRecords2130
  static Future<void> handleGirisCikisNotifications({
    required int userId,
    required double? currentLat,
    required double? currentLng,
  }) async {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    // Özel saat bayrağını kontrol edelim: hasSpecialHoursToday
    final sp = await SharedPreferences.getInstance();
    final hasSpecialHoursToday = sp.getBool('hasSpecialHoursToday') ?? false;
    if (hasSpecialHoursToday) {
      // Kullanıcı için özel saat tanımlıysa => sabah “sendMorningGunaydin” gitti,
      // diğer uyarı / bayraklar devre dışı kalsın.
      return;
    }

    // 16:30 => mesai var mı kontrol
    if (hour == 16 && minute >= 30 && minute < 35) {
      final mesaiVar = await UserServiceApi.hasOvertime(userId);
      await sp.setBool('hasOvertimeToday', mesaiVar);
    }

    // (B) "Yaklaştınız / Vardınız" bildirimi (saat <12:00, check_in yoksa, henüz gönderilmediyse)
    // => 2 aşamalı (250m => Yaklaştınız, 100m => Vardınız)
    await _checkMorningArrivalNotification(userId, currentLat, currentLng);

    // [1] Sabah kısımları => 'check_in_location' + giriş kontrol
    bool nearOfficeMorning = await _isNearOfficeMorning(userId, currentLat, currentLng);
    if (nearOfficeMorning) {
      // 08:40 => checkGiris09
      if (hour == 8 && minute >= 40 && minute < 45) {
        final checkedIn = await UserServiceApi.getIsCheckedIn(userId);
        if (!checkedIn) {
          await UserServiceApi.updateLogs(userId, "checkGiris09");
        }
      }
      // 10:40 => checkGiris11
      if (hour == 10 && minute >= 40 && minute < 45) {
        final checkedIn = await UserServiceApi.getIsCheckedIn(userId);
        if (!checkedIn) {
          await UserServiceApi.updateLogs(userId, "checkGiris11");
        }
      }
      // 12:20 => checkGiris12_20
      if (hour == 12 && minute >= 20 && minute < 25) {
        final checkedIn = await UserServiceApi.getIsCheckedIn(userId);
        if (!checkedIn) {
          await UserServiceApi.updateLogs(userId, "checkGiris12_20");
        }
      }
    }

    // [2] Akşam kısımları => önce mesai var mı?
    final mesaiAktif = sp.getBool('hasOvertimeToday') ?? false;
    if (mesaiAktif) {
      // Eğer mesai varsa => akşam bildirimlerini pas geç
      return;
    }

    // sabah check_in yapılmış mı? => yapılmadıysa akşam bildirimi yok
    final userCheckedIn = await UserServiceApi.getIsCheckedIn(userId);
    if (!userCheckedIn) {
      return;
    }

    // check_out yapılmışsa akşam bildirimi yok
    final userCheckedOut = await UserServiceApi.statusCheckOut(userId);
    if (!userCheckedOut) {
      bool nearOfficeEvening = await _isNearOfficeEvening(userId, currentLat, currentLng);
      // 16:40 => checkCikis1655
      if (hour == 16 && minute >= 40 && minute < 45) {
        await UserServiceApi.updateLogs(userId, "checkCikis1655");
      }
      // 17:10 => checkCikis1715
      if (hour == 17 && minute >= 10 && minute < 15) {
        await UserServiceApi.updateLogs(userId, "checkCikis1715");
      }
      // 17:30 => checkCikisAfter1740
      if (hour == 17 && minute >= 30 && minute < 35) {
        await UserServiceApi.updateLogs(userId, "checkCikisAfter1740");
      }
    }

    // 21:30 => checkNoRecords2130
    if (hour == 21 && minute >= 30 && minute < 40) {
      await UserServiceApi.updateLogs(userId, "checkNoRecords2130");
    }
  }

  /// =======================
  ///   ÖZEL FONKSİYONLAR
  /// =======================

  // Sabah “Yaklaştınız / Vardınız” bildirimi (2 aşamalı)
  static Future<void> _checkMorningArrivalNotification(
      int userId,
      double? lat,
      double? lng,
      ) async {
    final now = DateTime.now();
    // 12:00 geçince sabah bildirimi yapmayalım
    if (now.hour >= 12) {
      return;
    }

    // Kullanıcı sabah check_in yapmışsa tekrar bildirim göndermiyoruz
    final checkedIn = await UserServiceApi.getIsCheckedIn(userId);
    if (checkedIn) {
      return;
    }

    final sp = await SharedPreferences.getInstance();

    // 1) 250m için "Yaklaştınız" bildirimi
    final morningNearNotified = sp.getBool('morningNearNotified') ?? false;
    if (!morningNearNotified) {
      bool near250m = await _isNearOfficeMorningCustom(userId, lat, lng, 250.0);
      if (near250m) {
        await NotificationService().showNotificationCustom(
          "Ofise Yaklaştınız",
          "Yaklaştınız! Lütfen giriş yapmayı unutmayın.",
        );
        await sp.setBool('morningNearNotified', true);
      }
    }

    // 2) 100m için "Vardınız" bildirimi
    final morningArrivedNotified = sp.getBool('morningArrivedNotified') ?? false;
    if (!morningArrivedNotified) {
      bool near100m = await _isNearOfficeMorningCustom(userId, lat, lng, 100.0);
      if (near100m) {
        await NotificationService().showNotificationCustom(
          "Ofise Yaklaştınız",
          "Vardınız! Lütfen giriş yapmayı unutmayın.",
        );
        await sp.setBool('morningArrivedNotified', true);
      }
    }
  }

  // Sabah X metre => check_in_location
  static Future<bool> _isNearOfficeMorningCustom(
      int userId,
      double? lat,
      double? lng,
      double distanceLimit,
      ) async {
    if (lat == null || lng == null) return false;
    final locStr = await UserServiceApi.getCheckInLocation(userId);
    if (locStr == null || locStr.isEmpty) return false;

    final parts = locStr.split(',');
    if (parts.length != 2) return false;

    double officeLat = double.tryParse(parts[0]) ?? 0.0;
    double officeLng = double.tryParse(parts[1]) ?? 0.0;

    double distanceM = _calculateDistanceMeters(lat, lng, officeLat, officeLng);
    return (distanceM < distanceLimit);
  }

  // Sabah 150m vb. için kullanılan fonksiyon (eski sürümle uyumlu)
  static Future<bool> _isNearOfficeMorning(int userId, double? lat, double? lng) async {
    if (lat == null || lng == null) return false;
    final locStr = await UserServiceApi.getCheckInLocation(userId);
    if (locStr == null || locStr.isEmpty) return false;

    final parts = locStr.split(',');
    if (parts.length != 2) return false;
    double officeLat = double.tryParse(parts[0]) ?? 0.0;
    double officeLng = double.tryParse(parts[1]) ?? 0.0;

    double distanceM = _calculateDistanceMeters(lat, lng, officeLat, officeLng);
    return (distanceM < 150.0);
  }

  // Akşam 150m => check_out_location
  static Future<bool> _isNearOfficeEvening(int userId, double? lat, double? lng) async {
    if (lat == null || lng == null) return false;
    final locStr = await UserServiceApi.getCheckOutLocation(userId);
    if (locStr == null || locStr.isEmpty) return false;

    final parts = locStr.split(',');
    if (parts.length != 2) return false;
    double officeLat = double.tryParse(parts[0]) ?? 0.0;
    double officeLng = double.tryParse(parts[1]) ?? 0.0;

    double distanceM = _calculateDistanceMeters(lat, lng, officeLat, officeLng);
    return (distanceM < 150.0);
  }

  // Haversine Distance
  static double _calculateDistanceMeters(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const R = 6371000; // Dünya yarıçapı (metre)
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);
}
*/