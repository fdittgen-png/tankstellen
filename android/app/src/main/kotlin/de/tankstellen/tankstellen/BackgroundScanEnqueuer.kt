// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.Context
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
 * Enqueues a one-off WorkManager task that the Dart `callbackDispatcher`
 * handles. Shared by the native triggers that feed the on-device background
 * scan: the home-widget refresh (#2412) and the boot re-arm (#2413).
 *
 * Each enqueue routes through the workmanager plugin's [BackgroundWorker],
 * which resolves the Dart callback handle persisted by `Workmanager()
 * .initialize`. We only enqueue when that handle exists — i.e. the app
 * previously registered background work because the user had an active
 * alert. Without it, there is nothing to scan and polling would be
 * unconsented.
 *
 * The cross-trigger cooldown in `BackgroundAlertScanCoordinator` (#2415)
 * dedups these one-offs against the WorkManager periodic tasks, so an
 * opportunistic widget wake seconds after a periodic scan is a cheap no-op.
 */
object BackgroundScanEnqueuer {
    private const val TAG = "BackgroundScanEnqueuer"

    /**
     * Enqueue [dartTask] as a unique CONNECTED-network one-off. [uniqueName]
     * keeps the OS from stacking duplicates when the trigger fires rapidly
     * (e.g. several widgets refreshing at once) — REPLACE collapses them
     * into one pending task, and the coordinator's cooldown handles the rest.
     */
    fun enqueue(context: Context, dartTask: String, uniqueName: String) {
        if (SharedPreferenceHelper.getCallbackHandle(context) == -1L) {
            Log.d(TAG, "$dartTask: no persisted WorkManager callback — skipping")
            return
        }

        val input = Data.Builder()
            .putString(BackgroundWorker.DART_TASK_KEY, dartTask)
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
            uniqueName,
            ExistingWorkPolicy.REPLACE,
            request,
        )
        Log.d(TAG, "enqueued one-off scan task: $dartTask")
    }
}
