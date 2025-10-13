/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eyyubiye_personel_takip/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--

class ApiService {
  static Future<Map<String, dynamic>?> dailyCheck(int userId) async {
    final url = "${Constants.BASE_URL}/daily-check";
    try {
      // 1) token + 'Bearer ' => header
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      // token = 'eyJhbGci...'

      print("=== ApiService.dailyCheck => userId=$userId => url=$url => token=$token");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // Sanctum expects this
        },
        body: {
          'user_id': userId.toString(),
        },
      );
      print("=== dailyCheck => statusCode=${response.statusCode}");
      print("=== dailyCheck => body=${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print("=== dailyCheck => ERROR code:${response.statusCode} body=${response.body}");
      }
    } catch (e) {
      print("=== dailyCheck => Exception $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> check16h30(int userId) async {
    final url = "${Constants.BASE_URL}/check16h30";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
        },
      );
      // ...
    } catch (e) {
      // ...
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateLogs(int userId, String flag) async {
    final url = "${Constants.BASE_URL}/update-logs";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
          'flag': flag,
        },
      );
      // ...
    } catch (e) {
      // ...
    }
    return null;
  }

  static Future<Map<String, dynamic>?> closeDay(int userId) async {
    final url = "${Constants.BASE_URL}/close-day";
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
        },
      );
      // ...
    } catch (e) {
      // ...
    }
    return null;
  }
}
*/