import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eyyubiye_personel_takip/utils/constants.dart';

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  Future<String> login(String name, String password) async {
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'] ?? '';
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Giriş başarısız');
      }
    } catch (e) {
      throw Exception('Login Hatası: $e');
    }
  }

  Future<bool> verifyDevice(String token, String deviceInfo) async {
    final url = Uri.parse('$baseUrl/device/verify');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_info': deviceInfo,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Cihaz doğrulama başarısız');
      }
    } catch (e) {
      throw Exception('Cihaz Doğrulama Hatası: $e');
    }
  }
}