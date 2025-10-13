import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:eyyubiye_personel_takip/utils/constants.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final int userId;

  const PrivacyPolicyScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _PrivacyPolicyScreenState createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _isChecked = false;
  bool _isLoading = false;

  final String _privacyPolicyText = """
Bu uygulama, konum bilgilerinizi kullanarak size özel hizmetler sunmaktadır. Toplanan veriler; 
- Kullanıcı deneyimini artırmak,
- Güvenlik önlemlerini sağlamak,
- Uygulamanın işlevselliğini devam ettirebilmek amacıyla kullanılmaktadır.

Verileriniz, üçüncü taraflarla paylaşılmadan, güçlü şifreleme yöntemleri ve güvenli sunucu altyapısı ile saklanmaktadır. 
Lütfen dikkat: Bu veriler, sadece uygulama tarafından belirlenen amaçlar doğrultusunda işlenmektedir. 
Kişisel verilerinizin korunması bizim için önemlidir. Gizlilik politikamızda yapılacak herhangi bir değişiklik 
sizlere bildirilecektir. 

Bu koşulları kabul ederek uygulamayı kullanmaya devam ederseniz, verilerinizin yukarıdaki şartlar dahilinde işlenmesini onaylamış sayılırsınız.
""";

  Future<void> _submitPrivacyPolicyApproval() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sp = await SharedPreferences.getInstance();
      final deviceId = sp.getString('device_info');
      final token = sp.getString(Constants.tokenKey);

      if (deviceId == null || token == null) {
        _showErrorDialog(
            "Cihaz veya token bilgisi alınamadı. Lütfen tekrar giriş yapın.");
        print("Error: deviceId: $deviceId, token: $token");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('${Constants.baseUrl}/approve-privacy-policy');
      print(
          "Sending approval request with user_id: ${widget.userId}, device_id: $deviceId");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': widget.userId,
          'device_id': deviceId,
          'is_approved': true,
        }),
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        await sp.setBool('privacy_policy_approved', true);
        Navigator.pushReplacementNamed(context, '/attendance');
      } else {
        _showErrorDialog(
            "Gizlilik politikası onayı kaydedilemedi. Status: ${response.statusCode}");
        print("Approval error response: ${response.body}");
      }
    } catch (e, stackTrace) {
      print("Exception during approval: $e");
      print("Stack trace: $stackTrace");
      _showErrorDialog("Bir hata oluştu: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar rengini sabit tutuyor, yazı rengini beyaz yapıyoruz
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF1D98F4), // rgb(29,152,244) / #1d98f4
        title: const Text(
          'Miysoft Yazılım',
          style: TextStyle(color: Colors.white), // Başlık rengi beyaz
        ),
      ),

      // Arka plan gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // Merkeze hizalanmış bir kart yapısı
        child: Center(
          child: Padding(
            padding: Constants.globalPadding,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kart içindeki büyük başlık => "Gizlilik Politikası"
                  Text(
                    "Gizlilik Politikası",
                    style: Constants.titleStyle
                        .copyWith(color: const Color.fromARGB(255, 22, 3, 192)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  // İnce bir divider/bar
                  Container(
                    height: 4,
                    width: 80,
                    color: Colors.blueAccent,
                    margin: const EdgeInsets.symmetric(horizontal: 100),
                  ),
                  const SizedBox(height: 16.0),
                  // Uzun açıklama metni (Scrollbar ile)
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Text(
                          _privacyPolicyText,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Yeni Divider (çizgi) => Checkbox üstünde
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 16.0),
                  // Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _isChecked,
                        onChanged: (value) {
                          setState(() {
                            _isChecked = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Okudum ve Onaylıyorum',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Onaylıyorum Butonu
                      ElevatedButton(
                        onPressed: _isChecked && !_isLoading
                            ? _submitPrivacyPolicyApproval
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Onaylıyorum',
                                style: TextStyle(color: Colors.white)),
                      ),

                      // Kapat Butonu
                      ElevatedButton(
                        onPressed: _exitApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text('Kapat'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
