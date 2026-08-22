// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.autorecord

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * #3756 — MANIFEST-declared ACL wake path for a DEAD app process.
 *
 * Field logs 2026-08-22 show repeated background `low_memory_kill`s:
 * once Android reclaims the process, the context-registered
 * [BtAclEngineStartReceiver] is gone and NOTHING notices the car any
 * more — hands-free recording silently doesn't work until the user
 * happens to open the app ("does not work most of the time").
 *
 * [BluetoothDevice.ACTION_ACL_CONNECTED] is on the implicit-broadcast
 * exemption list precisely for this: a manifest receiver revives the
 * process when the PINNED adapter connects. Honoring the #3688
 * engine-churn lesson, this receiver spins NO FlutterEngine — it posts
 * one plain notification ("car connected — tap to record") whose copy
 * was localized Dart-side and mirrored into SharedPreferences by the
 * auto-record orchestrator. Tapping launches the app normally; the
 * orchestrator then arms and records.
 *
 * Guards:
 *  * exact (case-insensitive) match against the mirrored adapter MAC —
 *    unlike the in-process hint this path is FILTERED, because a
 *    notification for every headphone connect would be spam;
 *  * skipped entirely while the Flutter engine is alive
 *    ([FlutterEngineLiveness]) — the in-process hint already dials;
 *  * one notification per [THROTTLE_MS] (its own prefs file, so the
 *    Flutter prefs stay Dart-owned);
 *  * missing POST_NOTIFICATIONS just no-ops (NotificationManagerCompat
 *    swallows it) — never crashes the revived process.
 */
class AdapterWakeReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AdapterWake"
        private const val CHANNEL_ID = "adapter_wake"

        // System-settings-only label; English literal by the same
        // convention as every other notification channel name.
        private const val CHANNEL_LABEL = "Car adapter connected"
        private const val NOTIFICATION_ID = 37560 // #3756
        private const val THROTTLE_MS = 30L * 60L * 1000L
        private const val THROTTLE_PREFS = "adapter_wake_receiver"
        private const val KEY_LAST_POSTED = "last_posted_at"

        // Dart-mirrored keys (shared_preferences adds the flutter. prefix).
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val KEY_MAC = "flutter.acl_wake_mac"
        private const val KEY_TITLE = "flutter.acl_wake_title"
        private const val KEY_BODY = "flutter.acl_wake_body"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != BluetoothDevice.ACTION_ACL_CONNECTED) return
        if (FlutterEngineLiveness.alive) return // in-process hint owns it

        val flutterPrefs =
            context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val pinnedMac = flutterPrefs.getString(KEY_MAC, null) ?: return
        val device: BluetoothDevice? =
            if (android.os.Build.VERSION.SDK_INT >=
                android.os.Build.VERSION_CODES.TIRAMISU
            ) {
                intent.getParcelableExtra(
                    BluetoothDevice.EXTRA_DEVICE,
                    BluetoothDevice::class.java,
                )
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
            }
        val mac = device?.address ?: return
        if (!mac.equals(pinnedMac, ignoreCase = true)) return

        val throttle =
            context.getSharedPreferences(THROTTLE_PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        if (now - throttle.getLong(KEY_LAST_POSTED, 0L) < THROTTLE_MS) return
        throttle.edit().putLong(KEY_LAST_POSTED, now).apply()

        val title = flutterPrefs.getString(KEY_TITLE, null) ?: "Car connected"
        val body = flutterPrefs.getString(KEY_BODY, null)
            ?: "Tap to open Sparkilo — trip recording can start."

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_LABEL,
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply { setShowBadge(false) },
            )
        }
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: return
        val tap = PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(tap)
            .setAutoCancel(true)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .build()
        NotificationManagerCompat.from(context)
            .notify(NOTIFICATION_ID, notification)
        Log.d(TAG, "posted wake notification for $mac (process was cold)")
    }
}

/**
 * #3756 — process-level flag: true while a FlutterEngine is configured.
 * [AdapterWakeReceiver] skips its notification when the engine is alive
 * (the in-process #3699 hint already wakes the reconnect supervisor).
 */
object FlutterEngineLiveness {
    @Volatile
    var alive = false
}
