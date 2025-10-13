// android/app/src/main/kotlin/com/example/eyyubiye_personel_takip/MainActivity.kt
package com.example.eyyubiye_personel_takip

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleResumeAlarm" -> {
                    val pauseDuration = call.argument<Int>("pauseDuration") ?: 0
                    scheduleResumeAlarm(pauseDuration)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleResumeAlarm(pauseDuration: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // ResumeReceiver adlı BroadcastReceiver'ı kullanıyoruz.
        val intent = Intent(this, ResumeReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val triggerTime = System.currentTimeMillis() + pauseDuration * 60 * 1000L
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "location_channel",
                "Konum Servisi",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun disableBatteryOptimization() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        //disableBatteryOptimization()
        Handler(Looper.getMainLooper()).postDelayed({
            disableBatteryOptimization()
        }, 2000) // 2000ms = 2 saniye
    }
}
