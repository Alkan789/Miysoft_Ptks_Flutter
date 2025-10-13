import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart';

class AttendanceService {
  // baseUrl artık sabit bir string tanımını kaldırdık.
  // final String baseUrl = "http://192.168.184.247:8000/api"; // GEREK YOK

  Future<String> checkIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      return 'Token bulunamadı, lütfen tekrar giriş yapın.';
    }

    Position position = await _determinePosition();

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/attendance/check-in'),  // Constants.baseUrl kullandık
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Giriş başarılı.';
    } else {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Giriş yapılamadı.';
    }
  }

  Future<String> checkOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      return 'Token bulunamadı, lütfen tekrar giriş yapın.';
    }

    Position position = await _determinePosition();

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/attendance/check-out'), // Constants.baseUrl kullandık
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': position.latitude,
        'longitude': position.longitude,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Çıkış başarılı.';
    } else {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Çıkış yapılamadı.';
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Konum servisleri kapalı.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Konum izni verilmedi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Konum izni kalıcı olarak reddedildi.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}

