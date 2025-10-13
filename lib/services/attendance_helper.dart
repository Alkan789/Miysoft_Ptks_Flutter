// lib/services/attendance_helper.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart';

Future<bool> hasAnyAttendanceToday(int? userId) async {
  if (userId == null) return false;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');
  if (token == null) return false;

  // Gün içinde check-in kontrolü
  final checkInResponse = await http.get(
    Uri.parse('${Constants.baseUrl}/attendance/check-in?user_id=$userId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  // Gün içinde check-out kontrolü
  final checkOutResponse = await http.get(
    Uri.parse('${Constants.baseUrl}/attendance/check-out?user_id=$userId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  bool checkedIn = false;
  bool checkedOut = false;
  if (checkInResponse.statusCode == 200) {
    final data = jsonDecode(checkInResponse.body);
    checkedIn = data['checked_in_today'] == true;
  }
  if (checkOutResponse.statusCode == 200) {
    final data = jsonDecode(checkOutResponse.body);
    checkedOut = data['checked_out_today'] == true;
  }

  return (checkedIn || checkedOut);
}
