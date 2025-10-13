/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// <-- Constants import
import 'package:eyyubiye_personel_takip/utils/constants.dart';

class UserServiceApi {

  /// 1) dailyCheck
  static Future<Map<String, dynamic>?> dailyCheck(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/daily-check");
    try {
      final resp = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }
    } catch (e) {
      print("[dailyCheck] Exception => $e");
    }
    return null;
  }

  /// 2) createDailyRecords
  /*static Future<void> createDailyRecords(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/create-daily-records");
    try {
      final resp = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
        },
      );
      if (resp.statusCode == 200) {
        print("[createDailyRecords] => OK");
      } else {
        print("[createDailyRecords] => status=${resp.statusCode}, body=${resp.body}");
      }
    } catch (e) {
      print("[createDailyRecords] Exception => $e");
    }
  }*/

  /// 3) updateLogs
  static Future<void> updateLogs(int userId, String flag) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/update-logs");
    try {
      final resp = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
          'flag': flag,
        },
      );
      if (resp.statusCode == 200) {
        print("[updateLogs] => flag=$flag => OK");
      } else {
        print("[updateLogs] => status=${resp.statusCode}, body=${resp.body}");
      }
    } catch (e) {
      print("[updateLogs] Exception => $e");
    }
  }

  /// 4) storeGeoLocation
  static Future<void> storeGeoLocation(int userId, double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/store-geolocation");
    try {
      final resp = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'latitude': lat,
          'longitude': lng,
        }),
      );
      if (resp.statusCode == 200) {
        print("[storeGeoLocation] => OK");
      }
    } catch (e) {
      print("[storeGeoLocation] Exception => $e");
    }
  }

  /// 5) storeSituationData
  static Future<void> storeSituationData({
    required int userId,
    required String activeHours,
    required int isActive,
    String? locationInfo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/store-situation-data");
    try {
      final resp = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': userId.toString(),
          'active_hours': activeHours,
          'is_active': isActive.toString(),
          'location_info': locationInfo ?? "",
        },
      );
      if (resp.statusCode == 200) {
        print("[storeSituationData] => OK");
      } else {
        print("[storeSituationData] => status=${resp.statusCode}");
      }
    } catch (e) {
      print("[storeSituationData] Exception => $e");
    }
  }

  /// Giriş konumu
  static Future<String?> getCheckInLocation(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = "${Constants.baseUrl}/get-check-in-location";
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
        final data = json.decode(resp.body);
        if (data is Map && data.containsKey('check_in_location')) {
          return data['check_in_location'].toString();
        }
      }
    } catch (e) {
      print("[getCheckInLocation] Exception => $e");
    }
    return null;
  }

  /// Çıkış konumu
  static Future<String?> getCheckOutLocation(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = "${Constants.baseUrl}/get-check-out-location";
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
        final data = json.decode(resp.body);
        if (data is Map && data.containsKey('check_out_location')) {
          return data['check_out_location'].toString();
        }
      }
    } catch (e) {
      print("[getCheckOutLocation] Exception => $e");
    }
    return null;
  }

  /// attendance tablosunda bugun check_in_time var mi
  static Future<bool> getIsCheckedIn(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = "${Constants.baseUrl}/is-checked-in";
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
        final data = json.decode(resp.body);
        if (data is Map && data.containsKey('checkedIn')) {
          return data['checkedIn'] == true;
        }
      }
    } catch (e) {
      print("[getIsCheckedIn] Exception => $e");
    }
    return false;
  }

  /// bugun check-in yapmis mi?
  static Future<bool> statusCheckIn(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/attendance/check-in?user_id=$userId");
    try {
      final resp = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map && data.containsKey('checked_in_today')) {
          return data['checked_in_today'] == true;
        }
      }
    } catch (e) {
      print("[statusCheckIn] Exception => $e");
    }
    return false;
  }

  /// bugun check-out yapmis mi?
  static Future<bool> statusCheckOut(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/attendance/check-out?user_id=$userId");
    try {
      final resp = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map && data.containsKey('checked_out_today')) {
          return data['checked_out_today'] == true;
        }
      }
    } catch (e) {
      print("[statusCheckOut] Exception => $e");
    }
    return false;
  }

  /// 6) hasOvertime => mesai var mi?
  static Future<bool> hasOvertime(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/attendance/overtime?user_id=$userId");
    try {
      final resp = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        // data: { "has_overtime_today": true/false }
        if (data is Map && data.containsKey('has_overtime_today')) {
          return data['has_overtime_today'] == true;
        }
      }
    } catch (e) {
      print("[hasOvertime] Exception => $e");
    }
    return false;
  }

  /// [NEW] hasUserHours => Kullanıcının özel saat tanımlaması var mi?
  static Future<bool> hasUserHours(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    // Örnek: GET /has-user-hours?user_id=..
    final url = Uri.parse("${Constants.baseUrl}/has-user-hours?user_id=$userId");
    try {
      final resp = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        // data: { "hasUserHours": true/false }
        if (data is Map && data.containsKey('hasUserHours')) {
          return data['hasUserHours'] == true;
        }
      }
    } catch (e) {
      print("[hasUserHours] Exception => $e");
    }
    return false;
  }

  static Future<bool> isTodayOff(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? "";

    final url = Uri.parse("${Constants.baseUrl}/is-today-off?user_id=$userId");
    try {
      final resp = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        // data: { "isOff": true/false }
        if (data is Map && data.containsKey('isOff')) {
          return data['isOff'] == true;
        }
      }
    } catch (e) {
      print("[isTodayOff] Exception => $e");
    }
    return false;
  }
}
*/