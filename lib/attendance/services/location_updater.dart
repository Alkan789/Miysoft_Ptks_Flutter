import 'package:geolocator/geolocator.dart';
import 'package:eyyubiye_personel_takip/services/fake_location_service.dart';

class LocationService {
  final FakeLocationService _fakeLocationService = FakeLocationService();

  /// Cihazın konum değişikliklerini dinlemek için bir stream döndürür.
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Verilen konumun sahte (mock) olup olmadığını kontrol eder.
  Future<bool> isFakeLocation(Position position) async {
    // Projendeki fake_location_service.dart dosyasının bu metodu içerdiğinden emin ol.
    return await _fakeLocationService.isFakeLocation(position);
  }

  /// Kullanıcıdan konum izni ister veya mevcut izni kontrol eder.
  Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      final asked = await Geolocator.requestPermission();
      return asked != LocationPermission.denied &&
          asked != LocationPermission.deniedForever;
    }
    return true;
  }
}
