import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Bildirim servisi (local notification)
import 'package:eyyubiye_personel_takip/services/notification_service.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart';

// FCM ile entegre
import 'package:firebase_messaging/firebase_messaging.dart';

class LayerThree extends StatefulWidget {
  @override
  _LayerThreeState createState() => _LayerThreeState();
}

class _LayerThreeState extends State<LayerThree> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> showNotification(String title, String body) async {
    await NotificationService().showNotificationCustom(title, body);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Donanım bilgisinden (brand_model_id) bir string üretir
  Future<String> _getHardwareInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
  }

  /// device_info değerini SharedPreferences'ta saklamak veya okumak
  Future<String> _resolveDeviceInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? existingDeviceInfo = prefs.getString('device_info');
    if (existingDeviceInfo != null && existingDeviceInfo.isNotEmpty) {
      return existingDeviceInfo;
    } else {
      String newDeviceInfo = await _getHardwareInfo();
      await prefs.setString('device_info', newDeviceInfo);
      return newDeviceInfo;
    }
  }

  /// LOGIN isteği (Sunucu, yeni cihazsa random ekleyecek, biz de cevaptan okuyacağız)
  Future<void> _loginUser() async {
    final identifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen e-posta veya telefon numarası ve şifre giriniz.')),
      );
      return;
    }

    // Email veya telefon numarası kontrolü
    final isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(identifier);
    final isPhone = RegExp(r'^05[0-9]{9}$').hasMatch(identifier);

    if (!isEmail && !isPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçerli bir e-posta veya telefon numarası giriniz.')),
      );
      return;
    }

    // 1) deviceInfo
    final deviceInfo = await _resolveDeviceInfo();

    // 2) FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    try {
      // 3) /login isteği
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          isEmail ? 'email' : 'phone': identifier, // Email veya telefon numarası
          'password': password,
          'device_info': deviceInfo,
          'fcm_token': fcmToken ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // success
          final token = data['access_token'];
          final userMap = data['user'];
          final userId = userMap['id'];
          final userName = userMap['name'];

          // SUNUCUDA RANDOM EKLİ CİHAZ BİLGİSİ => serverDeviceInfo
          final serverDeviceInfo = userMap['device_info'] ?? '';

          SharedPreferences prefs = await SharedPreferences.getInstance();
          // Token kaydı
          await prefs.setString('auth_token', token);
          await prefs.setInt('user_id', userId);
          await prefs.setString('user_name', userName);

          // Eğer "device_info" sunucuda random eklenmişse => kaydet
          if (serverDeviceInfo.isNotEmpty) {
            await prefs.setString('device_info', serverDeviceInfo);
          }

          await showNotification('Giriş Başarılı', 'Hoşgeldiniz $userName');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Giriş başarılı: $userName')),
          );

          Navigator.pushReplacementNamed(context, '/attendance');
        } else {
          // Olası hata: "already has a device" vs.
          final errorMsg = data['message'] ?? 'Giriş başarısız';
          if (data['banned'] == true) {
            await showNotification('Ban Durumu', data['ban_reason'] ?? 'Banlısınız');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } else {
        // 400.. vb.
        final d = jsonDecode(response.body);
        final msg = d['message'] ?? 'Giriş başarısız';
        if (d['banned'] == true) {
          await showNotification('Ban Durumu', d['ban_reason'] ?? 'Banlısınız');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      await showNotification('Hata', 'Giriş esnasında hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Container(
        height: 584,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            Positioned(
              left: 59,
              top: 99,
              child: Text(
                'Kullanıcı Adı',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: 59,
              top: 129,
              child: Container(
                width: 310,
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    hintText: 'E-posta veya Telefon Numarası',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 59,
              top: 199,
              child: Text(
                'Şifre',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: 59,
              top: 229,
              child: Container(
                width: 310,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(),
                    hintText: 'Şifre Giriniz',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 320,
              left: 59,
              right: 59,
              child: GestureDetector(
                onTap: _loginUser,
                child: Container(
                  width: 310,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Giriş Yap',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}