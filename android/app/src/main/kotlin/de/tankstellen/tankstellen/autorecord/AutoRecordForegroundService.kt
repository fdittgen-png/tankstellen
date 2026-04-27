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
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
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
 * Idempotency:
 *  - If the service is started for the same MAC it's already armed for,
 *    it's a no-op.
 *  - If started for a different MAC, the prior GATT is closed and we
 *    re-arm against the new MAC.
 */
class AutoRecordForegroundService : Service() {
    companion object {
        private const val TAG = "AutoRecordFgService"
        const val EXTRA_MAC = "mac"

        private const val CHANNEL_ID = "auto_record"
        private const val CHANNEL_NAME = "Trip auto-record"
        private const val NOTIFICATION_ID = 4221
    }

    private var gatt: BluetoothGatt? = null
    private var armedMac: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val mac = intent?.getStringExtra(EXTRA_MAC)
        if (mac.isNullOrBlank()) {
            Log.w(TAG, "onStartCommand: missing MAC extra; stopping")
            stopSelfSafe()
            return START_NOT_STICKY
        }

        startForegroundSafe()

        if (mac.equals(armedMac, ignoreCase = true) && gatt != null) {
            // Idempotent: same MAC already armed. Nothing to do.
            return START_STICKY
        }

        // Different MAC (or first arm). Close any prior GATT.
        closeGatt()
        armedMac = mac
        armGatt(mac)
        return START_STICKY
    }

    override fun onDestroy() {
        closeGatt()
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

    private fun startForegroundSafe() {
        val notification: Notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Trip auto-record")
                .setContentText("Watching for your OBD2 adapter")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Trip auto-record")
                .setContentText("Watching for your OBD2 adapter")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setOngoing(true)
                .setPriority(Notification.PRIORITY_LOW)
                .build()
        }

        try {
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
        } catch (e: SecurityException) {
            Log.w(TAG, "startForeground: SecurityException", e)
            stopSelfSafe()
        } catch (e: IllegalStateException) {
            Log.w(TAG, "startForeground: IllegalStateException (Android 12+ background?)", e)
            stopSelfSafe()
        }
    }

    @SuppressLint("MissingPermission")
    private fun armGatt(mac: String) {
        val manager = getSystemService(BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter: BluetoothAdapter? = manager?.adapter
        if (adapter == null) {
            Log.w(TAG, "armGatt: no BluetoothAdapter; stopping")
            stopSelfSafe()
            return
        }
        if (!hasBluetoothConnectPermission()) {
            Log.w(TAG, "armGatt: BLUETOOTH_CONNECT not granted; stopping")
            stopSelfSafe()
            return
        }

        val device = try {
            adapter.getRemoteDevice(mac)
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "armGatt: invalid MAC '$mac'", e)
            stopSelfSafe()
            return
        }

        val callback = object : BluetoothGattCallback() {
            override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
                val type = when (newState) {
                    BluetoothProfile.STATE_CONNECTED -> "connect"
                    BluetoothProfile.STATE_DISCONNECTED -> "disconnect"
                    else -> null
                }
                if (type != null) {
                    BackgroundAdapterChannel.post(
                        mapOf<String, Any>(
                            "type" to type,
                            "mac" to mac,
                            "atMillis" to System.currentTimeMillis(),
                        ),
                    )
                }
            }
        }

        gatt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            device.connectGatt(this, /* autoConnect = */ true, callback, BluetoothDevice.TRANSPORT_LE)
        } else {
            @Suppress("DEPRECATION")
            device.connectGatt(this, true, callback)
        }
    }

    private fun hasBluetoothConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return checkSelfPermission(android.Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED
    }

    @SuppressLint("MissingPermission")
    private fun closeGatt() {
        val g = gatt ?: return
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
        gatt = null
        armedMac = null
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
