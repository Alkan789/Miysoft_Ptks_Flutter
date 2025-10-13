// lib/services/fake_location_service.dart

import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:detect_fake_location/detect_fake_location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Sahte konum analizi + raporlama
class FakeLocationService {
  Position? _lastPosition;
  DateTime? _lastTime;
  bool _alreadyReported = false;

  /// Hem "mock location API" hem hız/mesafe analiz ederek sahte konumu yakalar.
  /// Sahte tespit ederse bir kez raporlar ve true döndürür.
  Future<bool> isFakeLocation(Position currentPos) async {
    // 1) detect_fake_location paketi
    final detect = DetectFakeLocation();
    bool isMock = false;
    try {
      isMock = await detect.detectFakeLocation();
    } catch (_) {
      // Bazı cihazlarda hata olabilir, default false
      isMock = false;
    }
    if (isMock) {
      if (!_alreadyReported) {
        _alreadyReported = true;
        await _reportFakeLocation(currentPos, reason: 'MOCK_API');
      }
      return true;
    }

    // 2) Hız / mesafe analizi
    if (_lastPosition == null) {
      // ilk veri
      _lastPosition = currentPos;
      _lastTime = DateTime.now();
      return false;
    }

    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      currentPos.latitude,
      currentPos.longitude,
    );
    final diff = DateTime.now().difference(_lastTime!);

    // Örneğin <1sn’de >500m
    if (diff.inSeconds < 1 && distance > 500) {
      if (!_alreadyReported) {
        _alreadyReported = true;
        await _reportFakeLocation(currentPos, reason: 'DISTANCE<1S');
      }
      return true;
    }

    // ~720 km/h => 200 m/sn
    double secs = diff.inSeconds.toDouble();
    if (secs == 0) secs = 1;
    double speed = distance / secs;
    if (speed > 200) {
      if (!_alreadyReported) {
        _alreadyReported = true;
        await _reportFakeLocation(currentPos, reason: 'SPEED');
      }
      return true;
    }

    // değil
    _lastPosition = currentPos;
    _lastTime = DateTime.now();
    return false;
  }

  /// Sunucuya sahte konum raporu (isteğe bağlı).
  Future<void> _reportFakeLocation(Position pos, {String reason = 'UNKNOWN'}) async {
    try {
      final sp = await SharedPreferences.getInstance();
      String? token = sp.getString('auth_token');
      int? userId = sp.getInt('user_id');
      String userName = sp.getString('user_name') ?? 'Unknown';

      if (token == null || userId == null) return;

      final body = {
        'user_id': userId,
        'user_name': userName,
        'device_info': 'TODO-device-info',
        'fake_lat': pos.latitude,
        'fake_lng': pos.longitude,
        'reason': reason,
      };

      // Örnek bir endpoint (kendi sunucunuza göre düzenleyebilirsiniz)
      final url = Uri.parse('http://192.168.1.161:8080/api/fake-location/report');
      final resp = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (resp.statusCode == 201) {
        print('Sahte konum raporu gönderildi => reason=$reason');
      } else {
        print('Sahte konum raporu hata => ${resp.body}');
      }
    } catch (e) {
      print('fakeLocation report hata => $e');
    }
  }
}


