// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.Context
import android.util.Log
import androidx.core.content.pm.PackageInfoCompat
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
 * ## Handle-freshness gate (#3688)
 *
 * The persisted callback handle encodes an offset into the Dart snapshot of
 * the build that persisted it. After an app UPDATE it is stale until the
 * next foreground launch re-persists it — and a stale handle makes
 * [BackgroundWorker] fail `FlutterCallbackInformation.lookupCallbackInformation`
 * AFTER creating its FlutterEngine, which that failure path never destroys.
 * Field tombstones showed 43 live leaked engines (each with a bound
 * TextToSpeech) killing the process with a JNI global-reference-table
 * overflow. The Dart side stamps the build number that persisted the handle
 * (`flutter.bg_handle_build`); we refuse to enqueue when it does not match
 * the installed build. Fail-safe direction: a missing/mismatched stamp only
 * skips an opportunistic scan until the user next opens the app.
 *
 * A 60-min cooldown additionally caps the periodic widget wake (#3688):
 * even a healthy engine run leaves a small permanent JNI residue, so the
 * 30-min `updatePeriodMillis` churn is halved. User-initiated refreshes
 * bypass the cooldown but never the freshness gate.
 *
 * The cross-trigger cooldown in `BackgroundAlertScanCoordinator` (#2415)
 * dedups these one-offs against the WorkManager periodic tasks, so an
 * opportunistic widget wake seconds after a periodic scan is a cheap no-op.
 */
object BackgroundScanEnqueuer {
    private const val TAG = "BackgroundScanEnqueuer"

    /** Written by the Dart shared_preferences plugin (flutter.-prefixed). */
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"

    /** Build number stamped right after `Workmanager().initialize` (#3688). */
    const val HANDLE_BUILD_KEY = "flutter.bg_handle_build"

    private const val GATE_PREFS = "bg_scan_gate"
    private const val LAST_ENQUEUE_KEY = "last_enqueue_ms"
    private const val COOLDOWN_MS = 60L * 60L * 1000L

    /**
     * Enqueue [dartTask] as a unique CONNECTED-network one-off. [uniqueName]
     * keeps the OS from stacking duplicates when the trigger fires rapidly
     * (e.g. several widgets refreshing at once) — REPLACE collapses them
     * into one pending task, and the coordinator's cooldown handles the rest.
     *
     * Returns whether the task was actually enqueued, so callers with
     * visible feedback (the widget refresh glyph) only show progress for a
     * scan that will really run. [respectCooldown] is set by the periodic
     * widget wake; user-initiated triggers pass false.
     */
    fun enqueue(
        context: Context,
        dartTask: String,
        uniqueName: String,
        respectCooldown: Boolean = false,
    ): Boolean {
        if (SharedPreferenceHelper.getCallbackHandle(context) == -1L) {
            Log.d(TAG, "$dartTask: no persisted WorkManager callback — skipping")
            return false
        }

        if (!handleIsFresh(context)) {
            Log.d(
                TAG,
                "$dartTask: callback handle predates this build — skipping " +
                    "until the next app launch re-persists it (#3688)",
            )
            return false
        }

        val gate = context.getSharedPreferences(GATE_PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        if (respectCooldown) {
            val last = gate.getLong(LAST_ENQUEUE_KEY, 0L)
            if (now - last < COOLDOWN_MS) {
                Log.d(TAG, "$dartTask: within scan cooldown — skipping")
                return false
            }
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
        gate.edit().putLong(LAST_ENQUEUE_KEY, now).apply()
        Log.d(TAG, "enqueued one-off scan task: $dartTask")
        return true
    }

    /**
     * True when the Dart-side stamp says the persisted callback handle was
     * written by the currently installed build. Absent stamp = stale (the
     * update that ships the stamp, or any update before the first launch).
     */
    private fun handleIsFresh(context: Context): Boolean {
        val stamped = context
            .getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .getString(HANDLE_BUILD_KEY, null)
            ?: return false
        val installed = PackageInfoCompat.getLongVersionCode(
            context.packageManager.getPackageInfo(context.packageName, 0),
        ).toString()
        return stamped == installed
    }
}
