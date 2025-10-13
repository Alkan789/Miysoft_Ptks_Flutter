// lib/services/battery_optimization_helper.dart

import 'dart:io';
import 'package:flutter/services.dart';

class BatteryOptimizationHelper {
  static const MethodChannel _channel = MethodChannel('myBatteryChannel');

  /// Eğer true dönerse => zaten pil optimizasyonundan hariç
  /// false dönerse => hala optimizasyon altında
  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    final bool result = await _channel.invokeMethod("isIgnoringBatteryOptimizations");
    return result;
  }

  /// Kullanıcıyı ayar ekranına gönderir,
  /// orada "Bu uygulamayı pil optimizasyonundan hariç tut" seçeneği çıkar.
  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod("requestIgnoreBatteryOptimizations");
  }
}
