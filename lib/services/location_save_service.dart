import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart';

class LocationSaveService {
  static final LocationSaveService _instance = LocationSaveService._internal();
  factory LocationSaveService() => _instance;
  LocationSaveService._internal();

  /// Konumu veritabanına (Laravel API) kaydeder.
  /// Başarılıysa true, hatada false döndürür ve konsola log basar.
  Future<bool> saveLocation(double lat, double lng) async {
    try {
      // 1) SharedPrefs'tan user_id ve auth_token al
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');
      final String? token = prefs.getString('auth_token');

      final int realUserId = userId ?? 0;

      // 2) HTTP POST => /api/geo-log
      final url = Uri.parse("${Constants.baseUrl}/geo-log");
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'user_id': realUserId.toString(),
          'lat': lat.toString(),
          'lng': lng.toString(),
          // 'status' vb. lazımsa ekleyin
        },
      );

      // 3) Sonuç
      if (response.statusCode == 200) {
        print("[LocationSaveService] Kayıt başarılı => ${response.body}");
        return true;
      } else {
        print("[LocationSaveService] Kayıt hatalı => "
            "${response.statusCode} => ${response.body}");
        return false;
      }
    } catch (e) {
      print("[LocationSaveService] Exception => $e");
      return false;
    }
  }
}