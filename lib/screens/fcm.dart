import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// <-- Constants import
import 'package:eyyubiye_personel_takip/utils/constants.dart';

class FcmScreen extends StatefulWidget {
  @override
  _FcmScreenState createState() => _FcmScreenState();
}

class _FcmScreenState extends State<FcmScreen> {
  String _info = 'Henüz işlem yapılmadı';

  /// Tek buton: FCM token al, Laravel API'ye kaydet
  Future<void> _getTokenAndSave() async {
    setState(() {
      _info = 'Token alınıyor...';
    });

    try {
      // 1) FCM token al
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        setState(() {
          _info = 'Token alınamadı (null)';
        });
        return;
      }

      // 2) user_id'yi SharedPreferences'tan al
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id');
      if (userId == null) {
        setState(() {
          _info = 'Kullanıcı kimliği bulunamadı (user_id). Lütfen önce login olun.';
        });
        return;
      }

      // 3) Laravel API'ye POST isteği
      // Eskiden: http://192.168.1.123:8000/api/store-fcm-token
      final url = Uri.parse("${Constants.baseUrl}/store-fcm-token");
      setState(() {
        _info = 'Token: $token\nKullanıcı: $userId\nLaravel API\'ye gönderiliyor...';
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _info = 'Token başarıyla kaydedildi.\nCevap: ${response.body}';
        });
      } else {
        setState(() {
          _info = 'Kayıt başarısız. Status: ${response.statusCode}\nBody: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _info = 'Hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FCM Token Kaydetme Ekranı'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'FCM Token Al ve Laravel API\'ye Kaydet',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getTokenAndSave,
              child: Text('Token Al & Kaydet'),
            ),
            SizedBox(height: 20),
            Text(
              _info,
              style: TextStyle(color: Colors.blueGrey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
