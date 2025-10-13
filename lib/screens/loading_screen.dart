import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    String reason = 'blocked';
    String versionDesc = '';
    String versionLink = '';

    String? izinDetail;
    if (args is Map) {
      reason      = args['reason'] ?? 'blocked';
      versionDesc = args['desc']   ?? '';
      versionLink = args['link']   ?? '';
      izinDetail  = args['izin_detail']; // <-- EKLENDİ
    } else if (args is String) {
      reason = args;
    }

    // Ekranda gösterilecek metin
    String displayText;
    switch (reason) {
      case 'banned':
        displayText = 'Hesabınız banlı, lütfen yöneticiye başvurun.';
        break;
      case 'holiday':
        displayText = 'Bugün tatil, sisteme erişim yapamazsınız.';
        break;
      case 'weekend':
        displayText = 'Hafta sonu, bugün sistem kapalı.';
        break;
      case 'device_not_matched':
        displayText = 'Cihaz bilgileriniz eşleşmiyor.';
        break;
      case 'device_not_allowed':
        displayText = 'Cihaz yetkiniz bulunmuyor.';
        break;
      case 'version_update':
      // Versiyon açıklaması
        displayText = versionDesc.isNotEmpty
            ? versionDesc
            : 'Yeni bir uygulama versiyonu bulundu. Lütfen güncelleyin.';
        break;
      case 'izin_or_rapor':
        if (izinDetail == 'morning') {
          displayText = 'Bugün sabah (12:00’a kadar) izinlisiniz.';
        } else if (izinDetail == 'afternoon') {
          displayText = 'Bugün öğleden sonra (12:00’dan itibaren) izinlisiniz.';
        } else if (izinDetail == 'full_day') {
          displayText = 'Bugün tam gün izinlisiniz.';
        } else if (izinDetail == 'rapor') {
          displayText = 'Bugün raporlusunuz.';
        } else {
          displayText = 'Bugün izinli/raporlusunuz.';
        }
        break;
      default:
        displayText = 'Sistem erişiminiz şu an engellendi.';
        break;
    }

    return Scaffold(
      body: Container(
        // Arka plan degrade
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // LOGO
                Image.network(
                  'https://www.eyyubiye.bel.tr/images/logo.png',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 20),

                // "Eyyübiye Belediyesi" banner
                Container(
                  width: 320,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          'https://www.eyyubiye.bel.tr/images2/slider-1.jpg',
                          fit: BoxFit.cover,
                          width: 320,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.grey.withOpacity(0.2));
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Eyyübiye Belediyesi',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 5,
                                  color: Colors.black54,
                                  offset: Offset(1, 1),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Versiyon kutusu veya engel mesajı
                Container(
                  width: 340, // Biraz daha geniş
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6369FF), // Divin kenar rengi
                      width: 3, // Kenar kalınlığı
                    ),
                  ),
                  child: Column(
                    children: [
                      // Açıklama metni
                      Text(
                        displayText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,               // Biraz daha büyük
                          fontWeight: FontWeight.bold, // Kalın
                          color: Colors.black87,
                        ),
                      ),

                      // Sadece version_update durumunda butonlar
                      if (reason == 'version_update') ...[
                        const SizedBox(height: 20),
                        // İnce yatay çizgi
                        Divider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                        ),
                        const SizedBox(height: 20),
                        // Butonlar (kapat solda, indir sağda)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // KAPAT sol
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3E9FA7), // #3e9fa7
                                minimumSize: const Size(140, 50),
                              ),
                              onPressed: _closeApp,
                              child: const Text(
                                'Kapat',
                                style: TextStyle(color: Colors.white), // <-- metni beyaz yap
                              ),
                            ),

                            // UYGULAMAYI İNDİR sağ
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6369FF), // #6369ff
                                minimumSize: const Size(140, 50),
                              ),
                              onPressed: () {
                                if (versionLink.isNotEmpty) {
                                  _openLink(versionLink);
                                }
                              },
                              child: const Text(
                                'Uygulamayı İndir',
                                style: TextStyle(color: Colors.white), // <-- metni beyaz yap
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Link tarayıcıda açma fonksiyonu
  void _openLink(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Link açılamadı: $link");
    }
  }

  // Uygulamayı kapat
  void _closeApp() {
    if (Platform.isAndroid) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } else if (Platform.isIOS) {
      Future.delayed(const Duration(milliseconds: 200), () {
        exit(0);
      });
    }
  }
}
