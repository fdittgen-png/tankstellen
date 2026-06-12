// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Looper
import androidx.car.app.CarContext
import androidx.core.content.ContextCompat
import java.util.concurrent.CopyOnWriteArrayList

/**
 * The narrow fix-update surface [StationListScreen] subscribes to, so a
 * Robolectric test can substitute a fake (the real [CarLocationSource] is a
 * process singleton wrapping the platform [LocationManager]).
 */
interface CarFixUpdates {
    /** Subscribe to significant live-fix updates (main-thread delivery). */
    fun addListener(listener: (Location) -> Unit)

    /** Unsubscribe; a never-added listener is a no-op. */
    fun removeListener(listener: (Location) -> Unit)
}

/**
 * Android Auto v2 — PHASE-3 / slice 4 (#2990 / epic #2946): the LIVE in-car
 * GPS source.
 *
 * Phase-1 (#2947) deliberately fed the car screens from the PERSISTED
 * last-known phone fix (`StorageKeys.userPositionLat/Lng`), which goes stale on
 * Automotive OS (no phone process refreshing it) and for a driver who paired
 * the head unit but never opened the phone app. This object acquires a live
 * fix INSIDE the bound `CarAppService`/Session instead:
 *
 *  - [start] is called from the Session lifecycle `onCreate` and [stop] from
 *    `onDestroy`, so location runs ONLY while an Auto session is active —
 *    never in a started / foreground service (preserves the #1498
 *    FGS-avoidance: a bound car app shown on the head unit counts as
 *    "in use" for the while-in-use location permission).
 *  - If `ACCESS_FINE_LOCATION` is already granted (the phone app's normal
 *    grant), updates begin immediately — no prompt. Otherwise the permission
 *    is primed IN-CAR via [CarContext.requestPermissions] (stabilised by
 *    androidx.car.app 1.7.0, the reason for the #2990 bump): the host renders
 *    the grant flow (on-phone for projected Android Auto, on-head-unit for
 *    Automotive OS), at most ONCE per session. A denial simply leaves the
 *    persisted-fix fallback in charge.
 *  - The platform [LocationManager] is used directly (fused provider on
 *    API 31+, else GPS/network) — never a GMS client, so nothing here would
 *    trip `scripts/audit_no_gms.sh` even though this class compiles into both
 *    flavors (only the play manifest registers the car service).
 *
 * The freshest fix is exposed as [latestFix]; [CarDataBridge] attaches it to
 * every fetch over the EXISTING `tankstellen/car_data` channel so the Dart
 * `CarDataService` searches around the live position (and refreshes the
 * persisted fix as the fallback). Screens subscribe via [CarFixUpdates] and
 * are notified on the FIRST fix and after a significant move, so a cold-start
 * `no_gps` empty-state heals itself the moment a fix arrives.
 *
 * Never throws: every platform call is guarded — a location fault degrades to
 * the persisted-fix fallback, never crashes the car session.
 */
object CarLocationSource : CarFixUpdates {

    /** Notify subscribed screens only after moving this far (re-fetch cost). */
    private const val SIGNIFICANT_MOVE_M = 250f

    /** Update cadence requested from the platform provider. */
    private const val MIN_TIME_MS = 15_000L
    private const val MIN_DISTANCE_M = 100f

    /** Max age for a seed `getLastKnownLocation` fix to be considered live. */
    private const val MAX_SEED_AGE_MS = 10L * 60L * 1000L

    private val listeners = CopyOnWriteArrayList<(Location) -> Unit>()

    /** The freshest in-car fix, or null when none was acquired (yet). */
    @Volatile
    var latestFix: Location? = null
        private set

    private var locationManager: LocationManager? = null
    private var updatesActive = false
    private var sessionActive = false
    private var promptedThisSession = false
    private var lastNotifiedFix: Location? = null

    private val locationListener = LocationListener { location -> onFix(location) }

    /**
     * Begin acquiring the in-car fix. Idempotent. Call from Session `onCreate`.
     *
     * Respects the existing permission state: an already-granted location
     * permission starts updates silently; a missing one is primed in-car via
     * [CarContext.requestPermissions] at most once per session.
     */
    @Synchronized
    fun start(carContext: CarContext) {
        sessionActive = true
        if (updatesActive) return
        if (hasLocationPermission(carContext)) {
            beginUpdates(carContext)
            return
        }
        if (promptedThisSession) return
        promptedThisSession = true
        try {
            carContext.requestPermissions(
                listOf(Manifest.permission.ACCESS_FINE_LOCATION),
            ) { granted, _ ->
                if (granted.contains(Manifest.permission.ACCESS_FINE_LOCATION)) {
                    beginUpdates(carContext)
                }
                // Denied → persisted-fix fallback stays in charge; no re-prompt
                // this session.
            }
        } catch (e: Exception) {
            // A host that can't render the grant flow must never crash the
            // session — the persisted-fix fallback applies.
        }
    }

    /**
     * Stop updates and clear state. Idempotent. Call from Session `onDestroy`
     * so no location request outlives the car connection.
     */
    @Synchronized
    fun stop() {
        sessionActive = false
        promptedThisSession = false
        try {
            locationManager?.removeUpdates(locationListener)
        } catch (_: Exception) {
            // Best-effort teardown.
        }
        locationManager = null
        updatesActive = false
        latestFix = null
        lastNotifiedFix = null
        listeners.clear()
    }

    override fun addListener(listener: (Location) -> Unit) {
        listeners.addIfAbsent(listener)
    }

    override fun removeListener(listener: (Location) -> Unit) {
        listeners.remove(listener)
    }

    /**
     * Request platform location updates on the main looper. May run from the
     * permission-grant callback, so it re-checks the session is still alive.
     */
    @Synchronized
    private fun beginUpdates(carContext: CarContext) {
        if (updatesActive || !sessionActive) return
        try {
            val lm = carContext.applicationContext
                .getSystemService(Context.LOCATION_SERVICE) as? LocationManager
                ?: return
            val provider = pickProvider(lm, fineGranted(carContext)) ?: return
            seedFromLastKnown(lm)
            lm.requestLocationUpdates(
                provider,
                MIN_TIME_MS,
                MIN_DISTANCE_M,
                locationListener,
                Looper.getMainLooper(),
            )
            locationManager = lm
            updatesActive = true
        } catch (e: Exception) {
            // SecurityException (revoked between check and request) or any
            // provider fault → persisted-fix fallback, never a crash.
        }
    }

    /**
     * Best available platform provider: fused (API 31+) → GPS → network. A
     * coarse-only grant skips GPS (which needs fine).
     */
    private fun pickProvider(lm: LocationManager, fine: Boolean): String? {
        val candidates = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                add(LocationManager.FUSED_PROVIDER)
            }
            if (fine) add(LocationManager.GPS_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
        }
        return candidates.firstOrNull { provider ->
            try {
                lm.allProviders.contains(provider) && lm.isProviderEnabled(provider)
            } catch (_: Exception) {
                false
            }
        }
    }

    /** Seed [latestFix] from a recent last-known fix so the first fetch can
     *  already carry a live-ish position while the first real fix arrives. */
    private fun seedFromLastKnown(lm: LocationManager) {
        if (latestFix != null) return
        val now = System.currentTimeMillis()
        val best = lm.allProviders
            .mapNotNull { provider ->
                try {
                    lm.getLastKnownLocation(provider)
                } catch (_: Exception) {
                    null
                }
            }
            .filter { now - it.time <= MAX_SEED_AGE_MS }
            .maxByOrNull { it.time }
        if (best != null) latestFix = best
    }

    /** A new platform fix: remember it; notify screens on the first fix and
     *  after every significant move (delivered on the main looper). */
    private fun onFix(location: Location) {
        latestFix = location
        val last = lastNotifiedFix
        if (last != null && location.distanceTo(last) < SIGNIFICANT_MOVE_M) return
        lastNotifiedFix = location
        for (listener in listeners) {
            try {
                listener(location)
            } catch (_: Exception) {
                // One faulty subscriber must not starve the rest.
            }
        }
    }

    private fun hasLocationPermission(context: Context): Boolean =
        fineGranted(context) ||
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED

    private fun fineGranted(context: Context): Boolean =
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
}
