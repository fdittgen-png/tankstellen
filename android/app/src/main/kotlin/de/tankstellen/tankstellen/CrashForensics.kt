// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * #3580 — local-only crash forensics for the deaths the Dart handlers can
 * never see: native/Kotlin plugin crashes, ANRs and OOM kills (the class
 * of crash the field reports as "recording crashed, no traces").
 *
 * Two capture paths, both harvested by the Dart side on next launch and
 * folded into the EXISTING on-device error log (never uploaded — the
 * consent model is unchanged):
 *
 *  * [installUncaughtHandler] — a last-resort default
 *    [Thread.UncaughtExceptionHandler] that appends the full JVM stack to
 *    a crash-journal file before the process dies, then chains to the
 *    previous handler (so the system dialog / any enabled reporter still
 *    run). This yields FULL stacks for Java/Kotlin crashes, which
 *    [ApplicationExitInfo] only summarises.
 *  * [harvest] — reads [ActivityManager.getHistoricalProcessExitReasons]
 *    (API 30+) for every abnormal exit since the last harvest: reason,
 *    process importance (foreground vs background), timestamp, memory
 *    stats, plus the OS trace stream where the platform provides one
 *    (ANR / native crash). Catches OOM and system kills that no
 *    in-process handler can observe.
 */
object CrashForensics {
    private const val JOURNAL_DIR = "crash_journal"
    private const val PENDING_FILE = "pending_crashes.jsonl"
    private const val PREFS = "crash_forensics"
    private const val KEY_LAST_HARVEST = "last_harvest_ms"

    /** Cap for the pending-crash journal — a crash loop must never eat the disk. */
    private const val MAX_JOURNAL_BYTES = 256L * 1024L

    /** Cap for an OS-provided ANR/native trace stream per exit record. */
    private const val MAX_TRACE_BYTES = 64 * 1024

    private fun journalFile(context: Context): File =
        File(File(context.filesDir, JOURNAL_DIR).apply { mkdirs() }, PENDING_FILE)

    /** Install the last-resort handler. Idempotent per process. */
    fun installUncaughtHandler(context: Context) {
        val appContext = context.applicationContext
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        if (previous is JournalingHandler) return
        Thread.setDefaultUncaughtExceptionHandler(
            JournalingHandler(appContext, previous),
        )
    }

    private class JournalingHandler(
        private val context: Context,
        private val previous: Thread.UncaughtExceptionHandler?,
    ) : Thread.UncaughtExceptionHandler {
        override fun uncaughtException(thread: Thread, error: Throwable) {
            try {
                val file = journalFile(context)
                if (file.length() < MAX_JOURNAL_BYTES) {
                    val record = JSONObject()
                        .put("timestampMs", System.currentTimeMillis())
                        .put("thread", thread.name)
                        .put("error", error.toString())
                        .put("stack", android.util.Log.getStackTraceString(error))
                    file.appendText(record.toString() + "\n")
                }
            } catch (_: Throwable) {
                // Never let forensics turn a crash into a different crash.
            } finally {
                previous?.uncaughtException(thread, error)
            }
        }
    }

    /**
     * Collect and CLEAR everything captured since the last harvest.
     * Returns a JSON string: {"uncaught": [...], "exits": [...]} — a
     * string (not a platform map) so the channel payload stays trivially
     * serialisable and size-capped.
     */
    fun harvest(context: Context): String {
        val result = JSONObject()
        result.put("uncaught", drainJournal(context))
        result.put("exits", drainExitReasons(context))
        return result.toString()
    }

    private fun drainJournal(context: Context): JSONArray {
        val out = JSONArray()
        val file = journalFile(context)
        try {
            if (file.exists()) {
                file.readLines().forEach { line ->
                    if (line.isNotBlank()) {
                        try {
                            out.put(JSONObject(line))
                        } catch (_: Throwable) {
                            // A torn write from a mid-crash append — skip the line.
                        }
                    }
                }
                file.delete()
            }
        } catch (_: Throwable) {
            // Unreadable journal must not break startup.
        }
        return out
    }

    private fun drainExitReasons(context: Context): JSONArray {
        val out = JSONArray()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return out
        try {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val lastHarvest = prefs.getLong(KEY_LAST_HARVEST, 0L)
            var newest = lastHarvest
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            for (info in am.getHistoricalProcessExitReasons(context.packageName, 0, 16)) {
                if (info.timestamp <= lastHarvest) continue
                if (info.timestamp > newest) newest = info.timestamp
                // EXIT_SELF / user-initiated stops are normal lifecycle —
                // only abnormal deaths become error traces.
                if (info.reason == ApplicationExitInfo.REASON_EXIT_SELF ||
                    info.reason == ApplicationExitInfo.REASON_USER_REQUESTED ||
                    info.reason == ApplicationExitInfo.REASON_USER_STOPPED ||
                    info.reason == ApplicationExitInfo.REASON_PERMISSION_CHANGE
                ) {
                    continue
                }
                out.put(
                    JSONObject()
                        .put("timestampMs", info.timestamp)
                        .put("reason", reasonName(info.reason))
                        .put("importance", importanceName(info.importance))
                        .put("description", info.description ?: "")
                        .put("pssKb", info.pss)
                        .put("rssKb", info.rss)
                        .put("trace", readTrace(info)),
                )
            }
            prefs.edit().putLong(KEY_LAST_HARVEST, newest).apply()
        } catch (_: Throwable) {
            // Forensics are best-effort — never break startup.
        }
        return out
    }

    private fun readTrace(info: ApplicationExitInfo): String {
        return try {
            info.traceInputStream?.use { stream ->
                String(stream.readBytes().take(MAX_TRACE_BYTES).toByteArray())
            } ?: ""
        } catch (_: Throwable) {
            ""
        }
    }

    private fun reasonName(reason: Int): String = when (reason) {
        ApplicationExitInfo.REASON_ANR -> "anr"
        ApplicationExitInfo.REASON_CRASH -> "crash"
        ApplicationExitInfo.REASON_CRASH_NATIVE -> "crash_native"
        ApplicationExitInfo.REASON_DEPENDENCY_DIED -> "dependency_died"
        ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE -> "excessive_resource_usage"
        ApplicationExitInfo.REASON_EXIT_SELF -> "exit_self"
        ApplicationExitInfo.REASON_FREEZER -> "freezer"
        ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "initialization_failure"
        ApplicationExitInfo.REASON_LOW_MEMORY -> "low_memory_kill"
        ApplicationExitInfo.REASON_OTHER -> "other"
        ApplicationExitInfo.REASON_SIGNALED -> "signaled"
        else -> "unknown_$reason"
    }

    private fun importanceName(importance: Int): String = when {
        importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND_SERVICE ->
            "foreground"
        importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE -> "visible"
        else -> "background"
    }
}
