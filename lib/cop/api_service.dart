/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eyyubiye_personel_takip/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<Map<String,dynamic>?> dailyCheck(int userId) async {
    final url="${Constants.BASE_URL}/daily-check";
    try{
      final prefs=await SharedPreferences.getInstance();
      final token=prefs.getString('auth_token')??'';
      final response=await http.post(
          Uri.parse(url),
          headers:{
            'Accept':'application/json',
            'Authorization':'Bearer $token'
          },
          body:{
            'user_id':userId.toString(),
          }
      );
      if(response.statusCode==200){
        return json.decode(response.body);
      }else{
        print("=== dailyCheck => code=${response.statusCode}, body=${response.body}");
      }
    }catch(e){
      print("=== dailyCheck => error=$e");
    }
    return null;
  }

  static Future<Map<String,dynamic>?> check16h30(int userId) async {
    final url="${Constants.BASE_URL}/check16h30";
    try{
      final prefs=await SharedPreferences.getInstance();
      final token=prefs.getString('auth_token')??'';
      final response=await http.post(
          Uri.parse(url),
          headers:{
            'Accept':'application/json',
            'Authorization':'Bearer $token'
          },
          body:{
            'user_id':userId.toString()
          }
      );
      if(response.statusCode==200){
        return json.decode(response.body);
      }else{
        print("=== check16h30 => code=${response.statusCode}, body=${response.body}");
      }
    }catch(e){
      print("=== check16h30 => error=$e");
    }
    return null;
  }

  static Future<Map<String,dynamic>?> updateLogs(int userId,String flag) async {
    final url="${Constants.BASE_URL}/update-logs";
    try{
      final prefs=await SharedPreferences.getInstance();
      final token=prefs.getString('auth_token')??'';
      final response=await http.post(
          Uri.parse(url),
          headers:{
            'Accept':'application/json',
            'Authorization':'Bearer $token'
          },
          body:{
            'user_id':userId.toString(),
            'flag':flag
          }
      );
      if(response.statusCode==200){
        return json.decode(response.body);
      }else{
        print("=== updateLogs => code=${response.statusCode}, body=${response.body}");
      }
    }catch(e){
      print("=== updateLogs => error=$e");
    }
    return null;
  }

  static Future<Map<String,dynamic>?> closeDay(int userId) async {
    final url="${Constants.BASE_URL}/close-day";
    try{
      final prefs=await SharedPreferences.getInstance();
      final token=prefs.getString('auth_token')??'';
      final response=await http.post(
          Uri.parse(url),
          headers:{
            'Accept':'application/json',
            'Authorization':'Bearer $token'
          },
          body:{
            'user_id':userId.toString()
          }
      );
      if(response.statusCode==200){
        return json.decode(response.body);
      }else{
        print("=== closeDay => code=${response.statusCode}, body=${response.body}");
      }
    }catch(e){
      print("=== closeDay => error=$e");
    }
    return null;
  }

  // Konum kaydetmek istersen (opsiyonel)
  static Future<Map<String,dynamic>?> storeGeoLocation(int userId,double lat,double lng) async {
    final url="${Constants.BASE_URL}/store-geo-location";
    try{
      final prefs=await SharedPreferences.getInstance();
      final token=prefs.getString('auth_token')??'';
      final response=await http.post(
          Uri.parse(url),
          headers:{
            'Accept':'application/json',
            'Authorization':'Bearer $token'
          },
          body:{
            'user_id':userId.toString(),
            'lat':lat.toString(),
            'lng':lng.toString()
          }
      );
      if(response.statusCode==200){
        return json.decode(response.body);
      }else{
        print("=== storeGeoLocation => code=${response.statusCode}, body=${response.body}");
      }
    }catch(e){
      print("=== storeGeoLocation => error=$e");
    }
    return null;
  }
}
*/