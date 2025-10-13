/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Bu senin sabit URL vs. (utils/constants.dart'tan alabilir)
// Burada sabit olarak ekledim => "http://192.168.1.152:8000/api"
class MergedApiService {
  static const String baseUrl = "http://192.168.1.179:8000/api";

  /// daily-check => { "start":0/1, "message":"Tatil" }
  static Future<Map<String, dynamic>?> dailyCheck(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";
    final url = "$baseUrl/daily-check";
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
        },
      );
      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      }
    } catch(e) {
      print("[MergedApiService] dailyCheck => error $e");
    }
    return null;
  }

  /// close-day => sunucuda mesaiyi kapatma
  static Future<Map<String, dynamic>?> closeDay(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";
    final url = "$baseUrl/close-day";

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
        },
      );
      if (resp.statusCode == 200) {
        return json.decode(resp.body);
      } else {
        print("[MergedApiService] closeDay => code=${resp.statusCode}, body=${resp.body}");
      }
    } catch(e) {
      print("[MergedApiService] closeDay => error $e");
    }
    return null;
  }

  /// update-logs => checkGiris09 vb.
  static Future<void> updateLogs(int userId, String flag) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";
    final url = "$baseUrl/update-logs";
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Accept':'application/json',
          'Authorization':'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
          'flag': flag,
        },
      );
      if (resp.statusCode != 200) {
        print("[MergedApiService] updateLogs => code=${resp.statusCode} body=${resp.body}");
      }
    } catch(e) {
      print("[MergedApiService] updateLogs => error $e");
    }
  }

  /// store-geolocation => konum kaydı
  static Future<void> storeGeoLocation(int userId, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";
    final url = "$baseUrl/store-geolocation";
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Accept':'application/json',
          'Authorization':'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
          'latitude': lat.toString(),
          'longitude': lng.toString(),
        },
      );
      if (resp.statusCode != 200) {
        print("[MergedApiService] storeGeoLocation => code=${resp.statusCode}, body=${resp.body}");
      }
    } catch(e) {
      print("[MergedApiService] storeGeoLocation => error $e");
    }
  }

  /// get-checkin-location => "37.13318,38.74039"
  static Future<String?> getCheckInLocation(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";
    final url = "$baseUrl/get-checkin-location";

    try {
      print("[MergedApiService] getCheckInLocation => userId=$userId, token=$token");
      final resp = await http.post(
        Uri.parse(url),
        headers: {
          'Accept':'application/json',
          'Authorization':'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
        },
      );
      print("[MergedApiService] statusCode=${resp.statusCode}, body=${resp.body}");
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data['status'] == 'ok') {
          final loc = data['data'] as String?;
          print("[MergedApiService] Gelen loc => $loc");
          return loc;
        }
      }
    } catch(e) {
      print("[MergedApiService] getCheckInLocation => error $e");
    }
    return null;
  }
}
*/