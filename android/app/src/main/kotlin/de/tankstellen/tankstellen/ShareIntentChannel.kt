// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/**
 * GMS-free inbound OS share receiver (#2735, Epic #2687).
 *
 * Replaces the third-party `share_handler` plugin, which was dropped to keep
 * the F-Droid build free of any Play-Services risk. This is the SAME
 * app-internal channel pattern as [Obd2ClassicPlugin] /
 * [PublicFileExporterChannel]: it uses only the Android framework + Flutter —
 * NO `com.google.android.gms` / `com.google.mlkit` — so nothing it adds can
 * leak into the fdroid dex.
 *
 * Two channels, mirroring the others:
 *  - `tankstellen/share_intent/methods` (MethodChannel):
 *       getInitialShare() -> Map?   the ACTION_SEND payload that cold-launched
 *                                   the activity, consumed once (or null)
 *  - `tankstellen/share_intent/events` (EventChannel):
 *       Stream<Map>  one decoded share per warm ACTION_SEND
 *
 * Payload shape (matches `SharedReceiptIntent.fromPlatform` on the Dart side):
 *   {
 *     "items": [ {"kind":"image"|"pdf"|"text"|"file", "path":..., "text":...} ],
 *     "country": "DE"   // ISO 3166-1 alpha-2 from the device locale, or absent
 *   }
 *
 * Lifecycle. [MainActivity] forwards `onCreate`'s launch intent and every
 * `onNewIntent` here. A SEND that arrives before Dart has subscribed (cold
 * launch) is cached and replayed by [getInitialShare]; a SEND while Dart is
 * subscribed (warm) is emitted on the EventChannel immediately.
 */
object ShareIntentChannel {
    private const val TAG = "ShareIntent"
    private const val METHOD_CHANNEL = "tankstellen/share_intent/methods"
    private const val EVENT_CHANNEL = "tankstellen/share_intent/events"

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    /** A SEND seen before Dart subscribed (cold launch); drained by getInitialShare. */
    @Volatile
    private var pendingInitial: Map<String, Any?>? = null

    /**
     * #4048 — share decoding runs here, never on the platform thread.
     * #4064 — a cached pool, not a single thread: the watchdog below
     * bounds a stalled read by closing the stream, but a pipe-backed
     * read parked in the kernel is not reliably woken by close() from
     * another thread. On a single worker that one wedged decode queued
     * every later SEND behind it for the process lifetime, with no log
     * and no UI symptom. Each decode now gets its own thread, so a stall
     * costs one share, never the next one. The cache-file sequence is
     * serialised separately (see [nextSeq]).
     */
    private val worker: ExecutorService =
        Executors.newCachedThreadPool { r ->
            Thread(r, "share-intent-decode").apply { isDaemon = true }
        }

    /** Watchdog timer for [SHARE_READ_TIMEOUT_MS]; separate so a stalled
     *  read on [worker] cannot also starve its own watchdog. */
    private val watchdog: ScheduledExecutorService =
        Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "share-intent-watchdog").apply { isDaemon = true }
        }

    private val main = Handler(Looper.getMainLooper())

    fun registerWith(flutterEngine: FlutterEngine, context: Context) {
        val appContext = context.applicationContext

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShare" -> {
                        val payload = pendingInitial
                        pendingInitial = null
                        result.success(payload)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    // #4064 — a SEND that landed between getInitialShare()
                    // and this subscription sat in pendingInitial forever.
                    // Whichever of the two runs first now consumes it.
                    val parked = pendingInitial
                    if (parked != null && sink != null) {
                        pendingInitial = null
                        sink.success(parked)
                    }
                }

                override fun onCancel(args: Any?) {
                    eventSink = null
                }
            })

        // appContext is captured so a SEND that arrives via onNewIntent can
        // copy content:// streams into the cache without re-plumbing context.
        cachedContext = appContext
    }

    @Volatile
    private var cachedContext: Context? = null

    /**
     * Handle an inbound intent. A non-SEND intent (LAUNCHER tap, widget
     * deep-link, …) is ignored. A SEND that decodes to at least one item is
     * either emitted to a live Dart subscriber (warm) or cached for
     * [getInitialShare] (cold). Wrapped so a malformed share can never crash
     * the activity's intent handling.
     *
     * Returns true when the intent was a share this receiver consumed, so the
     * caller can skip any non-share fallback handling.
     */
    fun handleIntent(intent: Intent?): Boolean {
        if (intent == null) return false
        val action = intent.action
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE) {
            return false
        }
        // #4048 — decode OFF the platform thread. The #3740 byte cap
        // bounds how MUCH a hostile or merely slow ContentProvider can
        // send; it does not bound how LONG it takes to send it. A provider
        // that trickles bytes held the UI thread for as long as it chose to
        // trickle, and `deliver` below is the only part that has to be back
        // on the main looper (Flutter channels are platform-thread only).
        //
        // Returning true before the work finishes is correct: the return
        // value answers "is this a share I am consuming?", which is already
        // known from the action, not "did it decode?".
        worker.execute {
            val payload = try {
                decode(intent)
            } catch (e: Exception) {
                Log.w(TAG, "share intent decode failed", e)
                null
            }
            if (payload != null) main.post { deliver(payload) }
        }
        return true
    }

    /** Platform-thread delivery — Flutter channels permit nothing else. */
    private fun deliver(payload: Map<String, Any?>) {
        val sink = eventSink
        if (sink != null) sink.success(payload) else pendingInitial = payload
    }

    /** Decodes a SEND / SEND_MULTIPLE intent into the Dart payload map, or null. */
    private fun decode(intent: Intent): Map<String, Any?>? {
        val items = ArrayList<Map<String, Any?>>()

        // EXTRA_TEXT (a shared text body — e-receipt e-mail / SMS) (#2838).
        val sharedText = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        if (!sharedText.isNullOrBlank()) {
            items.add(mapOf("kind" to "text", "text" to sharedText))
        }

        // EXTRA_STREAM content URIs (images / PDFs / other files).
        val uris: List<Uri> = when (intent.action) {
            Intent.ACTION_SEND -> {
                @Suppress("DEPRECATION")
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                if (uri != null) listOf(uri) else emptyList()
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                @Suppress("DEPRECATION")
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                    ?: emptyList()
            }
            else -> emptyList()
        }
        for (uri in uris) {
            val item = decodeUri(uri, intent.type) ?: continue
            items.add(item)
        }

        if (items.isEmpty()) return null
        return mapOf(
            "items" to items,
            "country" to deviceCountry(),
        )
    }

    /**
     * Copies a shared content [uri] into the app cache and classifies it by
     * MIME / extension. Copying is required: the sharing app grants only a
     * transient read permission on the original URI, which is gone by the
     * time the Dart OCR / rasterise path runs.
     */
    private fun decodeUri(uri: Uri, intentType: String?): Map<String, Any?>? {
        val context = cachedContext ?: return null
        // #3740 — accept only content:// URIs. A file:// (or any other
        // scheme) in EXTRA_STREAM lets a malicious sharer point the copy at
        // app-private files (path traversal into our own sandbox) instead of
        // a ContentProvider stream it actually owns. Modern senders must use
        // FileProvider content URIs anyway (StrictMode enforces since N).
        if (uri.scheme != "content") {
            Log.w(TAG, "rejected non-content share URI scheme: ${uri.scheme}")
            return null
        }
        val resolver = context.contentResolver
        val mime = resolver.getType(uri) ?: intentType ?: ""
        val kind = when {
            mime.startsWith("image/") -> "image"
            mime == "application/pdf" -> "pdf"
            mime.startsWith("text/") -> "text"
            else -> "file"
        }

        // For a text/* stream, read the body directly rather than caching a
        // file. Bounded (#3740): an unbounded readBytes() let a hostile
        // sharer OOM the process with a giant stream.
        if (kind == "text") {
            val text = try {
                resolver.openInputStream(uri)?.use { input ->
                    val out = java.io.ByteArrayOutputStream()
                    copyBounded(input, out)
                    out.toByteArray().toString(Charsets.UTF_8)
                }
            } catch (e: Exception) {
                Log.w(TAG, "text stream read failed", e)
                null
            }
            if (text.isNullOrBlank()) return null
            return mapOf("kind" to "text", "text" to text)
        }

        val ext = when (kind) {
            "image" -> if (mime == "image/png") "png" else "jpg"
            "pdf" -> "pdf"
            else -> "bin"
        }
        val cacheFile = File(
            context.cacheDir,
            "shared_receipt_${System.currentTimeMillis()}_${nextSeq()}.$ext",
        )
        return try {
            resolver.openInputStream(uri)?.use { input ->
                cacheFile.outputStream().use { output -> copyBounded(input, output) }
            } ?: return null
            mapOf("kind" to kind, "path" to cacheFile.absolutePath)
        } catch (e: Exception) {
            Log.w(TAG, "stream copy failed for $uri", e)
            // Best-effort cleanup of a partial over-cap/failed copy.
            cacheFile.delete()
            null
        }
    }

    /** Copy cap (#3740): a receipt photo/PDF is well under this; anything
     *  bigger is a resource-exhaustion attempt, not a receipt. */
    private const val MAX_SHARE_BYTES = 8L * 1024 * 1024

    /**
     * #4048 — wall-clock budget for one shared stream. The byte cap limits
     * amount, not time-to-next-byte: a provider that hands over one byte a
     * second stays under 8 MiB essentially forever. Receipts are small and
     * local; anything still arriving after this is not a receipt.
     */
    private const val SHARE_READ_TIMEOUT_MS = 20_000L

    /**
     * Streams [input] into [output], counting bytes as they flow; aborts
     * with an [IOException] the moment the running total exceeds
     * [MAX_SHARE_BYTES] (#3740). Counting the stream — instead of trusting
     * a provider-reported size — means a lying ContentProvider cannot
     * bypass the cap.
     */
    private fun copyBounded(input: InputStream, output: OutputStream) {
        val buf = ByteArray(64 * 1024)
        var total = 0L
        val deadline = System.nanoTime() +
            TimeUnit.MILLISECONDS.toNanos(SHARE_READ_TIMEOUT_MS)
        // #4048 — a per-chunk deadline catches a slow trickle, but a single
        // read() can block forever regardless, and nothing in the loop runs
        // to notice. Closing the stream from another thread is what makes
        // that read throw, so the watchdog is the part that actually bounds
        // the wait; the loop check just fails faster in the common case.
        val stall = watchdog.schedule(
            {
                // #4064 — the stall is the only evidence there is; say so.
                Log.w(TAG, "share read stalled past ${SHARE_READ_TIMEOUT_MS}ms — closing the stream")
                try {
                    input.close()
                } catch (e: IOException) {
                    Log.w(TAG, "watchdog close failed", e)
                }
            },
            SHARE_READ_TIMEOUT_MS,
            TimeUnit.MILLISECONDS,
        )
        try {
            while (true) {
                val n = input.read(buf)
                if (n < 0) return
                if (System.nanoTime() > deadline) {
                    throw IOException(
                        "shared stream exceeded ${SHARE_READ_TIMEOUT_MS}ms — aborting copy",
                    )
                }
                total += n
                if (total > MAX_SHARE_BYTES) {
                    throw IOException("shared stream exceeds $MAX_SHARE_BYTES bytes — aborting copy")
                }
                output.write(buf, 0, n)
            }
        } finally {
            stall.cancel(false)
        }
    }

    /** Monotonic suffix so two streams shared in the same millisecond differ. */
    private val seqLock = Any()
    private var items_seq = 0

    /** #4064 — the only writer of [items_seq]; decodes run concurrently now. */
    private fun nextSeq(): Int = synchronized(seqLock) { items_seq++ }

    /** ISO 3166-1 alpha-2 region of the device locale, or null. */
    private fun deviceCountry(): String? {
        val country = Locale.getDefault().country
        return if (country.isNullOrBlank()) null else country.uppercase(Locale.ROOT)
    }
}
