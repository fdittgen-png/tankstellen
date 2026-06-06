// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.shadows.ShadowLooper

/**
 * Android Auto v2 SLICE 1 (#2947) — the bridge's channel / lifecycle contract,
 * as far as Robolectric allows.
 *
 * The real [CarDataBridge] wraps a [io.flutter.embedding.engine.FlutterEngine]
 * that cannot spin up under Robolectric (no native Flutter shell), so these
 * pin the behaviour reachable WITHOUT a live engine: the not-ready guard, the
 * RADAR short-circuit (slice 1 only wires SEARCH live), and the [CarFetchKind]
 * contract. The full snapshot-first → live-second render flow (which DOES need
 * a working live source) is covered by `CarScreensTest` via a fake [CarLiveSource].
 */
@RunWith(RobolectricTestRunner::class)
class CarDataBridgeTest {

    @Test
    fun isReady_isFalse_whenNoEngineCreated() {
        // No create() under Robolectric (no FlutterEngine), so the bridge is
        // never ready — the screens fall back to their snapshot.
        CarDataBridge.destroy() // ensure a clean, torn-down state
        assertFalse(CarDataBridge.isReady)
    }

    @Test
    fun fetch_returnsNull_whenNotReady() {
        CarDataBridge.destroy()
        var called = false
        var result: String? = "sentinel"
        CarDataBridge.fetch(CarFetchKind.SEARCH) { json ->
            called = true
            result = json
        }
        // The not-ready path posts the null callback on the main thread.
        ShadowLooper.idleMainLooper()
        assertEquals(true, called)
        assertNull(result)
    }

    @Test
    fun fetch_returnsNull_forRadarKind_evenIfAsked() {
        // SLICE 1 wires only SEARCH live; a RADAR fetch must short-circuit to
        // null so Radar keeps its v1 snapshot (slice 2 wires its live fetch).
        CarDataBridge.destroy()
        var result: String? = "sentinel"
        CarDataBridge.fetch(CarFetchKind.RADAR) { json -> result = json }
        ShadowLooper.idleMainLooper()
        assertNull(result)
    }

    @Test
    fun destroy_isIdempotent_andSafeWhenNeverCreated() {
        // Tearing down a bridge that was never created (or twice) must not throw
        // — the Session onDestroy calls this unconditionally.
        CarDataBridge.destroy()
        CarDataBridge.destroy()
        assertFalse(CarDataBridge.isReady)
    }

    @Test
    fun carFetchKind_hasSearchAndRadar() {
        assertEquals(2, CarFetchKind.entries.size)
        assertEquals(CarFetchKind.SEARCH, CarFetchKind.valueOf("SEARCH"))
        assertEquals(CarFetchKind.RADAR, CarFetchKind.valueOf("RADAR"))
    }

    @Test
    fun fetchCallback_funInterface_isInvokable() {
        // The FetchCallback SAM is the bridge↔screen contract — assert it can be
        // built + invoked (the screens pass a lambda).
        var seen: String? = null
        val cb = CarDataBridge.FetchCallback { json -> seen = json }
        cb.onResult("[]")
        assertEquals("[]", seen)
    }
}
