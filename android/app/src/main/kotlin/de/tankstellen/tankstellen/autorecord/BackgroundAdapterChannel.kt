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
 *       start(mac: String) -> Bool   starts the foreground service
 *       stop()             -> Bool   stops the foreground service
 *       isRunning()        -> Bool   true while the service is alive
 *  - `tankstellen/auto_record/events` (EventChannel):
 *       Stream<Map>  events of the form
 *          {"type": "connect" | "disconnect", "mac": "<MAC>", "atMillis": <Long>}
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
 */
object BackgroundAdapterChannel {
    private const val TAG = "BackgroundAdapter"
    private const val METHOD_CHANNEL = "tankstellen/auto_record/methods"
    private const val EVENT_CHANNEL = "tankstellen/auto_record/events"

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

    /** Tracks whether the foreground service is currently running. */
    @Volatile
    private var running: Boolean = false

    private val mainHandler = Handler(Looper.getMainLooper())

    fun registerWith(flutterEngine: FlutterEngine, context: Context) {
        appContext = context.applicationContext

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
            "start" -> {
                val mac = call.argument<String>("mac")
                if (mac.isNullOrBlank()) {
                    result.error("arg", "mac missing", null)
                    return
                }
                val intent = Intent(ctx, AutoRecordForegroundService::class.java).apply {
                    putExtra(AutoRecordForegroundService.EXTRA_MAC, mac)
                }
                try {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        ctx.startForegroundService(intent)
                    } else {
                        ctx.startService(intent)
                    }
                    running = true
                    result.success(true)
                } catch (e: SecurityException) {
                    Log.w(TAG, "start: missing FOREGROUND_SERVICE permission", e)
                    result.error("permission", e.message ?: "permission denied", null)
                } catch (e: IllegalStateException) {
                    // App in background on Android 12+ — caller must
                    // arm the service from a foreground context. Bubble
                    // up so Dart can decide what to do.
                    Log.w(TAG, "start: cannot start FGS from background", e)
                    result.error("state", e.message ?: "cannot start fgs", null)
                }
            }
            "stop" -> {
                val intent = Intent(ctx, AutoRecordForegroundService::class.java)
                try {
                    ctx.stopService(intent)
                } catch (e: SecurityException) {
                    Log.w(TAG, "stop: SecurityException", e)
                }
                running = false
                result.success(true)
            }
            "isRunning" -> result.success(running)
            else -> result.notImplemented()
        }
    }

    /**
     * Called by [AutoRecordForegroundService] on every connection
     * transition. Forwards on the main thread to the EventSink, or
     * buffers in the ring when no subscriber is attached.
     */
    fun post(event: Map<String, Any>) {
        mainHandler.post {
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
    }

    /** Marker called by the service so we can flip [isRunning] off when the OS kills it. */
    fun markStopped() {
        running = false
    }

    private fun drainPending() {
        val sink = eventSink ?: return
        while (pending.isNotEmpty()) {
            sink.success(pending.removeFirst())
        }
    }
}
