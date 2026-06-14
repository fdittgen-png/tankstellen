// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.autorecord

import android.annotation.SuppressLint
import android.app.Activity
import android.companion.AssociationInfo
import android.companion.AssociationRequest
import android.companion.BluetoothDeviceFilter
import android.companion.CompanionDeviceManager
import android.content.Context
import android.content.IntentSender
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * #3320 (Epic #3314) — Companion-Device-Manager association with the OBD2
 * dongle, bridged to the Dart `CompanionDeviceAssociation` facade over the
 * `tankstellen/auto_record/cdm` MethodChannel.
 *
 * The CDM association is the documented way to start the connectedDevice
 * [AutoRecordForegroundService] from the background (via
 * [CompanionPresenceService]) when the paired dongle appears, WITHOUT
 * `ACCESS_BACKGROUND_LOCATION`.
 *
 * Activity-coupled: [associate] launches the system association dialog via an
 * [IntentSender], which needs an [Activity]; the channel is therefore
 * registered from `MainActivity` (not a context-only object like
 * [BackgroundAdapterChannel]). Methods:
 *   - `isSupported()`  -> Bool   API 34+ AND the CDM system feature present
 *   - `isAssociated()` -> Bool   we already hold an association
 *   - `associate(mac)` -> Bool   true once the system dialog is confirmed
 *   - `disassociate()` -> Bool   drop all of our associations
 *
 * Gated on API 34+ (the stable `myAssociations` + associate-callback +
 * [AssociationInfo] APIs; the version churn below 34 isn't worth carrying for
 * a dark feature). Each CDM-touching method opens with an `SDK_INT` guard so
 * the Android `NewApi` lint is satisfied without scattering `@RequiresApi`.
 *
 * UNVALIDATED ON-DEVICE: ships behind the dark FGS gate, not yet exercised
 * against a real dongle (needs the #3173 form + hardware). CI's Android build
 * verifies it compiles.
 */
class CompanionDeviceAssociator(private val activity: Activity) {

    fun registerWith(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isSupported())
            "isAssociated" -> result.success(isAssociated())
            "disassociate" -> result.success(disassociate())
            "associate" -> {
                val mac = call.argument<String>("mac")
                if (mac.isNullOrBlank()) {
                    result.error("arg", "mac missing", null)
                } else {
                    associate(mac, result)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun isSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
        return activity.packageManager
            .hasSystemFeature(PackageManager.FEATURE_COMPANION_DEVICE_SETUP)
    }

    private fun cdm(): CompanionDeviceManager? {
        if (!isSupported()) return null
        return activity.getSystemService(Context.COMPANION_DEVICE_SERVICE)
            as? CompanionDeviceManager
    }

    @SuppressLint("MissingPermission")
    private fun isAssociated(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
        val manager = cdm() ?: return false
        return try {
            manager.myAssociations.isNotEmpty()
        } catch (e: Exception) {
            Log.w(TAG, "isAssociated: query failed", e)
            false
        }
    }

    private fun disassociate(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
        val manager = cdm() ?: return false
        return try {
            for (info in manager.myAssociations) {
                manager.disassociate(info.id)
            }
            true
        } catch (e: Exception) {
            Log.w(TAG, "disassociate failed", e)
            false
        }
    }

    private fun associate(mac: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            result.success(false)
            return
        }
        val manager = cdm()
        if (manager == null) {
            result.success(false)
            return
        }
        val request = AssociationRequest.Builder()
            .addDeviceFilter(
                BluetoothDeviceFilter.Builder().setAddress(mac.uppercase()).build(),
            )
            // The exact dongle MAC is known, so auto-associate the single
            // match rather than showing a chooser list.
            .setSingleDevice(true)
            .build()

        var settled = false
        fun settle(value: Boolean) {
            if (!settled) {
                settled = true
                result.success(value)
            }
        }

        manager.associate(
            request,
            ContextCompat.getMainExecutor(activity),
            object : CompanionDeviceManager.Callback() {
                override fun onAssociationPending(intentSender: IntentSender) {
                    try {
                        activity.startIntentSender(intentSender, null, 0, 0, 0)
                    } catch (e: IntentSender.SendIntentException) {
                        Log.w(TAG, "associate: startIntentSender failed", e)
                        settle(false)
                    }
                }

                override fun onAssociationCreated(associationInfo: AssociationInfo) {
                    startObserving(manager, associationInfo)
                    settle(true)
                }

                override fun onFailure(error: CharSequence?) {
                    Log.w(TAG, "associate failed: $error")
                    settle(false)
                }
            },
        )
    }

    @SuppressLint("MissingPermission")
    private fun startObserving(
        manager: CompanionDeviceManager,
        info: AssociationInfo,
    ) {
        val mac = info.deviceMacAddress?.toString() ?: return
        try {
            // The String overload is deprecated in API 35 but is the broadest
            // compatible call; the request-object overload is 35+.
            @Suppress("DEPRECATION")
            manager.startObservingDevicePresence(mac)
        } catch (e: Exception) {
            Log.w(TAG, "startObservingDevicePresence failed", e)
        }
    }

    companion object {
        private const val TAG = "CompanionAssociator"
        private const val METHOD_CHANNEL = "tankstellen/auto_record/cdm"
    }
}
