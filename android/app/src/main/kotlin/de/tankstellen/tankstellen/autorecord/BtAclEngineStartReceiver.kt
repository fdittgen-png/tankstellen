// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.autorecord

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.SystemClock
import android.util.Log

/**
 * #3699 — engine-start hint from Bluetooth ACL connections.
 *
 * The vLinker-class OBD2 adapter sleeps at ~3 mA while the ignition is
 * off (its Bluetooth presence lingers, but RFCOMM connects time out) and
 * wakes on bus activity the instant the ignition turns on. The reconnect
 * supervisor's stand-down holds are therefore CORRECT while parked but
 * blind at engine start: with the phone pocketed, nothing used to break
 * the hold until the app came to the foreground (2026-08-11 field log —
 * hourly 23 s misses escalating the hold past an hour, morning drives
 * connecting only after the app was opened).
 *
 * The one broadcast that fires at exactly the right moment is
 * [BluetoothDevice.ACTION_ACL_CONNECTED]: when driving starts, the phone
 * links to the car's audio system (and/or the adapter itself). We
 * forward it as an `aclConnected` event on the existing auto_record
 * events channel; the Dart side calls `Obd2LinkSupervisor.wake()`, which
 * resets the stand-down and dials immediately (a no-op in every state
 * where waking is meaningless).
 *
 * Deliberately UNFILTERED by device: the car-audio MAC is unknown to the
 * app, and a false hint (headphones at home) costs at most one fast
 * dial ladder before the stand-down re-arms. A [COOLDOWN_MS] gate keeps
 * accessory churn from re-triggering that repeatedly.
 *
 * Context-registered on the application context (process lifetime — no
 * manifest registration, so a dead process is never revived into a
 * fresh FlutterEngine; see the #3688 engine-churn lesson).
 */
object BtAclEngineStartReceiver {
    private const val TAG = "BtAclEngineStart"
    private const val COOLDOWN_MS = 5L * 60L * 1000L

    @Volatile
    private var registered = false

    @Volatile
    private var lastHintElapsedMs = -COOLDOWN_MS

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != BluetoothDevice.ACTION_ACL_CONNECTED) return
            val nowElapsed = SystemClock.elapsedRealtime()
            if (nowElapsed - lastHintElapsedMs < COOLDOWN_MS) return
            lastHintElapsedMs = nowElapsed
            val device: BluetoothDevice? =
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(
                        BluetoothDevice.EXTRA_DEVICE,
                        BluetoothDevice::class.java,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                }
            val mac = device?.address ?: ""
            Log.d(TAG, "ACL connected ($mac) — forwarding engine-start hint")
            BackgroundAdapterChannel.post(
                mapOf(
                    "type" to "aclConnected",
                    "mac" to mac,
                    "atMillis" to System.currentTimeMillis(),
                ),
            )
        }
    }

    /** Idempotent; safe to call on every engine configure. */
    fun register(context: Context) {
        if (registered) return
        synchronized(this) {
            if (registered) return
            context.applicationContext.registerReceiver(
                receiver,
                IntentFilter(BluetoothDevice.ACTION_ACL_CONNECTED),
            )
            registered = true
            Log.d(TAG, "registered for ACTION_ACL_CONNECTED")
        }
    }
}
