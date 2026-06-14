// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.autorecord

import android.companion.AssociationInfo
import android.companion.CompanionDeviceService
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi

/**
 * #3320 (Epic #3314) — the system binds this [CompanionDeviceService] on
 * Companion-Device-Manager presence transitions for an associated OBD2
 * dongle.
 *
 * [onDeviceAppeared] starts the `connectedDevice`
 * [AutoRecordForegroundService] from the background — the CDM exemption to
 * the Android 12+ background-foreground-service-start restriction — so a
 * hands-free trip can begin the moment the car's dongle powers up, WITHOUT
 * `ACCESS_BACKGROUND_LOCATION` (that gate, #1498, only blocks the GPS half).
 *
 * Inert in default builds: the service is declared only in the FGS-approved
 * play overlay, and association is only ever requested behind the Dart
 * `kGpsRecordingForegroundServiceEnabled` gate. Requires API 33+ (the
 * [AssociationInfo] presence callbacks); the manifest declaration is gated by
 * the merge, and the class is annotated accordingly.
 *
 * UNVALIDATED ON-DEVICE: this ships behind the dark FGS gate and has not been
 * exercised against a real dongle yet (needs the #3173 form + hardware). CI's
 * Android build verifies it compiles.
 */
@RequiresApi(Build.VERSION_CODES.TIRAMISU)
class CompanionPresenceService : CompanionDeviceService() {
    override fun onDeviceAppeared(associationInfo: AssociationInfo) {
        val mac = associationInfo.deviceMacAddress?.toString()
        if (mac.isNullOrBlank()) {
            Log.w(TAG, "onDeviceAppeared: association has no MAC; cannot arm")
            return
        }
        try {
            val intent = Intent(this, AutoRecordForegroundService::class.java)
                .apply {
                    putExtra(AutoRecordForegroundService.EXTRA_MAC, mac.uppercase())
                }
            startForegroundService(intent)
        } catch (e: Exception) {
            // Best-effort: a failed background start (OEM policy, race) must
            // never crash the bound service. The next presence event retries.
            Log.w(TAG, "onDeviceAppeared: could not start auto-record FGS", e)
        }
    }

    override fun onDeviceDisappeared(associationInfo: AssociationInfo) {
        // No-op: the trip-recording teardown is already driven by the BLE GATT
        // disconnect that AutoRecordForegroundService observes. We don't stop
        // the FGS here — a brief out-of-range blip shouldn't kill a live trip.
    }

    companion object {
        private const val TAG = "CompanionPresence"
    }
}
