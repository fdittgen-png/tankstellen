// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.autorecord

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridge between [AutoRecordForegroundService] and the Dart-side
 * `AndroidBackgroundAdapterListener` (#1004 phase 2b-1).
 *
 * Two channels:
 *  - `tankstellen/auto_record/methods` (MethodChannel):
 *       start(mac: String) -> Bool   starts the foreground service AND waits
 *                                    for the service's promotion ack
 *       stop()             -> Bool   stops the foreground service
 *       isRunning()        -> Bool   true while the service is promoted
 *  - `tankstellen/auto_record/events` (EventChannel):
 *       Stream<Map>  events of the form
 *          {"type": "connect" | "disconnect", "mac": "<MAC>", "atMillis": <Long>}
 *          {"type": "fgsPromoted", "generation": <Int>, "atMillis": <Long>}
 *          {"type": "fgsStartFailed", "reason": "<wireName>", "atMillis": <Long>}
 *
 * Architecture notes:
 *  - The service emits events through this object via [post]; the
 *    object forwards them on the platform main thread to the
 *    [EventChannel.EventSink] when one is attached.
 *  - When no Dart subscriber is attached (the app process is dead and
 *    the service is firing alone) we buffer the most recent events in
 *    a small ring so the coordinator can replay state on resume. The
 *    ring size is intentionally tiny (16) — the coordinator only needs
 *    to know the current connected/disconnected state, not a full
 *    history.
 *  - We deliberately do NOT share the flutter_blue_plus stack with
 *    the foreground service. The service owns its own stock
 *    `BluetoothGatt` client whose only job is observing connection
 *    transitions; the active trip-recording session re-uses the
 *    existing `FlutterBluePlusElmChannel` once the Flutter activity
 *    is back in the foreground.
 *
 * #4355 — **a `ComponentName` is not a promotion.** `startForegroundService`
 * returning non-null proves only that the OS *created* the service; whether
 * Android accepted the subsequent `startForeground` call is decided later, on
 * a later main-thread turn, inside the service. Answering `success(true)` on
 * the ComponentName alone made Dart believe a foreground service was running
 * that the OS had already refused. The reply is therefore parked until the
 * service posts [postPromoted] or [postStartFailure], with a bounded timeout
 * so a wedged service degrades instead of hanging the caller.
 */
object BackgroundAdapterChannel {
    private const val TAG = "BackgroundAdapter"
    private const val METHOD_CHANNEL = "tankstellen/auto_record/methods"
    private const val EVENT_CHANNEL = "tankstellen/auto_record/events"

    /**
     * #4355 — how long a parked `start` reply waits for the service's
     * promotion acknowledgement. The service promotes synchronously inside
     * its own `onStartCommand`, i.e. on the very next main-thread turn, so
     * this is a generous outer bound on a wedged platform, not a cadence.
     */
    const val PROMOTION_ACK_TIMEOUT_MS = 5_000L

    /** Event type names shared with the Dart parser. Keep in sync. */
    const val EVENT_PROMOTED = "fgsPromoted"
    const val EVENT_START_FAILED = "fgsStartFailed"

    /** Channel error codes shared with the Dart parser. Keep in sync. */
    const val ERROR_PROMOTION_REFUSED = "promotionRefused"
    const val ERROR_PROMOTION_TIMEOUT = "promotionTimeout"
    const val ERROR_SUPERSEDED = "superseded"

    /** Cached app context for starting / stopping the service. Set in [registerWith]. */
    @Volatile
    private var appContext: Context? = null

    /** Live EventSink, or null when no Dart subscriber is attached. */
    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    /**
     * Last-N ring buffer of events seen while no subscriber was
     * attached. Replayed in order on [EventChannel.StreamHandler.onListen].
     */
    private val pending = ArrayDeque<Map<String, Any>>()
    private const val PENDING_CAPACITY = 16

    /**
     * Tracks whether the foreground service is currently PROMOTED — not
     * merely created. Flipped on by [postPromoted] only.
     */
    @Volatile
    private var running: Boolean = false

    private val mainHandler = Handler(Looper.getMainLooper())

    /** The `start` reply parked until the service acknowledges (#4355). */
    private var pendingStart: PendingStart? = null

    /** The timeout runnable armed alongside [pendingStart]. */
    private var pendingStartTimeout: Runnable? = null

    /**
     * A `start` reply that must be answered exactly once, from the main
     * thread, by whichever of {ack, failure, timeout, supersede} lands first.
     */
    private class PendingStart(private val result: MethodChannel.Result) {
        private var settled = false

        fun succeed(): Boolean {
            if (settled) return false
            settled = true
            result.success(true)
            return true
        }

        fun fail(code: String, message: String): Boolean {
            if (settled) return false
            settled = true
            result.error(code, message, null)
            return true
        }
    }

    fun registerWith(flutterEngine: FlutterEngine, context: Context) {
        appContext = context.applicationContext

        // #3699 — ACL engine-start hints ride this channel's event stream.
        BtAclEngineStartReceiver.register(context)

        val method = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        method.setMethodCallHandler { call, result -> handle(call, result) }

        val events = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
                drainPending()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        val ctx = appContext
        if (ctx == null) {
            result.error("state", "BackgroundAdapterChannel not initialised", null)
            return
        }
        when (call.method) {
            "start" -> handleStart(ctx, call, result)
            "stop" -> handleStop(ctx, result)
            "isRunning" -> result.success(running)
            else -> result.notImplemented()
        }
    }

    private fun handleStart(ctx: Context, call: MethodCall, result: MethodChannel.Result) {
        val mac = call.argument<String>("mac")
        if (mac.isNullOrBlank()) {
            result.error("arg", "mac missing", null)
            return
        }
        // #3505 — persist the LOCALIZED notification copy Dart hands
        // over, so even a CDM cold start (app process dead — no Dart
        // side to ask) shows the user's language. Absent args keep
        // whatever was stored (language unchanged since last arm).
        val title = call.argument<String>("notifTitle")
        val text = call.argument<String>("notifText")
        if (title != null || text != null) {
            ctx.getSharedPreferences(
                AutoRecordForegroundService.NOTIF_PREFS,
                Context.MODE_PRIVATE,
            ).edit().apply {
                if (title != null) putString(AutoRecordForegroundService.NOTIF_KEY_TITLE, title)
                if (text != null) putString(AutoRecordForegroundService.NOTIF_KEY_TEXT, text)
            }.apply()
        }
        val intent = Intent(ctx, AutoRecordForegroundService::class.java).apply {
            putExtra(AutoRecordForegroundService.EXTRA_MAC, mac)
        }
        val component = try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                ctx.startForegroundService(intent)
            } else {
                ctx.startService(intent)
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "start: missing FOREGROUND_SERVICE permission", e)
            result.error("permission", e.message ?: "permission denied", null)
            return
        } catch (e: IllegalStateException) {
            // App in background on Android 12+ — caller must arm the service
            // from a foreground context. #4355: report the SAME typed reason
            // the service's own promotion refusal uses, so Dart sees one
            // vocabulary whichever side of the start the OS refuses on.
            val reason = classifyPromotionFailure(android.os.Build.VERSION.SDK_INT, e)
            Log.w(TAG, "start: cannot start FGS (${reason.wireName})", e)
            result.error(ERROR_PROMOTION_REFUSED, reason.wireName, null)
            return
        }

        // #3246 — shipped builds gate the <service> OUT of the manifest
        // (FGS_FORM_APPROVED off, #3173). Starting an undeclared service
        // does NOT throw — it logs "Unable to start service … not found"
        // and resolves to a null ComponentName. Report the honest failure
        // instead of a phantom "armed", so Dart degrades to GPS-only rather
        // than believing a foreground service is running that isn't.
        if (component == null) {
            Log.w(
                TAG,
                "start: AutoRecordForegroundService is not registered " +
                    "(FGS gated out of the manifest) — not armed",
            )
            running = false
            result.error(
                "unavailable",
                "foreground service not registered",
                null,
            )
            return
        }

        // #4355 — the ComponentName proves CREATION, never PROMOTION. Park the
        // reply until the service acknowledges. Safe against a race: `handle`
        // runs on the platform main thread and so does the service's
        // `onStartCommand`, so the ack cannot land before we park.
        awaitPromotionAck(result)
    }

    private fun handleStop(ctx: Context, result: MethodChannel.Result) {
        // #4355 — clear the DESIRE before tearing the service down, so a
        // sticky restart cannot reconstruct a watcher the user just stopped.
        // Done here rather than in the service because the service process
        // may already be gone.
        SharedPrefsDesiredArmStateStore(ctx).disarm()
        val intent = Intent(ctx, AutoRecordForegroundService::class.java)
        try {
            ctx.stopService(intent)
        } catch (e: SecurityException) {
            Log.w(TAG, "stop: SecurityException", e)
        }
        running = false
        // An explicit stop invalidates any start still waiting for an ack.
        settlePendingStart { it.fail(ERROR_SUPERSEDED, "stopped before promotion") }
        result.success(true)
    }

    /** Parks [result] until the service acks, or the bound elapses. */
    private fun awaitPromotionAck(result: MethodChannel.Result) {
        settlePendingStart { it.fail(ERROR_SUPERSEDED, "a newer start superseded this one") }

        val parked = PendingStart(result)
        pendingStart = parked
        val timeout = Runnable {
            if (pendingStart === parked) {
                pendingStart = null
                pendingStartTimeout = null
            }
            if (parked.fail(
                    ERROR_PROMOTION_TIMEOUT,
                    "foreground promotion was not acknowledged within " +
                        "${PROMOTION_ACK_TIMEOUT_MS}ms",
                )
            ) {
                running = false
            }
        }
        pendingStartTimeout = timeout
        mainHandler.postDelayed(timeout, PROMOTION_ACK_TIMEOUT_MS)
    }

    /** Main-thread only: settles and clears the parked start, if any. */
    private fun settlePendingStart(settle: (PendingStart) -> Unit) {
        pendingStartTimeout?.let { mainHandler.removeCallbacks(it) }
        pendingStartTimeout = null
        val parked = pendingStart ?: return
        pendingStart = null
        settle(parked)
    }

    /**
     * Called by [AutoRecordForegroundService] on every connection
     * transition. Forwards on the main thread to the EventSink, or
     * buffers in the ring when no subscriber is attached.
     */
    fun post(event: Map<String, Any>) {
        mainHandler.post { deliver(event) }
    }

    /**
     * #4355 — the OS promoted the service. This, and only this, is what makes
     * [running] true and what answers a parked `start`.
     */
    fun postPromoted(generation: Int) {
        mainHandler.post {
            running = true
            settlePendingStart { it.succeed() }
            deliver(
                mapOf<String, Any>(
                    "type" to EVENT_PROMOTED,
                    "generation" to generation,
                    "atMillis" to System.currentTimeMillis(),
                ),
            )
        }
    }

    /**
     * #4355 — the single explicit failure outcome for an arm that could not be
     * promoted (or whose GATT the platform refused). [reason] is a
     * [PromotionFailureReason] wire name.
     */
    fun postStartFailure(reason: String) {
        mainHandler.post {
            running = false
            settlePendingStart { it.fail(ERROR_PROMOTION_REFUSED, reason) }
            deliver(
                mapOf<String, Any>(
                    "type" to EVENT_START_FAILED,
                    "reason" to reason,
                    "atMillis" to System.currentTimeMillis(),
                ),
            )
        }
    }

    /** Marker called by the service so we can flip [isRunning] off when the OS kills it. */
    fun markStopped() {
        running = false
    }

    private fun deliver(event: Map<String, Any>) {
        val sink = eventSink
        if (sink != null) {
            sink.success(event)
        } else {
            if (pending.size >= PENDING_CAPACITY) {
                pending.removeFirst()
            }
            pending.addLast(event)
        }
    }

    private fun drainPending() {
        val sink = eventSink ?: return
        while (pending.isNotEmpty()) {
            sink.success(pending.removeFirst())
        }
    }
}
