// lib/screens/battery_optimization_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BatteryOptimizationScreen extends StatelessWidget {
  final VoidCallback onDone;
  const BatteryOptimizationScreen({Key? key, required this.onDone})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pil Optimizasyonu & Arka Plan"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Arka planda çalışması için pil optimizasyonunu kapatın vs...\n",
            ),
            ElevatedButton(
              onPressed: () async {
                Uri url = Uri.parse("https://dontkillmyapp.com/");
                if (await canLaunchUrl(url)) {
                  // Eski versiyonda: 'mode' parametresi yok => kaldıralım
                  await launchUrl(url
                    // , mode: LaunchMode.externalApplication,  // BU satırı kaldır
                  );
                }
              },
              child: Text("dontkillmyapp.com"),
            ),
            SizedBox(height:20),
            ElevatedButton(
              onPressed: onDone,
              child: Text("Ayarları Yaptım, Devam Et"),
            ),
          ],
        ),
      ),
    );
  }
}
