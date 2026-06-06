// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Android Auto v2 — PHASE-1 (#2947 / epic #2946): the LIVE data bridge between
 * the native car screens and a headless Flutter engine.
 *
 * v1 rendered a stale SharedPreferences snapshot the last in-app search/radar
 * wrote ([CarStation.read]). Phase-1 swaps BOTH the SEARCH (slice 1, #2987) and
 * the RADAR (slice 2) data sources for an on-demand live fetch: this object
 * spins up a dedicated, CACHED headless [FlutterEngine] and runs the Dart
 * `carDataMain` entry point (`lib/features/car/car_data_service.dart`) through
 * it, then asks Dart — over the `tankstellen/car_data` [MethodChannel] — for
 * the freshest nearby stations (Search and Radar share one live producer,
 * differing only in the snapshot fallback key).
 *
 * ## Why this preserves the #1498 FGS-avoidance
 * The engine lives in the BOUND [androidx.car.app.CarAppService]/Session the
 * Android Auto / Automotive host binds — it is NEVER hosted in a started /
 * foreground service. No FOREGROUND_SERVICE permission and no
 * foregroundServiceType is added; the Play Open-Testing upload still ships
 * without the Foreground Service Use form.
 *
 * ## Why a dedicated cached engine (not MainActivity's)
 * Reusing MainActivity's engine would couple the car process to the phone UI's
 * lifecycle (and would be null when the app isn't foreground). A dedicated
 * engine cached under [ENGINE_CACHE_ID] keeps the car path self-contained:
 * created on Session CREATED, destroyed (and evicted from the cache) on Session
 * DESTROYED — see [create] / [destroy].
 *
 * ## Plugin auto-registration (verified, not assumed)
 * Constructing `FlutterEngine(context)` runs the embedding's default
 * `automaticallyRegisterPlugins` path: the constructor calls
 * `flutterLoader.startInitialization` + `ensureInitializationComplete`, then
 * `GeneratedPluginRegister.registerGeneratedPlugins(this)` (FlutterEngine.java).
 * So the headless engine gets the same plugins the app's engine does —
 * including `path_provider` (the [io.flutter.embedding.engine] path the Dart
 * `HiveIsolateLock` / Hive isolate-init relies on) and `home_widget` (the
 * snapshot-cache write). Dio uses `dart:io` HttpClient, which needs no plugin.
 *
 * ## Timeout + fallback contract
 * [fetch] runs with a HARD [FETCH_TIMEOUT_MS] ceiling; on timeout, channel
 * fault, or a `no_gps` result it invokes the callback with `null`, so the
 * calling screen keeps its snapshot (never blanks). A re-entrancy guard
 * permits one in-flight fetch per [CarFetchKind]; a duplicate request while one
 * is running short-circuits to `null`.
 */
/**
 * The narrow surface [StationListScreen] needs from the live data path, so a
 * Robolectric test can substitute a fake (the real [CarDataBridge] is a process
 * singleton wrapping a [FlutterEngine] that can't spin up under Robolectric).
 */
interface CarLiveSource {
    /** Whether a live engine is ready to serve [fetch]. */
    val isReady: Boolean

    /**
     * Fetch the live list for [kind], invoking [callback] once with the JSON
     * string, or `null` to keep the snapshot.
     */
    fun fetch(kind: CarFetchKind, callback: CarDataBridge.FetchCallback)
}

object CarDataBridge : CarLiveSource {

    /** Cache id for the dedicated headless car engine. */
    // i18n-ignore: engine-cache identifier, not user-facing text.
    private const val ENGINE_CACHE_ID = "tankstellen_car"

    /** Dart entry point (`@pragma('vm:entry-point') void carDataMain()`). */
    // i18n-ignore: Dart entry-point name, not user-facing text.
    private const val DART_ENTRYPOINT = "carDataMain"

    /** MethodChannel name shared with the Dart `kCarDataChannel`. */
    // i18n-ignore: platform channel name, not user-facing text.
    private const val CHANNEL = "tankstellen/car_data"

    /** Dart method that returns the live Search JSON. */
    // i18n-ignore: protocol token, not user-facing text.
    private const val METHOD_FETCH_SEARCH = "fetchSearch"

    /** Dart method that returns the live Radar JSON (v2 phase-1 slice 2). */
    // i18n-ignore: protocol token, not user-facing text.
    private const val METHOD_FETCH_RADAR = "fetchRadar"

    /** Dart sentinel for "no usable persisted GPS fix". */
    // i18n-ignore: protocol sentinel, not user-facing text.
    private const val NO_GPS = "no_gps"

    /**
     * Hard ceiling on a single fetch round-trip (engine spin-up + Dart work +
     * channel reply). Kept above the Dart side's own 7 s fetch timeout so the
     * Dart path wins the race normally and this is the last-resort backstop.
     */
    const val FETCH_TIMEOUT_MS = 8_000L

    private val mainHandler = Handler(Looper.getMainLooper())

    /** The cached headless engine + its channel, or null when torn down. */
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null

    /** One in-flight guard per kind (re-entrancy). */
    private val inFlight = mutableMapOf<CarFetchKind, AtomicBoolean>()

    /**
     * Result of a [fetch]: the JSON list string on success, or `null` when the
     * caller should keep its snapshot (timeout / fault / no fix).
     */
    fun interface FetchCallback {
        fun onResult(json: String?)
    }

    /**
     * Lazily create + cache the headless engine and open the channel. Idempotent
     * — a second call while alive is a no-op. Call from Session `onCreate`.
     *
     * Constructing [FlutterEngine] auto-registers plugins (see class doc) and
     * initialises the Flutter loader, so [FlutterInjector] can resolve the app
     * bundle path immediately after.
     */
    @Synchronized
    fun create(context: Context) {
        if (engine != null) return
        try {
            val appContext = context.applicationContext
            val flutterEngine = FlutterEngine(appContext)
            val bundlePath = FlutterInjector.instance().flutterLoader().findAppBundlePath()
            flutterEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(bundlePath, DART_ENTRYPOINT),
            )
            FlutterEngineCache.getInstance().put(ENGINE_CACHE_ID, flutterEngine)
            channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            engine = flutterEngine
        } catch (e: Exception) {
            // A failed spin-up must never crash the car session — the screens
            // simply fall back to their snapshot. Leave engine/channel null.
            engine = null
            channel = null
        }
    }

    /**
     * Destroy the engine and evict it from the cache. Idempotent. Call from
     * Session `onDestroy` so no engine outlives the car connection (preserves
     * the bound-service, no-FGS contract).
     */
    @Synchronized
    fun destroy() {
        channel = null
        FlutterEngineCache.getInstance().remove(ENGINE_CACHE_ID)
        try {
            engine?.destroy()
        } catch (_: Exception) {
            // Best-effort teardown.
        }
        engine = null
        inFlight.clear()
    }

    /** Whether a live engine is currently available. */
    override val isReady: Boolean
        @Synchronized get() = channel != null

    /**
     * Fetch the live list for [kind], invoking [callback] exactly once with the
     * JSON string, or `null` to keep the snapshot. Honours [FETCH_TIMEOUT_MS]
     * and the per-kind re-entrancy guard. Phase-1 wires BOTH
     * [CarFetchKind.SEARCH] (slice 1) and [CarFetchKind.RADAR] (slice 2) to
     * their respective Dart fetch methods.
     *
     * The callback is always delivered on the main thread.
     */
    override fun fetch(kind: CarFetchKind, callback: FetchCallback) {
        val ch = channel
        if (ch == null) {
            callback.onResult(null)
            return
        }
        val method = when (kind) {
            CarFetchKind.SEARCH -> METHOD_FETCH_SEARCH
            CarFetchKind.RADAR -> METHOD_FETCH_RADAR
        }

        val guard = inFlight.getOrPut(kind) { AtomicBoolean(false) }
        if (!guard.compareAndSet(false, true)) {
            // A fetch for this kind is already running — don't double-hit.
            callback.onResult(null)
            return
        }

        val done = AtomicBoolean(false)
        fun finish(json: String?) {
            if (!done.compareAndSet(false, true)) return
            guard.set(false)
            mainHandler.post { callback.onResult(json) }
        }

        // Hard backstop timeout independent of the Dart-side timeout.
        val timeout = Runnable { finish(null) }
        mainHandler.postDelayed(timeout, FETCH_TIMEOUT_MS)

        ch.invokeMethod(method, null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                mainHandler.removeCallbacks(timeout)
                val json = result as? String
                // A no_gps marker or non-JSON-array reply → keep the snapshot.
                finish(if (json == null || json == NO_GPS) null else json)
            }

            override fun error(code: String, message: String?, details: Any?) {
                mainHandler.removeCallbacks(timeout)
                finish(null)
            }

            override fun notImplemented() {
                mainHandler.removeCallbacks(timeout)
                finish(null)
            }
        })
    }
}

/**
 * Which car list a [CarDataBridge.fetch] targets. Phase-1 (#2947) wires BOTH
 * [SEARCH] (slice 1, #2987) and [RADAR] (slice 2) to the live bridge.
 */
enum class CarFetchKind {
    SEARCH,
    RADAR,
}
