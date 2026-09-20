// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.autorecord

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.annotation.RequiresApi
import de.tankstellen.tankstellen.R

/**
 * Long-running foreground service that drives hands-free trip
 * auto-record (#1004 phase 2b-1).
 *
 * Why a foreground service?
 *  - Android Doze + App Standby will kill ordinary background services
 *    and suspend BLE callbacks while the app is not visible. The user's
 *    car drives by in the morning, the phone is in the kitchen, the
 *    app's process is dead — a non-foreground service simply will not
 *    run. A foreground service with a `connectedDevice` type and a
 *    persistent (low-importance) notification is the OS-supported way
 *    to keep a BLE listener alive.
 *
 * Why stock [BluetoothGatt] instead of flutter_blue_plus?
 *  - flutter_blue_plus owns its own state machine that lives inside the
 *    Flutter activity. Sharing one instance across an activity-less
 *    Android service is fragile (the plugin's binding spans
 *    `FlutterEngine` + `FlutterPluginBinding.getApplicationContext`).
 *    The service's only job is observing connect/disconnect; for that
 *    a 60-line stock GATT client with `autoConnect=true` is the simpler
 *    and OS-blessed shape. Once the user opens the app, the existing
 *    [FlutterBluePlusElmChannel] takes over for the actual ELM327
 *    session.
 *
 * #4355 — this class is now only the **platform adapter**. Every lifecycle
 * decision (promotion gating, null-intent reconstruction, generation fencing,
 * idempotency) lives in [AutoRecordArming], which is a pure-JVM object and is
 * therefore covered by executable unit tests rather than by a source scan.
 *
 * This service watches for an adapter's *presence*. It is explicitly **not**
 * evidence that a recording is protected — #4352 owns that acknowledgement.
 */
class AutoRecordForegroundService : Service() {
    companion object {
        /** #3505 — SharedPreferences file + keys carrying the LOCALIZED
         *  notification copy Dart persists at arm time. */
        const val NOTIF_PREFS = "autorecord_notification"
        const val NOTIF_KEY_TITLE = "title"
        const val NOTIF_KEY_TEXT = "text"

        /** #4355 — sibling SharedPreferences file holding the DESIRED arming.
         *  An OS sticky restart always delivers a null intent, so the extras
         *  are gone; this is what the watcher reconstructs from instead. */
        const val ARM_PREFS = "autorecord_arm"
        const val ARM_KEY_MAC = "mac"
        const val ARM_KEY_GENERATION = "generation"
        const val ARM_KEY_ARMED = "armed"

        private const val TAG = "AutoRecordFgService"
        const val EXTRA_MAC = "mac"

        private const val CHANNEL_ID = "auto_record"
        private const val CHANNEL_NAME = "Trip auto-record"
        private const val NOTIFICATION_ID = 4221
    }

    /**
     * The lifecycle brain. Constructed lazily so `applicationContext` is
     * available (it is, from `onCreate` onwards — `onStartCommand` always
     * follows `onCreate`).
     */
    private val arming: AutoRecordArming by lazy {
        AutoRecordArming(
            promoter = ForegroundPromoter { startForegroundSafe() },
            armer = GattArmer(::openGatt),
            store = SharedPrefsDesiredArmStateStore(applicationContext),
            host = object : ArmingHost {
                override fun postTransition(event: Map<String, Any>) =
                    BackgroundAdapterChannel.post(event)

                override fun postPromoted(generation: Int) =
                    BackgroundAdapterChannel.postPromoted(generation)

                override fun postStartFailure(reason: String) =
                    BackgroundAdapterChannel.postStartFailure(reason)

                override fun stopSelf() = stopSelfSafe()
            },
        )
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // #4355 — a null intent is the NORMAL sticky-restart delivery, not an
        // error: the OS does not redeliver extras. Handing the seam a null MAC
        // routes it to the persisted desired state.
        return when (arming.onStartCommand(intent?.getStringExtra(EXTRA_MAC))) {
            StartDisposition.STICKY -> START_STICKY
            StartDisposition.NOT_STICKY -> START_NOT_STICKY
        }
    }

    override fun onDestroy() {
        arming.onDestroy()
        BackgroundAdapterChannel.markStopped()
        super.onDestroy()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) == null) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Watches your paired OBD2 adapter to start trips automatically."
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        // #3505 — localized copy persisted by BackgroundAdapterChannel at arm
        // time (HARD RULE #1: no hard-coded user-facing text); the English
        // literals below are only the never-armed / fresh-install fallback.
        val prefs = getSharedPreferences(NOTIF_PREFS, MODE_PRIVATE)
        val title = prefs.getString(NOTIF_KEY_TITLE, null) ?: "Trip auto-record"
        val text = prefs.getString(NOTIF_KEY_TEXT, null)
            ?: "Watching for your OBD2 adapter"
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .setPriority(Notification.PRIORITY_LOW)
                .build()
        }
    }

    /**
     * #4355 defect 1 — promotion now REPORTS. It used to return `Unit` and
     * swallow both catches, so the caller walked straight on into `armGatt`
     * and opened a BLE connection from a service the OS had refused to
     * promote: a ghost service Android kills silently mid-trip.
     *
     * The typed [PromotionOutcome] strictly subsumes the boolean the issue
     * asks for — a bare `false` cannot carry the accurate reason that has to
     * reach the Dart boundary.
     */
    private fun startForegroundSafe(): PromotionOutcome {
        val notification = buildNotification()
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ accepts the foregroundServiceType variant
                // — required on Android 14+ so the OS knows we are the
                // connectedDevice flavour and can size the timeout
                // window accordingly.
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            PromotionOutcome.Promoted
        } catch (e: SecurityException) {
            Log.w(TAG, "startForeground: SecurityException", e)
            PromotionOutcome.Refused(PromotionFailureReason.PERMISSION_DENIED)
        } catch (e: IllegalStateException) {
            val reason = classifyPromotionFailure(Build.VERSION.SDK_INT, e)
            Log.w(TAG, "startForeground: refused (${reason.wireName})", e)
            PromotionOutcome.Refused(reason)
        }
    }

    /**
     * Opens the stock GATT client for [mac], or returns null when the platform
     * refuses (no adapter, `BLUETOOTH_CONNECT` not granted, unusable MAC).
     * Stopping the service on a refusal is [AutoRecordArming]'s call, not ours.
     */
    @SuppressLint("MissingPermission")
    private fun openGatt(
        mac: String,
        generation: Int,
        onTransition: (type: String, atMillis: Long) -> Unit,
    ): GattHandle? {
        val manager = getSystemService(BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter: BluetoothAdapter? = manager?.adapter
        if (adapter == null) {
            Log.w(TAG, "openGatt: no BluetoothAdapter")
            return null
        }
        if (!hasBluetoothConnectPermission()) {
            Log.w(TAG, "openGatt: BLUETOOTH_CONNECT not granted")
            return null
        }

        val device = try {
            // getRemoteDevice insists on upper-case hex; the seam's pattern
            // accepts either, so canonicalise here and keep the caller's
            // spelling for the events the Dart coordinator filters on.
            adapter.getRemoteDevice(mac.uppercase())
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "openGatt: invalid MAC", e)
            return null
        }

        val callback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
                val type = when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> "connect"
                    BluetoothProfile.STATE_DISCONNECTED -> "disconnect"
                    else -> null
                } ?: return
                // #4355 — the callback reports the generation it was opened
                // for; the seam drops it once that generation is retired.
                onTransition(type, System.currentTimeMillis())
            }
        }

        val gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            device.connectGatt(this, /* autoConnect = */ true, callback, BluetoothDevice.TRANSPORT_LE)
        } else {
            @Suppress("DEPRECATION")
            device.connectGatt(this, true, callback)
        }
        if (gatt == null) {
            Log.w(TAG, "openGatt: connectGatt returned null (generation $generation)")
            return null
        }
        return GattHandle { closeGatt(gatt) }
    }

    private fun hasBluetoothConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED
    }

    @SuppressLint("MissingPermission")
    private fun closeGatt(g: BluetoothGatt) {
        try {
            g.disconnect()
        } catch (e: SecurityException) {
            Log.w(TAG, "closeGatt: SecurityException on disconnect", e)
        }
        try {
            g.close()
        } catch (e: SecurityException) {
            Log.w(TAG, "closeGatt: SecurityException on close", e)
        }
    }

    private fun stopSelfSafe() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (e: IllegalStateException) {
            Log.w(TAG, "stopSelfSafe: stopForeground failed", e)
        }
        stopSelf()
        BackgroundAdapterChannel.markStopped()
    }
}

/**
 * #4355 — names the promotion refusal accurately.
 *
 * `ForegroundServiceStartNotAllowedException` — the Android 12+ background
 * -start refusal, which is what actually happens in the field — is an
 * `IllegalStateException` subclass, so the old code caught it only
 * incidentally and reported a generic label. It is matched **by name** here;
 * the match lives in its own API-gated function so the `instanceof` never has
 * to verify against a class that does not exist on an older runtime.
 *
 * Package-internal (not private) so it is directly executable from a unit
 * test without constructing a real `Service`.
 */
internal fun classifyPromotionFailure(
    sdkInt: Int,
    e: IllegalStateException,
): PromotionFailureReason {
    if (sdkInt < Build.VERSION_CODES.S) return PromotionFailureReason.ILLEGAL_STATE
    return classifyPromotionFailureApi31(e)
}

@RequiresApi(Build.VERSION_CODES.S)
private fun classifyPromotionFailureApi31(e: IllegalStateException): PromotionFailureReason =
    if (e is android.app.ForegroundServiceStartNotAllowedException) {
        PromotionFailureReason.NOT_ALLOWED_IN_BACKGROUND
    } else {
        PromotionFailureReason.ILLEGAL_STATE
    }

/**
 * #4355 — [DesiredArmStateStore] backed by the `autorecord_arm`
 * SharedPreferences file, a sibling of [AutoRecordForegroundService.NOTIF_PREFS].
 *
 * It holds the paired adapter MAC the app already stores, the monotonic arm
 * generation, and the armed flag — no credentials, and nothing that is not
 * already persisted elsewhere for auto-record.
 */
class SharedPrefsDesiredArmStateStore(context: Context) : DesiredArmStateStore {
    private val prefs = context.applicationContext.getSharedPreferences(
        AutoRecordForegroundService.ARM_PREFS,
        Context.MODE_PRIVATE,
    )

    override fun read(): DesiredArmState? {
        val mac = prefs.getString(AutoRecordForegroundService.ARM_KEY_MAC, null)
            ?: return null
        return DesiredArmState(
            mac = mac,
            generation = prefs.getInt(AutoRecordForegroundService.ARM_KEY_GENERATION, 0),
            armed = prefs.getBoolean(AutoRecordForegroundService.ARM_KEY_ARMED, false),
        )
    }

    override fun arm(mac: String, generation: Int) {
        prefs.edit()
            .putString(AutoRecordForegroundService.ARM_KEY_MAC, mac)
            .putInt(AutoRecordForegroundService.ARM_KEY_GENERATION, generation)
            .putBoolean(AutoRecordForegroundService.ARM_KEY_ARMED, true)
            .apply()
    }

    override fun disarm() {
        // The generation is deliberately kept so it stays monotonic across an
        // explicit stop; only the desire is cleared.
        prefs.edit()
            .putBoolean(AutoRecordForegroundService.ARM_KEY_ARMED, false)
            .apply()
    }
}
