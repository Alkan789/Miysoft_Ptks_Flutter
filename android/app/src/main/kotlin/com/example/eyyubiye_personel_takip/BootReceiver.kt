package com.example.eyyubiye_personel_takip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.time.Duration

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val locationWork = PeriodicWorkRequestBuilder<LocationWorker>(
                Duration.ofMinutes(15) // 15 dakika aralıkla
            )
                .setConstraints(constraints)
                .setInitialDelay(Duration.ofMinutes(1)) // İlk 1 dakikalık gecikme
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                "location_work",
                ExistingPeriodicWorkPolicy.REPLACE,
                locationWork
            )
        }
    }
}
