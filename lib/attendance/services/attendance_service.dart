import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart'; // Constants dosyanızın yolu
import '../models/user_profile.dart';
import '../models/attendance_data.dart';

class AttendanceService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<UserProfile?> fetchUserProfile() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserProfile.fromJson(data['user']);
    }
    return null;
  }

  Future<AttendanceData> fetchTodayAttendance() async {
    final token = await _getToken();
    if (token == null) return AttendanceData();

    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/attendance/today'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AttendanceData.fromJson(data['attendance']);
    }
    return AttendanceData();
  }

  Future<bool> checkShiftStatus(int userId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/has-shift-check'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
        body: {'user_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['has_shift'] == true;
      }
    } catch (e) {
      print("checkShiftStatus error: $e");
    }
    return false;
  }

  Future<void> fetchAndStoreWorkHours() async {
      final token = await _getToken();
      final prefs = await SharedPreferences.getInstance();
      if (token == null) return;
      // ... _fetchHours fonksiyonunun içeriği buraya gelecek ...
      // Bu fonksiyon SharedPreferences'e yazdığı için geri dönüş tipi void olabilir.
  }


  Future<Map<String, dynamic>> checkIn(int userId, Position position) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'Token bulunamadı.'};

    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/attendance/check-in'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      }),
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
        final checkInTime = data['attendance']['check_in_time'];
        return {'success': true, 'message': 'Giriş yapıldı. Saat=$checkInTime', 'time': checkInTime};
    } else {
        return {'success': false, 'message': data['message'] ?? 'Giriş yapılamadı.'};
    }
  }
  
  Future<Map<String, dynamic>> checkOut(int userId, Position position) async {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token bulunamadı.'};

      // ... checkOutAction içerisindeki http.post ve sonrası mantığı buraya gelecek ...
      final response = await http.post(
          Uri.parse('${Constants.baseUrl}/attendance/check-out'),
          headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
          },
          body: jsonEncode({
              'user_id': userId,
              'latitude': position.latitude,
              'longitude': position.longitude,
          }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
          final checkOutTime = data['attendance']['check_out_time'];
          return {'success': true, 'message': 'Çıkış yapıldı. Saat=$checkOutTime', 'time': checkOutTime};
      } else {
          return {'success': false, 'message': data['message'] ?? 'Çıkış yapılamadı.'};
      }
  }

  // Günü sıfırlama mantığı da buraya taşınabilir.
  Future<void> resetFlagsIfNewDay() async {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}";

      final prefs = await SharedPreferences.getInstance();
      final lastOpen = prefs.getString('last_open_date');

      if (lastOpen != todayStr) {
          await prefs.setString('last_open_date', todayStr);
          await prefs.setBool('didCheckIn', false); // Bu flagler artık AttendanceData'dan yönetileceği için gereksiz olabilir.
          // Diğer flag'leri de sıfırla...
      }
  }
}