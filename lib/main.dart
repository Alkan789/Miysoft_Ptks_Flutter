// lib/main.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

import 'services/workmanager_service.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/app_lifecycle_manager.dart';
import 'services/alarm_manager_service.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/PrivacyPolicyScreen.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:eyyubiye_personel_takip/utils/constants.dart';

import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

// Pusher entegrasyonu için gerekli import
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ──────────────────────────────────────────
// Main Konum Takibi
StreamSubscription<Position>? _mainLocationSubscription;
double? gCurrentLat;
double? gCurrentLng;

Future<void> _startMainLocationTracking() async {
  const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 0,
  );
  _mainLocationSubscription = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen((pos) {
    gCurrentLat = pos.latitude;
    gCurrentLng = pos.longitude;
    debugPrint("[Main] Konum => lat=${pos.latitude}, lng=${pos.longitude}");
  });
}

void _stopMainLocationTracking() {
  _mainLocationSubscription?.cancel();
  _mainLocationSubscription = null;
}
// ──────────────────────────────────────────

// ──────────────────────────────────────────
// Ekstra: Uygulamanın background’dan açılması (force-kill değilse)
Future<void> openAppInBackground() async {
  if (!Platform.isAndroid) return;
  const packageName = 'com.example.eyyubiyePersonelTakip';
  final intent = AndroidIntent(
    action: 'android.intent.action.MAIN',
    category: 'android.intent.category.LAUNCHER',
    package: packageName,
    flags: <int>[268435456, 67108864],
  );
  try {
    await intent.launch();
  } catch (e) {
    debugPrint("[openAppInBackground] => hata: $e");
  }
}
// ──────────────────────────────────────────

// ──────────────────────────────────────────
// FCM Background Handler (pause/resume komutlarını işler)
// Gelen data-only mesajlarda, NotificationService().showNotificationCustom() çağrısı ile yerel bildirim oluşturulur.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService().initNotifications();

  // Eğer gelen mesajda 'notification' payload'u yoksa, manuel olarak yerel bildirim oluşturuyoruz.
  if (message.notification == null) {
    await NotificationService().showNotificationCustom(
      message.data['title'] ?? 'Yeni Bildirim',
      message.data['body'] ?? 'Yeni bildirim mesajı var.',
    );
  }

  // Gelen FCM komutlarını işleyelim (pause, resume, getLocation vb.)
  await handleFcmCommand(message.data);
}
// ──────────────────────────────────────────

// Arkaplan Konum İzni Kontrolü
Future<void> checkBackgroundLocationPermission() async {
  if (Platform.isAndroid) {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        debugPrint("Arkaplan konum izni reddedildi!");
      }
    }
  }
}

Future<void> createAndroidNotificationChannel() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'critical_channel',
    'Critical Service',
    description: 'Yüksek öncelikli servis bildirimleri',
    importance: Importance.max,
    playSound: true,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await createAndroidNotificationChannel();
  await NotificationService().initNotifications();
  await checkBackgroundLocationPermission();
  await AndroidAlarmManager.initialize();

  final sp = await SharedPreferences.getInstance();
  bool pauseActive = sp.getBool('pauseActive') ?? false;

  // Eğer uygulama duraklatılmamışsa, servisleri başlatıyoruz.
  if (!pauseActive) {
    await initializeBackgroundService();
    await WorkmanagerService.initializeWorkmanager();
  }

  // Ekstra: Bugün izinli olup olmadığını kontrol edip WorkManager'ı iptal edebilirsiniz.
  final userId = sp.getInt('user_id');
  bool todayOff = false;
  /*if (userId != null) {
    todayOff = await UserServiceApi.isTodayOff(userId);
  }*/
  final now = DateTime.now();
  final weekday = now.weekday;
  if (!pauseActive &&
      (todayOff ||
          weekday == DateTime.saturday ||
          weekday == DateTime.sunday)) {
    await WorkmanagerService.cancelAllTasks();
  } else if (!pauseActive) {
    await WorkmanagerService.schedulePeriodicTask();
  }

  runApp(
    AppLifecycleManager(
      child: MyApp(),
    ),
  );
}

// ──────────────────────────────────────────
// FCM Komut İşleyicisi (pause/resume ve getLocation)
// FCM mesajları her zaman alınmaya devam eder; bu fonksiyon yalnızca WorkManager, BFS ve konum kaydetme işlemlerinde işlem yapar.
Future<void> handleFcmCommand(Map<String, dynamic> data) async {
  final action = data['action'];
  final sp = await SharedPreferences.getInstance();
  final userIdFromSp = sp.getInt('user_id');
  int? userId;
  if (data['user_id'] is int) {
    userId = data['user_id'] as int;
  } else {
    userId = int.tryParse(data['user_id']?.toString() ?? '');
  }
  if (userId == null || userId != userIdFromSp) return;

  switch (action) {
    case 'getLocation':
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        // Önceki sağlam versiyondaki URL kullanılıyor:
        final url = Uri.parse("http://192.168.1.161:8080/api/save-location");
        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "user_id": data['user_id'] ?? 0,
            "latitude": position.latitude,
            "longitude": position.longitude,
            "timestamp": DateTime.now().toIso8601String(),
          }),
        );
      } catch (e) {
        // Lokal bildirim yok, hata loglanıyor.
      }
      break;
    case 'pause':
      final duration = int.tryParse(data['duration']?.toString() ?? '60') ?? 60;
      await pauseBackgroundServices(duration);
      break;
    case 'resume':
      await resumeBackgroundServices();
      break;
  }
}

Future<void> pauseBackgroundServices(int duration) async {
  final sp = await SharedPreferences.getInstance();
  await sp.setBool('pauseActive', true);
  await sp.setInt('pauseDuration', duration);
  // WorkManager görevlerini iptal ediyoruz.
  await WorkmanagerService.cancelAllTasks();
  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    service.invoke("stopService");
  }
  await AlarmManagerService.scheduleResumeAlarm(duration);
}

Future<void> resumeBackgroundServices() async {
  final sp = await SharedPreferences.getInstance();
  await sp.setBool('pauseActive', false);

  // WorkManager görevlerini yeniden planla
  await WorkmanagerService.schedulePeriodicTask();

  // BFS/Foreground service yeniden başlatılıyor
  final service = FlutterBackgroundService();
  if (!await service.isRunning()) {
    debugPrint("[resumeBackgroundServices] => BFS çalışmıyor, başlatılıyor.");
    await service.startService();
  } else {
    debugPrint("[resumeBackgroundServices] => BFS zaten çalışıyor.");
  }
}

// ──────────────────────────────────────────

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _backgroundTime;
  final Duration _threshold = const Duration(minutes: 30);

  // Pusher değişkenleri (pusher_channels_flutter kullanımı)
  final pusher = PusherChannelsFlutter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFCMForegroundListener();
    initPusher(); // Pusher bağlantısını başlat
  }

  // Pusher bağlantısını oluştur ve dinlemeye başla
  Future<void> initPusher() async {
    try {
      await pusher.init(
        apiKey: "119fb54c8cac893dae6c", // .env dosyanızda bulunan KEY
        cluster: "eu", // .env'de bulunan CLUSTER bilgisi
        onEvent: (event) {
          debugPrint(
              "Yeni konum güncellendi: ${event.eventName} - ${event.data}");
        },
      );
      await pusher.subscribe(channelName: "mobilpersonel-development");
      await pusher.connect();
    } catch (e) {
      debugPrint("Pusher Hata: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMainLocationTracking();
    pusher.unsubscribe(channelName: "mobilpersonel-development");
    pusher.disconnect();
    super.dispose();
  }

  void _setupFCMForegroundListener() {
    FirebaseMessaging.onMessage.listen((message) async {
      if (message.data.isNotEmpty) await handleFcmCommand(message.data);
    });
  }

  Future<void> _checkAndStartServices() async {
    final service = FlutterBackgroundService();
    bool isBFSActive = await service.isRunning();
    if (!isBFSActive) {
      await service.startService();
    }
    await WorkmanagerService.schedulePeriodicTask();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final diff = DateTime.now().difference(_backgroundTime!);
        if (diff > _threshold) {
          navigatorKey.currentState
              ?.pushNamedAndRemoveUntil('/', (route) => false);
        }
      }
      _backgroundTime = null;

      // Uygulama ön plana geldiğinde servisleri kontrol et
      await _checkAndStartServices();

      final sp = await SharedPreferences.getInstance();
      final userId = sp.getInt('user_id');
      bool todayOff = false;
      /* if (userId != null) {
        todayOff = await UserServiceApi.isTodayOff(userId);
      }*/

      final now = DateTime.now();
      final weekday = now.weekday;
      if (todayOff ||
          (weekday == DateTime.saturday || weekday == DateTime.sunday)) {
        debugPrint(
            "[didChangeAppLifecycleState] => Today off or weekend => cancel WM + stop BFS");
        await WorkmanagerService.cancelAllTasks();
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke("stopService");
        }
      } else {
        await WorkmanagerService.schedulePeriodicTask();
        final service = FlutterBackgroundService();
        if (!await service.isRunning()) {
          await service.startService();
        }

        if (!await service.isRunning() && _mainLocationSubscription == null) {
          await _startMainLocationTracking();
        } else if (await service.isRunning() &&
            _mainLocationSubscription != null) {
          _stopMainLocationTracking();
        }
      }
    }
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyyübiye Personel Takip',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/attendance': (context) => AttendanceScreen(),
        '/loading': (context) => LoadingScreen(),
        // PrivacyPolicyScreen artık sadece userId alıyor, dummy değer veriyoruz:
        '/privacy-policy': (context) => PrivacyPolicyScreen(userId: 0),
      },
    );
  }
}
