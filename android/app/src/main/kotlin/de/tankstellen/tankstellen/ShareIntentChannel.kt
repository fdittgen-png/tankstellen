// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

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
        return try {
            val payload = decode(intent) ?: return false
            val sink = eventSink
            if (sink != null) {
                sink.success(payload)
            } else {
                pendingInitial = payload
            }
            true
        } catch (e: Exception) {
            Log.w(TAG, "share intent decode failed", e)
            false
        }
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
        val resolver = context.contentResolver
        val mime = resolver.getType(uri) ?: intentType ?: ""
        val kind = when {
            mime.startsWith("image/") -> "image"
            mime == "application/pdf" -> "pdf"
            mime.startsWith("text/") -> "text"
            else -> "file"
        }

        // For a text/* stream, read the body directly rather than caching a file.
        if (kind == "text") {
            val text = try {
                resolver.openInputStream(uri)?.use { it.readBytes().toString(Charsets.UTF_8) }
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
            "shared_receipt_${System.currentTimeMillis()}_${items_seq++}.$ext",
        )
        return try {
            resolver.openInputStream(uri)?.use { input ->
                cacheFile.outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            mapOf("kind" to kind, "path" to cacheFile.absolutePath)
        } catch (e: Exception) {
            Log.w(TAG, "stream copy failed for $uri", e)
            null
        }
    }

    /** Monotonic suffix so two streams shared in the same millisecond differ. */
    @Volatile
    private var items_seq = 0

    /** ISO 3166-1 alpha-2 region of the device locale, or null. */
    private fun deviceCountry(): String? {
        val country = Locale.getDefault().country
        return if (country.isNullOrBlank()) null else country.uppercase(Locale.ROOT)
    }
}
