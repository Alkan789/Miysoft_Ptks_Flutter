package com.example.eyyubiye_personel_takip

import android.content.Context
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import kotlinx.coroutines.delay

class LocationWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        // Foreground service olarak çalışmak için gerekli bildirim bilgisi
        setForeground(createForegroundInfo())
        
        // Konum güncelleme işlemini burada gerçekleştirin.
        // Örnek: 5 saniye bekleme
        delay(5000)
        return Result.success()
    }

    private fun createForegroundInfo(): ForegroundInfo {
        val notification = NotificationCompat.Builder(applicationContext, "location_channel")
            .setContentTitle("Konum Güncelleniyor")
            .setContentText("Arka planda konumunuz alınıyor...")
            .setSmallIcon(R.mipmap.ic_launcher) // Eğer özel bir ikonunuz varsa ic_notification kullanabilirsiniz.
            .build()

        return ForegroundInfo(1, notification)
    }
}
