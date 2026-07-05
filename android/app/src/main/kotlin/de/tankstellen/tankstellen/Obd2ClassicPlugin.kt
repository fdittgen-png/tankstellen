// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.os.SystemClock
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * In-repo MethodChannel plugin for Bluetooth Classic SPP RFCOMM,
 * the transport used by the vLinker FS OBD2 adapter (#763).
 *
 * Written in Kotlin inside this app to avoid the license problem:
 * the popular flutter_blue_classic package is GPL-3, incompatible
 * with this MIT project. Everything here is the Apache-licensed
 * Android Bluetooth API — no external plugin dependency.
 *
 * Channels:
 *  - "tankstellen.obd2/classic" (MethodChannel):
 *       bondedDevices() -> List<Map{address, name, bondState}>
 *       connect(address, uuid) -> Bool
 *       write(bytes) -> void
 *       disconnect() -> void
 *  - "tankstellen.obd2/classic/incoming" (EventChannel):
 *       Stream<List<int>> — bytes arriving from the socket's
 *       InputStream, pushed on a background reader thread.
 *
 * The Dart-side `PluginClassicBluetoothFacade` is the only caller.
 *
 * Threading: Android's BluetoothSocket I/O MUST NOT happen on the
 * main thread. `connect()` does the dial on a background thread and
 * completes a MethodChannel.Result when done. The reader thread runs
 * for the lifetime of the connection and pushes bytes to the
 * EventChannel's sink from whichever thread — Flutter's platform-
 * channel plumbing marshals to the main thread for delivery.
 */
object Obd2ClassicPlugin {
    private const val TAG = "Obd2ClassicPlugin"
    private const val METHOD_CHANNEL = "tankstellen.obd2/classic"
    private const val INCOMING_CHANNEL = "tankstellen.obd2/classic/incoming"

    /** #2906 — bounded RFCOMM connect attempts before falling back to the
     *  insecure / reflection channel-1 socket. Real ELM327 clones routinely
     *  reject the FIRST `connect()` (the adapter is still waking the SPP
     *  service) with `IOException: read failed, socket might closed ... -1`,
     *  but answer the 2nd or 3rd try. ~3 attempts with a short backoff between
     *  each mirrors the Dart-side #2909 `channel.open()` retry shape. */
    private const val MAX_RFCOMM_ATTEMPTS = 3
    private const val RFCOMM_RETRY_BASE_MS = 150L

    /** #3348 — per-attempt watchdog for the blocking `BluetoothSocket.connect()`.
     *  `connect()` has NO timeout: when the adapter's single RFCOMM channel is
     *  still held by a just-dropped session it blocks for the OS default
     *  (~20–40 s) before throwing `read failed … read ret: -1`. Across the
     *  secure×3 + insecure + reflection ladder that turned every RECONNECT into
     *  an 80–120 s hang (field exports, #3346). A watchdog that `close()`s the
     *  socket after this budget makes the blocking `connect()` throw at once, so
     *  a failing rung fails FAST and the Dart-side reconnect controller's
     *  exponential backoff (2→60 s) spaces attempts enough for the adapter to
     *  release its channel — bounded, responsive tries instead of a 2-min freeze.
     *  7 s comfortably clears a healthy connect (a full self-test incl. ELM init
     *  is ~3 s). */
    private const val RFCOMM_CONNECT_TIMEOUT_MS = 7000L

    /** #3421 — default WHOLE-LADDER budget. The #3348 watchdog bounds each
     *  RUNG at 7 s but never the CALL: field traces (#3415 t5/t8) show one
     *  native connect blocking 4.7–16.8 minutes across a wedged ladder.
     *  Before each rung starts, the elapsed time is checked against the
     *  budget and the remaining rungs are SKIPPED (strategy
     *  `budget-exhausted`) once it is spent. The Dart side normally passes
     *  its own `budgetMs`; this default keeps an old Dart caller bounded. */
    private const val DEFAULT_CONNECT_BUDGET_MS = 20_000L

    private var socket: BluetoothSocket? = null
    private var readerThread: Thread? = null
    private val readerRunning = AtomicBoolean(false)
    private var eventSink: EventChannel.EventSink? = null

    fun registerWith(flutterEngine: FlutterEngine, context: Context) {
        val method = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        val events = EventChannel(flutterEngine.dartExecutor.binaryMessenger, INCOMING_CHANNEL)

        method.setMethodCallHandler { call, result -> handle(call, result, context) }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result, context: Context) {
        try {
            when (call.method) {
                "bondedDevices" -> result.success(bondedDevices(context))
                "connect" -> {
                    val address = call.argument<String>("address")
                        ?: return result.error("arg", "address missing", null)
                    val uuid = call.argument<String>("uuid")
                        ?: return result.error("arg", "uuid missing", null)
                    // #3421 — optional whole-ladder budget from Dart (absent
                    // on an old Dart side → the bounded default applies).
                    val budgetMs = call.argument<Number>("budgetMs")?.toLong()
                        ?: DEFAULT_CONNECT_BUDGET_MS
                    thread(name = "obd2-classic-connect") {
                        // #2969 — return a Map{ok, strategy, error} so the Dart
                        // side surfaces WHICH RFCOMM strategy won (or that all
                        // were exhausted) + the last IOException, instead of a
                        // bare Boolean that threw away every diagnostic (only
                        // Logcat had it). The Dart binding accepts BOTH shapes.
                        // #3247 — the ladder runs here on the background
                        // thread; the Result itself is posted to the main
                        // looper (platform-channel thread requirement).
                        val outcome = connect(context, address, uuid, budgetMs)
                        postResult { result.success(outcome) }
                    }
                }
                "write" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                        ?: return result.error("arg", "bytes missing", null)
                    writeBytes(bytes, result)
                }
                "disconnect" -> {
                    disconnect()
                    result.success(true)
                }
                // #3183 — the Dart-side permission flow needs the REAL SDK
                // level (it hard-coded 33 before, making the <31 legacy
                // location-permission branch unreachable). Reuse this channel
                // instead of pulling in device_info_plus.
                "sdkInt" -> result.success(android.os.Build.VERSION.SDK_INT)
                // #3422 — wedge-recovery rung 1: refresh the LOCAL SDP /
                // RFCOMM-channel cache for the adapter. Kicks off an async
                // OS-side SDP query; `true` means the query was accepted.
                "fetchUuidsWithSdp" -> {
                    val address = call.argument<String>("address")
                        ?: return result.error("arg", "address missing", null)
                    result.success(fetchUuidsWithSdp(context, address))
                }
                // #3422 — wedge-recovery rung 2 (guarded re-bond): drop the
                // bond via the hidden reflection `removeBond()`, then re-pair
                // with the public `createBond()`. Both async kick-offs.
                "removeBond" -> {
                    val address = call.argument<String>("address")
                        ?: return result.error("arg", "address missing", null)
                    result.success(removeBond(context, address))
                }
                "createBond" -> {
                    val address = call.argument<String>("address")
                        ?: return result.error("arg", "address missing", null)
                    result.success(createBond(context, address))
                }
                // #3422 — wedge-recovery rung 3 needs to await the adapter
                // actually turning OFF between the two consent dialogs.
                "adapterEnabled" -> {
                    @Suppress("MissingPermission")
                    result.success(adapterOrNull(context)?.isEnabled == true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "handle ${call.method} failed", e)
            result.error("platform", e.message ?: e.javaClass.simpleName, null)
        }
    }

    private fun bondedDevices(context: Context): List<Map<String, Any?>> {
        val adapter = adapterOrNull(context) ?: return emptyList()
        // Requires BLUETOOTH_CONNECT on Android 12+. Caller gates
        // this via Obd2Permissions before invoking us.
        @Suppress("MissingPermission")
        val bonded = adapter.bondedDevices ?: return emptyList()
        return bonded.map { d ->
            mapOf(
                "address" to d.address,
                "name" to (d.name ?: ""),
            )
        }
    }

    /** #2969 — build the connect result map the Dart side reads. `ok` is the
     *  only field the legacy bool path used; `strategy` names which RFCOMM
     *  variant won / the terminal failure mode; `error` carries the last
     *  IOException message. */
    private fun connectResult(
        ok: Boolean,
        strategy: String,
        error: String? = null,
    ): Map<String, Any?> = mapOf(
        "ok" to ok,
        "strategy" to strategy,
        "error" to error,
    )

    private fun connect(
        context: Context,
        address: String,
        uuid: String,
        budgetMs: Long,
    ): Map<String, Any?> {
        // #3421 — whole-ladder budget. Monotonic clock; started BEFORE the
        // teardown of any prior socket so everything this call does counts.
        val startedAt = SystemClock.elapsedRealtime()
        fun budgetSpent(): Boolean =
            SystemClock.elapsedRealtime() - startedAt >= budgetMs
        disconnect() // ensure any prior socket is closed
        val adapter = adapterOrNull(context)
            ?: return connectResult(false, "no-adapter", "Bluetooth adapter unavailable")
        @Suppress("MissingPermission")
        val device = try {
            adapter.getRemoteDevice(address)
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "connect: bad address $address", e)
            return connectResult(false, "bad-address", e.message ?: "bad address")
        }
        // cancelDiscovery() is required before EVERY connect() — a live
        // discovery slows the RFCOMM handshake to a crawl (and can fail it).
        @Suppress("MissingPermission")
        adapter.cancelDiscovery()

        val serviceUuid = UUID.fromString(uuid)
        // #2969 — capture the last IOException across ALL strategies so the
        // returned map can carry it (was Logcat-only).
        var lastError: String? = null
        // 1) Bounded retry on the standard secure SPP socket. This runs on the
        //    background "obd2-classic-connect" thread, so the Thread.sleep
        //    backoff between attempts never blocks the Flutter main thread.
        for (attempt in 1..MAX_RFCOMM_ATTEMPTS) {
            // #3421 — skip the remaining rungs once the whole-ladder budget
            // is spent. The per-rung #3348 watchdog is unchanged; this bounds
            // the CALL, which the watchdog alone never did (#3415 t5/t8).
            if (budgetSpent()) {
                return budgetExhaustedResult(address, budgetMs, lastError)
            }
            @Suppress("MissingPermission")
            val s = try {
                device.createRfcommSocketToServiceRecord(serviceUuid)
            } catch (e: IOException) {
                Log.e(TAG, "connect: createRfcommSocket failed (attempt $attempt)", e)
                lastError = e.message ?: "createRfcommSocket failed"
                null
            }
            if (s != null) {
                val r = tryConnectSocket(s, attempt, ::budgetSpent)
                if (r == null) return connectResult(true, "secure")
                lastError = r
            }
            if (attempt < MAX_RFCOMM_ATTEMPTS) {
                try {
                    Thread.sleep(RFCOMM_RETRY_BASE_MS * attempt)
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return connectResult(false, "interrupted", lastError)
                }
            }
        }
        // 2) Documented clone fallback: the INSECURE SPP socket. Many ELM327
        //    clones never complete the secure (authenticated/encrypted) RFCOMM
        //    handshake but connect fine over the insecure variant.
        if (budgetSpent()) { // #3421
            return budgetExhaustedResult(address, budgetMs, lastError)
        }
        @Suppress("MissingPermission")
        val insecure = try {
            device.createInsecureRfcommSocketToServiceRecord(serviceUuid)
        } catch (e: IOException) {
            Log.e(TAG, "connect: createInsecureRfcommSocket failed", e)
            lastError = e.message ?: "createInsecureRfcommSocket failed"
            null
        }
        if (insecure != null) {
            val r = tryConnectSocket(insecure, MAX_RFCOMM_ATTEMPTS + 1, ::budgetSpent)
            if (r == null) return connectResult(true, "insecure")
            lastError = r
        }
        // 3) Last-resort reflection on the hidden channel-1 RFCOMM socket —
        //    the long-standing workaround for clones whose SDP record is
        //    missing/garbage so the UUID lookup resolves to no channel.
        if (budgetSpent()) { // #3421
            return budgetExhaustedResult(address, budgetMs, lastError)
        }
        val reflected = reflectChannelOneSocket(device)
        if (reflected != null) {
            val r = tryConnectSocket(reflected, MAX_RFCOMM_ATTEMPTS + 2, ::budgetSpent)
            if (r == null) return connectResult(true, "reflection")
            lastError = r
        }
        Log.e(TAG, "connect: all RFCOMM strategies exhausted for $address")
        return connectResult(false, "exhausted", lastError)
    }

    /** #3421 — the whole-ladder budget ran out before this rung could start:
     *  log + report the dedicated `budget-exhausted` strategy (with the last
     *  rung's IOException, when any rung ran at all) so the Dart connect
     *  trace tells a budget overrun apart from a fully-exhausted ladder. */
    private fun budgetExhaustedResult(
        address: String,
        budgetMs: Long,
        lastError: String?,
    ): Map<String, Any?> {
        Log.w(
            TAG,
            "connect: whole-ladder budget (${budgetMs}ms) exhausted for " +
                "$address — skipping remaining rungs (#3421)",
        )
        return connectResult(false, "budget-exhausted", lastError)
    }

    /** Attempt to connect [s], adopt it as the live socket + start the reader
     *  on success, or close it on failure. Returns null on success, or the
     *  IOException message on failure (#2969 — was a bare Boolean).
     *
     *  #3495 F2 — [budgetSpent] is re-checked AFTER the blocking `connect()`
     *  returns: a rung that started just under the whole-ladder budget can
     *  complete up to the 7 s watchdog later, PAST the Dart caller's
     *  budget+grace deadline — the Dart `.timeout` has already thrown, so
     *  adopting here would create a live socket + reader with no Dart owner
     *  (a ghost holding the adapter's single SPP channel until the next
     *  connect's teardown). When the budget is spent at completion, the
     *  socket is closed instead of adopted. */
    private fun tryConnectSocket(
        s: BluetoothSocket,
        attempt: Int,
        budgetSpent: () -> Boolean = { false },
    ): String? {
        // #3348 — bound the blocking connect() with a watchdog. `connect()` has
        // no timeout; closing the socket from another thread is the documented
        // way to abort it (it throws immediately). The watchdog only fires when
        // connect() overruns the budget, so a healthy connect is untouched.
        val settled = AtomicBoolean(false)
        val watchdog = thread(name = "obd2-classic-connect-watchdog-$attempt") {
            try {
                Thread.sleep(RFCOMM_CONNECT_TIMEOUT_MS)
            } catch (_: InterruptedException) {
                return@thread // connect finished first; watchdog cancelled
            }
            if (settled.compareAndSet(false, true)) {
                Log.w(TAG, "connect: RFCOMM open exceeded ${RFCOMM_CONNECT_TIMEOUT_MS}ms" +
                    " (attempt $attempt) — aborting socket")
                try { s.close() } catch (_: IOException) {}
            }
        }
        return try {
            s.connect()
            // Won the race: cancel the watchdog before it can abort us.
            if (!settled.compareAndSet(false, true)) {
                // The watchdog already closed the socket the instant before
                // connect() returned — treat as a timeout, not a live link.
                watchdog.interrupt()
                try { s.close() } catch (_: IOException) {}
                return "RFCOMM open timed out after ${RFCOMM_CONNECT_TIMEOUT_MS}ms" +
                    " (attempt $attempt)"
            }
            watchdog.interrupt()
            if (budgetSpent()) {
                // #3495 F2 — completed past the whole-ladder budget: the Dart
                // caller has already timed out and moved on. Close, don't adopt.
                Log.w(TAG, "connect: RFCOMM open completed after the whole-ladder" +
                    " budget (attempt $attempt) — not adopting (#3495)")
                try { s.close() } catch (_: IOException) {}
                return "RFCOMM open completed after the whole-ladder budget" +
                    " (attempt $attempt)"
            }
            socket = s
            startReader()
            null
        } catch (e: IOException) {
            settled.set(true)
            watchdog.interrupt()
            Log.w(TAG, "connect: RFCOMM open failed (attempt $attempt)", e)
            try { s.close() } catch (_: IOException) {}
            if (socket === s) socket = null
            e.message ?: "RFCOMM open failed (attempt $attempt)"
        }
    }

    /** Reflectively open a channel-1 RFCOMM socket (#2906 clone fallback). Some
     *  ELM327 clones expose no usable SDP service record, so the UUID-based
     *  socket never resolves a channel; the hidden `createRfcommSocket(int)`
     *  on channel 1 is the documented community workaround. Returns null when
     *  the reflection is unavailable (future Android hides it) — the caller
     *  then surfaces a clean connect failure. */
    @Suppress("MissingPermission")
    private fun reflectChannelOneSocket(
        device: android.bluetooth.BluetoothDevice,
    ): BluetoothSocket? {
        return try {
            val m = device.javaClass.getMethod(
                "createRfcommSocket", Int::class.javaPrimitiveType,
            )
            m.invoke(device, 1) as? BluetoothSocket
        } catch (e: Exception) {
            Log.w(TAG, "connect: channel-1 reflection unavailable", e)
            null
        }
    }

    private fun startReader() {
        readerRunning.set(true)
        readerThread = thread(name = "obd2-classic-read") {
            val s = socket ?: return@thread
            val buffer = ByteArray(256)
            var endedByEof = false
            try {
                val input = s.inputStream
                while (readerRunning.get()) {
                    val n = input.read(buffer)
                    if (n < 0) {
                        // #3183 — a clean remote EOF is a DROP (the adapter
                        // closed the socket): signalled below so the Dart
                        // onDone fires, instead of the thread dying silently.
                        endedByEof = true
                        break
                    }
                    if (n == 0) continue
                    val slice = buffer.copyOfRange(0, n).toList()
                    postToSink { sink -> sink.success(slice) }
                }
            } catch (e: IOException) {
                Log.w(TAG, "reader: $e")
                // #3183 — the reader exiting on IOException was INVISIBLE to
                // Dart (sink.success was the only sink call in this file), so
                // ClassicElmChannel's onError never fired and a mid-session
                // Classic drop was discovered only lazily on the next write.
                // A DELIBERATE teardown (disconnect() flips readerRunning
                // false, then closes the socket, which interrupts read() with
                // an IOException) is NOT a drop — stay silent for it.
                if (readerRunning.get()) {
                    postToSink { sink ->
                        sink.error("io", e.message ?: "read failed", null)
                    }
                }
                return@thread
            }
            if (endedByEof) {
                postToSink { sink -> sink.endOfStream() }
            }
        }
    }

    /** #3183 — deliver one sink callback on the MAIN thread (EventChannel
     *  sinks must only be touched from the platform thread). No-op when no
     *  Dart listener is attached. */
    private fun postToSink(block: (EventChannel.EventSink) -> Unit) {
        val sink = eventSink ?: return
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            block(sink)
        }
    }

    /** #3247 — complete a MethodChannel Result on the MAIN thread. The
     *  connect/write bodies run on background threads, but a
     *  `MethodChannel.Result` must only be submitted from the platform
     *  thread (mirrors [postToSink] for the EventChannel sink). */
    private fun postResult(block: () -> Unit) {
        android.os.Handler(android.os.Looper.getMainLooper()).post { block() }
    }

    private fun writeBytes(bytes: ByteArray, result: MethodChannel.Result) {
        val s = socket ?: return result.error("state", "not connected", null)
        thread(name = "obd2-classic-write") {
            try {
                s.outputStream.write(bytes)
                s.outputStream.flush()
                // #3247 — result posted to the main looper (see postResult).
                postResult { result.success(true) }
            } catch (e: IOException) {
                Log.e(TAG, "write failed", e)
                postResult { result.error("io", e.message ?: "write failed", null) }
            }
        }
    }

    private fun disconnect() {
        readerRunning.set(false)
        val hadConnection = socket != null
        try { socket?.close() } catch (_: IOException) {}
        socket = null
        readerThread = null
        // #3183 — end the Dart-side byte stream on a deliberate teardown too,
        // in case a listener is still attached (the normal Dart close()
        // cancels its subscription first, making this a no-op). Guarded so
        // the pre-connect "ensure any prior socket is closed" call never
        // signals when there was nothing to tear down.
        if (hadConnection) {
            postToSink { sink -> sink.endOfStream() }
        }
    }

    /** #3422 — wedge-recovery rung 1: ask the OS to re-run SDP discovery for
     *  [address], refreshing the locally-cached UUID / RFCOMM-channel records
     *  a wedged re-open may be dialling into. `fetchUuidsWithSdp()` is an
     *  async kick-off; the Dart side waits a settle delay before its bounded
     *  verification connect. Never throws — false on any failure. */
    private fun fetchUuidsWithSdp(context: Context, address: String): Boolean {
        val adapter = adapterOrNull(context) ?: return false
        return try {
            @Suppress("MissingPermission")
            adapter.getRemoteDevice(address).fetchUuidsWithSdp()
        } catch (e: Exception) {
            Log.w(TAG, "fetchUuidsWithSdp failed for $address", e)
            false
        }
    }

    /** #3422 — wedge-recovery rung 2 (guarded re-bond, config-gated on the
     *  Dart side): drop the bond via the hidden `removeBond()` — reflection,
     *  the long-standing community workaround (no public API removes a bond).
     *  Returns false when the reflection is unavailable (future Android hides
     *  it) or the call fails; the Dart rung then falls through. */
    private fun removeBond(context: Context, address: String): Boolean {
        val adapter = adapterOrNull(context) ?: return false
        return try {
            @Suppress("MissingPermission")
            val device = adapter.getRemoteDevice(address)
            val m = device.javaClass.getMethod("removeBond")
            (m.invoke(device) as? Boolean) == true
        } catch (e: Exception) {
            Log.w(TAG, "removeBond reflection failed for $address", e)
            false
        }
    }

    /** #3422 — wedge-recovery rung 2 second half: re-pair with the PUBLIC
     *  `createBond()`. May surface the system pairing dialog (ELM clones pair
     *  just-works / PIN 1234) — acceptable as guided recovery; the Dart side
     *  gates the whole rung behind a developer flag. Async kick-off; `true`
     *  means the bonding process started. */
    private fun createBond(context: Context, address: String): Boolean {
        val adapter = adapterOrNull(context) ?: return false
        return try {
            @Suppress("MissingPermission")
            adapter.getRemoteDevice(address).createBond()
        } catch (e: Exception) {
            Log.w(TAG, "createBond failed for $address", e)
            false
        }
    }

    private fun adapterOrNull(context: Context): BluetoothAdapter? {
        return try {
            (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
        } catch (e: Exception) {
            Log.e(TAG, "adapter fetch failed", e)
            null
        }
    }
}
