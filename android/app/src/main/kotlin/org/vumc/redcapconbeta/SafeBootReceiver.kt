package org.vumc.redcapconbeta

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver

/**
 * Wraps ScheduledNotificationBootReceiver to guard against the
 * "Missing type parameter" crash that occurs when stored notification
 * data is stale after a plugin upgrade. On failure, the corrupt
 * SharedPreferences entry is cleared so future boots are safe.
 */
class SafeBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            ScheduledNotificationBootReceiver().onReceive(context, intent)
        } catch (e: Exception) {
            context.getSharedPreferences("scheduled_notifications", Context.MODE_PRIVATE)
                .edit().clear().apply()
        }
    }
}
