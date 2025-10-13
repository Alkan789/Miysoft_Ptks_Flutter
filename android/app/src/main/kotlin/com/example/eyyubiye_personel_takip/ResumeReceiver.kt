package com.example.eyyubiye_personel_takip

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class ResumeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d("ResumeReceiver", "Alarm triggered, resuming services...")

        // Burada, alarm tetiklendiğinde yapılmasını istediğin işlemleri gerçekleştirebilirsin.
        // Örneğin: Ana aktiviteyi başlatabilir veya arka plan servislerini yeniden başlatabilirsin.
        // Aşağıda, örnek olarak MainActivity’i yeniden başlatıyoruz:
        if (context != null) {
            val i = Intent(context, MainActivity::class.java)
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            context.startActivity(i)
        }
    }
}
