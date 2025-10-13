import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:eyyubiye_personel_takip/services/fake_location_service.dart';
import 'package:eyyubiye_personel_takip/services/notification_service.dart';
import 'package:eyyubiye_personel_takip/layers/AttendanceLayer.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart';
//import 'package:eyyubiye_personel_takip/services/notification_manager.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _timeString = '00:00:00';

  String? checkInLocation;
  String? checkOutLocation;
  int? userId;
  String? userName;

  bool isFakeLocation = false;
  bool isNearCheckIn = false;
  bool isNearCheckOut = false;

  String locationStatus = 'Konumda Değilsiniz';
  Color locationColor = Colors.red;

  Position? currentPosition;
  Timer? _timer;

  final double nearDistance = 1000;
  final double arriveDistance = 50;

  bool doneCheckIn = false;
  bool doneCheckOut = false;
  String? lastCheckInTime;
  String? lastCheckOutTime;

  /// Mesai (vardiya) varsa => akşam saat kısıtı kalkacak
  bool hasShift = false;

  @override
  void initState() {
    super.initState();
    _resetFlagsIfNewDay();
    _initData();
    _startClock();
    _startLocationUpdates();
    //CustomNotificationManager().startDailyCheck(); // opsiyonel

    // Saatleri ve mesai durumunu fetch
    Future.delayed(Duration.zero, () async {
      await _fetchHours();
      await checkShiftStatus(); // Mesai durumu
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // CustomNotificationManager().dispose();
    super.dispose();
  }

  // ------------------- Mesai kontrolü --------------
  Future<void> checkShiftStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || userId == null) return;

    try {
      final url = Uri.parse('${Constants.baseUrl}/has-shift-check');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
        body: {'user_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        final js = jsonDecode(response.body);
        bool shift = js['has_shift'] == true;
        if (shift) {
          await NotificationService().showNotificationCustom(
            'Mesai Durumu',
            'Mesainiz var, çıkış saat kısıtı kalktı.',
          );
        }
        setState(() {
          hasShift = shift;
        });
      } else {
        print(
            "checkShiftStatus => code=${response.statusCode}, body=${response.body}");
      }
    } catch (e) {
      print("checkShiftStatus => error=$e");
    }
  }

  Future<void> _resetFlagsIfNewDay() async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    final prefs = await SharedPreferences.getInstance();
    final lastOpen = prefs.getString('last_open_date');

    if (lastOpen != todayStr) {
      // KALDIRILACAK --
      // Yeni gün => reset
      await prefs.setString('last_open_date', todayStr);
      await prefs.setBool('didCheckIn', false);
      await prefs.setBool('didCheckOut', false);
      await prefs.setBool('didShow16_55', false);
      await prefs.setBool('didShow17_20', false);
      await prefs.setBool('didShow20', false);

      setState(() {
        doneCheckIn = false;
        doneCheckOut = false;
        lastCheckInTime = null;
        lastCheckOutTime = null;
      });
    }
  }

  Future<void> _checkInAppNotifications() async {
    // Burada varsa saatlik local bildirim işlemleri...
  }

  Future<void> _initData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final resp = await http.get(
      Uri.parse('${Constants.baseUrl}/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final user = data['user'];
      setState(() {
        checkInLocation = user['check_in_location'];
        checkOutLocation = user['check_out_location'];
        userId = user['id'];
        userName = user['name'];
      });

      await _fetchTodayAttendance();
    } else if (resp.statusCode == 401) {
      await NotificationService().showNotificationCustom(
        'Token Süresi Doldu',
        'Lütfen tekrar giriş yapınız.',
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      await NotificationService().showNotificationCustom(
        'Hata',
        'Kullanıcı bilgisi alınamadı, tekrar deneyin.',
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _fetchTodayAttendance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); //TOKEN
    if (token == null || userId == null) return;

    try {
      final url =
          Uri.parse('${Constants.baseUrl}/attendance/today'); // GÜN KONTROL
      final r = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (r.statusCode == 200) {
        final js = jsonDecode(r.body);
        final att = js['attendance'];
        if (att == null) {
          setState(() {
            doneCheckIn = false;
            doneCheckOut = false;
            lastCheckInTime = null;
            lastCheckOutTime = null;
          });
        } else {
          final cIn = att['check_in_time'];
          final cOut = att['check_out_time'];
          setState(() {
            lastCheckInTime = cIn;
            lastCheckOutTime = cOut;
            doneCheckIn = (cIn != null);
            doneCheckOut = (cOut != null);
          });
        }
      } else {
        print("today endpoint error: ${r.body}");
      }
    } catch (e) {
      print("fetchTodayAttendance error => $e");
    }

    await _checkInAppNotifications();
  }

  void _startClock() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final h = now.hour.toString().padLeft(2, '0');
      final m = now.minute.toString().padLeft(2, '0');
      final s = now.second.toString().padLeft(2, '0');
      setState(() {
        _timeString = '$h:$m:$s';
      });
    });
  }

  void _startLocationUpdates() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      final asked = await Geolocator.requestPermission();
      if (asked == LocationPermission.denied ||
          asked == LocationPermission.deniedForever) {
        await NotificationService().showNotificationCustom(
          'Konum Hatası',
          'Konum izni verilmedi, konum alınamadı.',
        );
        return;
      }
    }

    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) async {
      currentPosition = pos;
      bool fake = await FakeLocationService().isFakeLocation(pos);
      setState(() {
        isFakeLocation = fake;
      });
      if (fake) {
        locationStatus = 'Sahte Konum Tespit Edildi';
        locationColor = Colors.red;
        await NotificationService().showNotificationCustom(
          'Uyarı',
          'Şüpheli konum, işlemler devre dışı.',
        );
      } else {
        await _fetchTodayAttendance();
        _updateLocationStatus();
      }
    });
  }

  void _updateLocationStatus() {
    if (currentPosition == null || isFakeLocation) return;
    if (checkInLocation == null || checkOutLocation == null) {
      locationStatus = 'Lokasyon tanımlı değil';
      locationColor = Colors.red;
      setState(() {});
      _checkInAppNotifications();
      return;
    }

    final inArr = checkInLocation!.split(',');
    double iLat = double.parse(inArr[0].trim());
    double iLng = double.parse(inArr[1].trim());

    final outArr = checkOutLocation!.split(',');
    double oLat = double.parse(outArr[0].trim());
    double oLng = double.parse(outArr[1].trim());

    double distIn = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      iLat,
      iLng,
    );
    double distOut = Geolocator.distanceBetween(
      currentPosition!.latitude,
      currentPosition!.longitude,
      oLat,
      oLng,
    );

    isNearCheckIn = (distIn < nearDistance);
    isNearCheckOut = (distOut < nearDistance);

    double chosenDist;
    if (!doneCheckIn && !doneCheckOut) {
      chosenDist = distIn;
    } else if (doneCheckIn && !doneCheckOut) {
      chosenDist = distOut;
    } else {
      chosenDist = (distIn < distOut) ? distIn : distOut;
    }

    String locMsg;
    if (chosenDist < arriveDistance) {
      locMsg = 'Vardınız';
      locationColor = Colors.green;
    } else if (chosenDist < nearDistance) {
      locMsg = 'Yaklaşıyorsunuz';
      locationColor = Colors.yellow;
    } else {
      locMsg = 'Konumda Değilsiniz';
      locationColor = Colors.red;
    }

    if (!doneCheckIn && !doneCheckOut) {
      locationStatus = 'Henüz giriş yapılmadı. $locMsg (Giriş Noktası)';
    } else if (doneCheckIn && !doneCheckOut) {
      locationStatus = 'Giriş yapıldı. $locMsg (Çıkış Noktası)';
    } else {
      locationStatus = 'Gün içi işlemler tamam. $locMsg';
    }
    setState(() {});
    _checkInAppNotifications();
  }

  Future<void> _fetchHours() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final url = Uri.parse('${Constants.baseUrl}/entry-exit-hours');
      final resp = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );
      //ÖZEL SAAT TANIMLIAMA ALANAI
      if (resp.statusCode == 200) {
        final js = jsonDecode(resp.body);
        if (js['success'] == true) {
          final morningStart =
              js['morning_start_time'] as String? ?? "07:00:00";
          final morningEnd = js['morning_end_time'] as String? ?? "12:00:00";
          final eveningStart =
              js['evening_start_time'] as String? ?? "12:00:00";
          final eveningEnd = js['evening_end_time'] as String? ?? "17:50:00";

          await prefs.setString('morning_start_time', morningStart);
          await prefs.setString('morning_end_time', morningEnd);
          await prefs.setString('evening_start_time', eveningStart);
          await prefs.setString('evening_end_time', eveningEnd);
        } else {
          await prefs.setString('morning_start_time', "07:00:00");
          await prefs.setString('morning_end_time', "12:00:00");
          await prefs.setString('evening_start_time', "12:00:00");
          await prefs.setString('evening_end_time', "17:50:00");
        }
      } else {
        // fallback
        await prefs.setString('morning_start_time', "07:00:00");
        await prefs.setString('morning_end_time', "12:00:00");
        await prefs.setString('evening_start_time', "12:00:00");
        await prefs.setString('evening_end_time', "17:50:00");
      }
    } catch (e) {
      // fallback
      await prefs.setString('morning_start_time', "07:00:00");
      await prefs.setString('morning_end_time', "12:00:00");
      await prefs.setString('evening_start_time', "12:00:00");
      await prefs.setString('evening_end_time', "17:50:00");
    }
  }

  Future<String> checkInAction() async {
    if (isFakeLocation) {
      await NotificationService().showNotificationCustom(
        'Giriş Başarısız',
        'Sahte konum => giriş yok.',
      );
      return 'Sahte konum => giriş yok.';
    }
    if (doneCheckIn) {
      await NotificationService().showNotificationCustom(
        'Giriş Bilgisi',
        'Bugün zaten giriş yaptınız.',
      );
      return 'Bugün zaten giriş yaptınız.';
    }
    //KULLANICI ÖZEL SAAT BÖLÜMÜ
    final prefs = await SharedPreferences.getInstance();
    final morningStart = prefs.getString('morning_start_time') ?? "07:00:00";
    final morningEnd = prefs.getString('morning_end_time') ?? "12:00:00";

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;

    final msTotal = _timeToMinutes(morningStart);
    final meTotal = _timeToMinutes(morningEnd);

    if (!(nowMin >= msTotal && nowMin < meTotal)) {
      final msg =
          'Giriş işlemi $morningStart - $morningEnd arasında yapılabilir.';
      await NotificationService().showNotificationCustom(
        'Giriş İzni Yok',
        msg,
      );
      return msg;
    }

    if (!isNearCheckIn) {
      await NotificationService().showNotificationCustom(
        'Konum Uyarısı',
        'Check-in lokasyonuna yakın değilsiniz.',
      );
      return 'Check-in lokasyonuna yakın değilsiniz.';
    }

    String? token = prefs.getString('auth_token');
    if (token == null || userId == null || currentPosition == null) {
      await NotificationService().showNotificationCustom(
        'Giriş Başarısız',
        'Eksik veri => Giriş yapılamadı.',
      );
      return 'Eksik veri => Giriş yapılamadı.';
    }

    final r = await http.post(
      Uri.parse('${Constants.baseUrl}/attendance/check-in'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'latitude': currentPosition!.latitude,
        'longitude': currentPosition!.longitude,
      }),
    );
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      final att = data['attendance'];
      final cInTime = att['check_in_time'];

      setState(() {
        doneCheckIn = true;
        lastCheckInTime = cInTime;
      });

      await prefs.setBool('didCheckIn', true);

      final msg = 'Giriş yapıldı. Saat=$cInTime';
      await NotificationService().showNotificationCustom(
        'Giriş Başarılı',
        msg,
      );
      return msg;
    } else {
      final dt = jsonDecode(r.body);
      final errMsg = dt['message'] ?? 'Giriş yapılamadı.';
      await NotificationService().showNotificationCustom(
        'Giriş Başarısız',
        errMsg,
      );
      return errMsg;
    }
  }

  Future<String> checkOutAction() async {
    if (isFakeLocation) {
      await NotificationService().showNotificationCustom(
        'Çıkış Başarısız',
        'Sahte konum => çıkış yok.',
      );
      return 'Sahte konum => çıkış yok.';
    }
    if (!doneCheckIn) {
      await NotificationService().showNotificationCustom(
        'Çıkış Başarısız',
        'Bugün giriş yapmadınız => çıkış yok.',
      );
      return 'Bugün giriş yapmadınız => çıkış yok.';
    }
    if (doneCheckOut) {
      await NotificationService().showNotificationCustom(
        'Çıkış Bilgisi',
        'Bugün zaten çıkış yaptınız.',
      );
      return 'Bugün zaten çıkış yaptınız.';
    }

    if (!hasShift) {
      final prefs = await SharedPreferences.getInstance();
      final eveningStart = prefs.getString('evening_start_time') ?? "12:00:00";
      final eveningEnd = prefs.getString('evening_end_time') ?? "17:50:00";

      final now = DateTime.now();
      final nowMin = now.hour * 60 + now.minute;

      final esTotal = _timeToMinutes(eveningStart);
      final eeTotal = _timeToMinutes(eveningEnd);

      if (!(nowMin >= esTotal && nowMin < eeTotal)) {
        final msg =
            'Çıkış işlemi $eveningStart - $eveningEnd arasında yapılabilir.';
        await NotificationService().showNotificationCustom(
          'Çıkış İzni Yok',
          msg,
        );
        return msg;
      }
    } else {
      print("Mesai var => saat kısıtı yok => direk devam.");
    }

    SharedPreferences sp = await SharedPreferences.getInstance();
    String? token = sp.getString('auth_token');
    if (token == null || userId == null || currentPosition == null) {
      await NotificationService().showNotificationCustom(
        'Çıkış Başarısız',
        'Eksik veri => Çıkış yapılamadı.',
      );
      return 'Eksik veri => Çıkış yapılamadı.';
    }

    final r = await http.post(
      Uri.parse('${Constants.baseUrl}/attendance/check-out'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'latitude': currentPosition!.latitude,
        'longitude': currentPosition!.longitude,
      }),
    );
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      final att = data['attendance'];
      final cOutTime = att['check_out_time'];

      setState(() {
        doneCheckOut = true;
        lastCheckOutTime = cOutTime;
      });

      await sp.setBool('didCheckOut', true);

      final msg = 'Çıkış yapıldı. Saat=$cOutTime';
      await NotificationService().showNotificationCustom(
        'Çıkış Başarılı',
        msg,
      );
      return msg;
    } else {
      final dt = jsonDecode(r.body);
      final errMsg = dt['message'] ?? 'Çıkış yapılamadı.';
      await NotificationService().showNotificationCustom(
        'Çıkış Başarısız',
        errMsg,
      );
      return errMsg;
    }
  }

  int _timeToMinutes(String hhmmss) {
    final parts = hhmmss.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    final displayCheckIn = (lastCheckInTime == null)
        ? 'Henüz giriş yapılmadı'
        : 'Giriş Saati: $lastCheckInTime';
    final displayCheckOut = (lastCheckOutTime == null)
        ? 'Henüz çıkış yapılmadı'
        : 'Çıkış Saati: $lastCheckOutTime';

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/primaryBg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                // Logo
                Center(
                  child: Container(
                    width: 300,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.1), // Saydam arka plan
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Miysoft Yazılım',
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Pacifico',
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                Text(
                  userName == null ? 'Hoşgeldiniz' : 'Hoşgeldiniz, $userName',
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Poppins-Medium',
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 5,
                  width: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(height: 10),

                // Giriş/Çıkış Saatleri
                Container(
                  width: 320,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        displayCheckIn,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins-Medium',
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        displayCheckOut,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins-Medium',
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Konum Durumu
                Container(
                  width: 320,
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    locationStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: locationColor,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // [DÜZELTİLMİŞ] "Konum + Haritada Gör" satırı
                Container(
                  width: 320,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Koordinat Metni
                      Expanded(
                        child: Center(
                          child: (currentPosition == null)
                              ? Text(
                                  'Konum alınıyor...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins-Medium',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  '${currentPosition!.latitude.toStringAsFixed(5)}, '
                                  '${currentPosition!.longitude.toStringAsFixed(5)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins-Medium',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // Sabit genişlikte buton
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Ekrandaki saat
                Container(
                  width: 320,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _timeString,
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Poppins-Medium',
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Butonlar (Giriş Yap / Çıkış Yap)
                Container(
                  width: double.infinity,
                  height: 300,
                  child: AttendanceLayer(
                    onCheckIn: checkInAction,
                    onCheckOut: checkOutAction,
                    isFakeLocation: isFakeLocation,
                    isNearCheckIn: isNearCheckIn,
                    isNearCheckOut: isNearCheckOut,
                    doneCheckIn: doneCheckIn,
                    doneCheckOut: doneCheckOut,
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
