// lib/services/geo_check_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:eyyubiye_personel_takip/services/location_save_service.dart';

class GeoCheckService {
  static final GeoCheckService _instance = GeoCheckService._internal();
  factory GeoCheckService() => _instance;
  GeoCheckService._internal();

  Future<void> checkLocation(Position pos) async {
    try {
      // Yüksek hassasiyet kontrolü
      if (pos.accuracy < 10) { // 10 metreden daha hassas konumları kabul et
        final success = await LocationSaveService().saveLocation(
          pos.latitude,
          pos.longitude,
        );
        
        if (success) {
          print("[GeoCheckService] Yüksek hassasiyetli konum kaydedildi");
        } else {
          print("[GeoCheckService] Kayıt başarısız");
        }
      } else {
        print("[GeoCheckService] Hassasiyet yetersiz: ${pos.accuracy}m");
      }
    } catch (e) {
      print("[GeoCheckService] İşlem hatası: $e");
    }
  }
}