// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import dev.fluttercommunity.workmanager.SharedPreferenceHelper

/**
 * Re-arms the on-device background price scan after a device reboot (#2413).
 *
 * ## Why this exists
 * WorkManager persists periodic work and androidx already reschedules it on
 * boot — but only when the WorkManager DB survived and the boot-reschedule
 * receiver fired. To make the Tier-1 scan robust against the edge cases where
 * that does not happen (DB cleared, OEM aggressive task killers), this
 * receiver enqueues a one-off WorkManager task on `BOOT_COMPLETED` whose Dart
 * handler ([BackgroundService.callbackDispatcher] → `bootReregister`)
 * re-registers the periodic tasks from scratch.
 *
 * ## How it stays cheap
 * - It only acts when the WorkManager callback handle is already persisted —
 *   i.e. the user previously had an active alert and the app registered
 *   background work. A fresh install with no alerts re-arms nothing.
 * - The one-off task carries a `connected` network constraint, so it waits
 *   for connectivity rather than firing a dead request right at boot.
 *
 * Background scanning remains **best-effort, never real-time** — this only
 * guarantees the periodic schedule is re-established, not that any individual
 * wake is punctual.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        // Only re-arm if WorkManager was previously initialized from Dart
        // (callback handle persisted). Otherwise there is no schedule to
        // restore and re-arming would poll without user consent.
        val callbackHandle = SharedPreferenceHelper.getCallbackHandle(context)
        if (callbackHandle == -1L) {
            Log.d(TAG, "boot: no persisted WorkManager callback — nothing to re-arm")
            return
        }

        val input = Data.Builder()
            .putString(BackgroundWorker.DART_TASK_KEY, BOOT_REREGISTER_TASK)
            .build()

        val request = OneTimeWorkRequest.Builder(BackgroundWorker::class.java)
            .setInputData(input)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            .build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            BOOT_REREGISTER_UNIQUE_NAME,
            ExistingWorkPolicy.REPLACE,
            request,
        )
        Log.d(TAG, "boot: enqueued background-scan re-registration")
    }

    companion object {
        private const val TAG = "BootReceiver"

        /**
         * Dart task name handled by `callbackDispatcher` to re-register the
         * periodic tasks. Must match `BackgroundService.bootReregisterTask`.
         */
        const val BOOT_REREGISTER_TASK = "bootReregister"

        private const val BOOT_REREGISTER_UNIQUE_NAME = "bootReregister"
    }
}
