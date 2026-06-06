// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen.car

import android.content.Context
import androidx.car.app.Screen
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.PlaceListMapTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.testing.ScreenController
import androidx.car.app.testing.TestCarContext
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import de.tankstellen.tankstellen.R
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * Android Auto v1 (#2948 / epic #2946) — JVM tests for the car screens.
 *
 * Drives the real `onGetTemplate()` through androidx.car.app's
 * [ScreenController] (moveToState → getTemplatesReturned) under Robolectric,
 * with station JSON seeded into the same SharedPreferences file the Flutter
 * app writes (`HomeWidgetPreferences`). Proves the menu has both rows, the
 * list screens render N place items from a seeded key, and a missing key shows
 * the empty-state message (never crashes).
 */
@RunWith(RobolectricTestRunner::class)
class CarScreensTest {

    private lateinit var carContext: TestCarContext

    @Before
    fun setUp() {
        carContext = TestCarContext.createCarContext(
            ApplicationProvider.getApplicationContext()
        )
        // Clean slate per test — no leftover car JSON from a prior test.
        carContext.getSharedPreferences(CarStation.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().clear().commit()
    }

    private fun seed(key: String, json: String) {
        carContext.getSharedPreferences(CarStation.PREFS_NAME, Context.MODE_PRIVATE)
            .edit().putString(key, json).commit()
    }

    /**
     * Register [screen] with the test car context (so its lifecycle +
     * ScreenManager are wired) and return the template it builds. `Screen`'s
     * `onGetTemplate()` is public in androidx.car.app 1.4.0, so we call it
     * directly — the host normally invokes it on render.
     */
    private fun templateOf(screen: Screen): Template {
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)
        return screen.onGetTemplate()
    }

    private fun string(resId: Int): String = carContext.getString(resId)

    private fun twoStationsJson(): String = """
        [
          {"id":"a","name":"Aral Hauptstr","brand":"Aral","lat":52.5,"lng":13.4,
           "price":1.799,"priceText":"1.799","fuelLabel":"E10","band":"cheap",
           "bandColor":4282621761,"distanceKm":1.2,"currency":"€"},
          {"id":"b","name":"Shell Bahnhof","brand":"Shell","lat":52.6,"lng":13.5,
           "price":1.899,"priceText":"1.899","fuelLabel":"E10","band":"expensive",
           "bandColor":4291176488,"distanceKm":3.4,"currency":"€"}
        ]
    """.trimIndent()

    @Test
    fun menuScreen_hasSearchAndRadarRows() {
        val template = templateOf(MenuScreen(carContext)) as ListTemplate

        val rows = (template.singleList as ItemList).items.filterIsInstance<Row>()
        assertEquals(2, rows.size)
        assertEquals(string(R.string.car_menu_search), rows[0].title.toString())
        assertEquals(string(R.string.car_menu_radar), rows[1].title.toString())
    }

    @Test
    fun searchScreen_rendersSeededStationsAsPlaceItems() {
        seed(CarStation.SEARCH_KEY, twoStationsJson())
        val template = templateOf(SearchScreen(carContext)) as PlaceListMapTemplate

        val rows = (template.itemList as ItemList).items.filterIsInstance<Row>()
        assertEquals(2, rows.size)
        assertEquals("Aral", rows[0].title.toString())
        // Each rendered station carries a map anchor (Place metadata).
        assertNotNull(rows[0].metadata?.place)
        assertNotNull(rows[1].metadata?.place)
    }

    @Test
    fun searchScreen_missingKeyShowsNoGpsMessage() {
        // No seed → key absent. v2 SLICE 1 (#2947): the real SearchScreen is
        // live-enabled, but the real CarDataBridge has no engine under
        // Robolectric (isReady == false), so it renders the empty list with the
        // v2 no-GPS message rather than the v1 "run a search first" copy.
        val template = templateOf(SearchScreen(carContext)) as PlaceListMapTemplate

        val list = template.itemList as ItemList
        assertTrue(list.items.isEmpty())
        assertEquals(string(R.string.car_empty_no_gps), list.noItemsMessage.toString())
    }

    @Test
    fun radarScreen_rendersSeededStationsAndEmptyState() {
        // v2 PHASE-1 SLICE 2 (#2947): RadarScreen is now live-enabled, but the
        // real CarDataBridge has no engine under Robolectric (isReady == false),
        // so it renders the snapshot only — exactly as Search does without an
        // engine. Empty first: missing key shows the v2 no-GPS empty message.
        var template = templateOf(RadarScreen(carContext)) as PlaceListMapTemplate
        var list = template.itemList as ItemList
        assertTrue(list.items.isEmpty())
        assertEquals(string(R.string.car_empty_no_gps), list.noItemsMessage.toString())

        // Seed → renders the stations.
        seed(CarStation.RADAR_KEY, twoStationsJson())
        template = templateOf(RadarScreen(carContext)) as PlaceListMapTemplate
        list = template.itemList as ItemList
        assertEquals(2, list.items.filterIsInstance<Row>().size)
    }

    @Test
    fun carStation_parsesContractAndDegradesOnMalformedJson() {
        val parsed = CarStation.parse(twoStationsJson())
        assertEquals(2, parsed.size)
        assertEquals("a", parsed[0].id)
        assertEquals("Aral", parsed[0].brand)
        assertEquals(52.5, parsed[0].lat, 0.0001)
        assertEquals("1.799", parsed[0].priceText)
        assertEquals("cheap", parsed[0].band)
        assertEquals(4282621761L.toInt(), parsed[0].bandColor)
        assertTrue(parsed[0].hasLocation)

        // Malformed input never throws — empty list.
        assertTrue(CarStation.parse("not json").isEmpty())
        assertTrue(CarStation.parse("").isEmpty())
    }

    // ── Android Auto v2 SLICE 1 (#2947) — LIVE Search via the headless bridge ──

    /**
     * A fake [CarLiveSource] standing in for the real [CarDataBridge] (whose
     * FlutterEngine can't spin up under Robolectric). [ready] toggles whether a
     * live fetch is kicked; each `fetch` returns the next queued reply
     * SYNCHRONOUSLY (or null when the queue is empty), so a test can assert the
     * snapshot-first → live-second render sequence deterministically.
     */
    private class FakeLiveSource(
        var ready: Boolean = true,
    ) : CarLiveSource {
        val replies = ArrayDeque<String?>()
        var fetchCount = 0

        override val isReady: Boolean get() = ready

        override fun fetch(kind: CarFetchKind, callback: CarDataBridge.FetchCallback) {
            fetchCount++
            val json = if (replies.isEmpty()) null else replies.removeFirst()
            callback.onResult(json)
        }
    }

    /** A [SearchScreen] wired to a fake live source for deterministic tests. */
    private inner class FakeLiveSearchScreen(
        private val source: CarLiveSource,
    ) : StationListScreen(carContext) {
        override val titleRes: Int = R.string.car_search_title
        override val prefsKey: String = CarStation.SEARCH_KEY
        override val emptyMessageRes: Int = R.string.car_empty_no_gps
        override val kind: CarFetchKind = CarFetchKind.SEARCH
        override val liveFetchEnabled: Boolean = true
        override val liveSource: CarLiveSource = source
    }

    private fun rows(t: Template): List<Row> =
        ((t as PlaceListMapTemplate).itemList as ItemList).items.filterIsInstance<Row>()

    @Test
    fun liveSearch_rendersSnapshotBeforeAnyLiveResult() {
        // A live reply is queued, but the FIRST render must still show the
        // snapshot (live result lands only on the next render). Proves the
        // never-blank-first-frame contract.
        seed(CarStation.SEARCH_KEY, twoStationsJson())
        val source = FakeLiveSource().apply {
            replies.add(oneStationJson("Esso", 52.7, 13.7))
        }
        val screen = FakeLiveSearchScreen(source)
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)

        val first = rows(screen.onGetTemplate())
        assertEquals(2, first.size)
        assertEquals("Aral", first[0].title.toString())
    }

    @Test
    fun liveSearch_freshJsonReplacesSnapshotOnNextRender() {
        // Snapshot has 2; the live fetch returns 1 fresh station. The first
        // render shows the snapshot; the second (post-invalidate) shows live.
        seed(CarStation.SEARCH_KEY, twoStationsJson())
        val source = FakeLiveSource().apply {
            replies.add(oneStationJson("Esso", 52.7, 13.7))
        }
        val screen = FakeLiveSearchScreen(source)
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)

        rows(screen.onGetTemplate()) // first render kicks + caches the live list
        val second = rows(screen.onGetTemplate())
        assertEquals(1, second.size)
        assertEquals("Esso", second[0].title.toString())
    }

    @Test
    fun liveSearch_emptyLiveResultKeepsSnapshot() {
        // A null/empty live reply must NEVER blank a good snapshot.
        seed(CarStation.SEARCH_KEY, twoStationsJson())
        val source = FakeLiveSource() // empty queue → fetch yields null
        val screen = FakeLiveSearchScreen(source)
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)

        rows(screen.onGetTemplate())
        val second = rows(screen.onGetTemplate())
        assertEquals("a null live result keeps the snapshot", 2, second.size)
        assertEquals("Aral", second[0].title.toString())
    }

    @Test
    fun liveSearch_noSnapshotAndNoLiveShowsNoGpsMessage() {
        // Fresh head unit: no snapshot AND the live fetch returns null (e.g. no
        // persisted fix) → the car_empty_no_gps message, never a crash.
        val source = FakeLiveSource() // empty queue → null
        val screen = FakeLiveSearchScreen(source)
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)

        // First render (cold) shows the host spinner (loading) — no item list.
        val firstLoading = (screen.onGetTemplate() as PlaceListMapTemplate).isLoading
        assertTrue("cold start with no snapshot shows the spinner", firstLoading)

        // Second render (after the null reply) clears the spinner to the
        // no-GPS empty message.
        val list = (screen.onGetTemplate() as PlaceListMapTemplate).itemList as ItemList
        assertTrue(list.items.isEmpty())
        assertEquals(string(R.string.car_empty_no_gps), list.noItemsMessage.toString())
    }

    // ── v2 PHASE-1 SLICE 2 (#2947) — LIVE Radar via the headless bridge ───────

    /** A [RadarScreen] wired to a fake live source for deterministic tests. */
    private inner class FakeLiveRadarScreen(
        private val source: CarLiveSource,
    ) : StationListScreen(carContext) {
        override val titleRes: Int = R.string.car_radar_title
        override val prefsKey: String = CarStation.RADAR_KEY
        override val emptyMessageRes: Int = R.string.car_empty_no_gps
        override val kind: CarFetchKind = CarFetchKind.RADAR
        override val liveFetchEnabled: Boolean = true
        override val liveSource: CarLiveSource = source
    }

    @Test
    fun liveRadar_rendersSnapshotBeforeAnyLiveResult() {
        // First render must show the radar snapshot — the live result lands
        // only on the next render (never-blank-first-frame).
        seed(CarStation.RADAR_KEY, twoStationsJson())
        val source = FakeLiveSource().apply {
            replies.add(oneStationJson("Esso", 52.7, 13.7))
        }
        val screen = FakeLiveRadarScreen(source)
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)

        val first = rows(screen.onGetTemplate())
        assertEquals(2, first.size)
        assertEquals("Aral", first[0].title.toString())
    }

    @Test
    fun liveRadar_freshJsonReplacesSnapshotOnNextRender() {
        seed(CarStation.RADAR_KEY, twoStationsJson())
        val source = FakeLiveSource().apply {
            replies.add(oneStationJson("Esso", 52.7, 13.7))
        }
        val screen = FakeLiveRadarScreen(source)
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)

        rows(screen.onGetTemplate()) // first render kicks + caches the live list
        val second = rows(screen.onGetTemplate())
        assertEquals(1, second.size)
        assertEquals("Esso", second[0].title.toString())
    }

    @Test
    fun liveRadar_emptyLiveResultKeepsSnapshot() {
        seed(CarStation.RADAR_KEY, twoStationsJson())
        val source = FakeLiveSource() // empty queue → fetch yields null
        val screen = FakeLiveRadarScreen(source)
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)

        rows(screen.onGetTemplate())
        val second = rows(screen.onGetTemplate())
        assertEquals("a null live radar result keeps the snapshot", 2, second.size)
        assertEquals("Aral", second[0].title.toString())
    }

    @Test
    fun liveRadar_noSnapshotAndNoLiveShowsNoGpsMessage() {
        // Fresh head unit: no radar snapshot AND the live fetch returns null →
        // the car_empty_no_gps message, never a crash.
        val source = FakeLiveSource() // empty queue → null
        val screen = FakeLiveRadarScreen(source)
        ScreenController(screen).moveToState(Lifecycle.State.CREATED)

        val firstLoading = (screen.onGetTemplate() as PlaceListMapTemplate).isLoading
        assertTrue("cold start with no snapshot shows the spinner", firstLoading)

        val list = (screen.onGetTemplate() as PlaceListMapTemplate).itemList as ItemList
        assertTrue(list.items.isEmpty())
        assertEquals(string(R.string.car_empty_no_gps), list.noItemsMessage.toString())
    }

    @Test
    fun realRadarScreen_isLiveEnabled_andStaysOnSnapshotWithoutAnEngine() {
        // The REAL RadarScreen opts into the live bridge (slice 2). With no
        // engine under Robolectric (isReady == false) it renders the snapshot
        // and never crashes — the live wiring is exercised by the fake above.
        seed(CarStation.RADAR_KEY, twoStationsJson())
        val template = templateOf(RadarScreen(carContext)) as PlaceListMapTemplate
        assertEquals(2, rows(template).size)
    }

    // ── v2 PHASE-1 SLICE 3 (#2947) — the address subtitle, lock-step ──────────

    @Test
    fun addressSubtitle_rendersOnARow() {
        seed(CarStation.SEARCH_KEY, addressStationJson())
        val template = templateOf(SearchScreen(carContext)) as PlaceListMapTemplate
        val row = rows(template).first()

        // The address is one of the row's secondary text lines.
        val texts = row.texts.map { it.toString() }
        assertTrue(
            "the address subtitle renders on the row: $texts",
            texts.any { it.contains("Hauptstr. 1") && it.contains("Berlin") },
        )
    }

    @Test
    fun carStation_parsesAddress_andOldAddresslessSnapshotDoesNotCrash() {
        // Fresh JSON carries the address.
        val withAddr = CarStation.parse(addressStationJson())
        assertEquals(1, withAddr.size)
        assertEquals("Hauptstr. 1, 10115 Berlin", withAddr[0].address)

        // BACK-COMPAT: an OLD address-less snapshot (written before slice 3)
        // parses fine, defaulting address to "" — never crashes.
        val oldJson = """
            [
              {"id":"a","name":"Aral","brand":"Aral","lat":52.5,"lng":13.4,
               "price":1.799,"priceText":"1.799","fuelLabel":"E10","band":"cheap",
               "bandColor":4282621761,"distanceKm":1.2,"currency":"€"}
            ]
        """.trimIndent()
        val old = CarStation.parse(oldJson)
        assertEquals(1, old.size)
        assertEquals("", old[0].address)
    }

    private fun oneStationJson(brand: String, lat: Double, lng: Double): String = """
        [
          {"id":"x","name":"$brand X","brand":"$brand","lat":$lat,"lng":$lng,
           "price":1.749,"priceText":"1.749","fuelLabel":"E10","band":"cheap",
           "bandColor":4282621761,"distanceKm":2.1,"currency":"€"}
        ]
    """.trimIndent()

    private fun addressStationJson(): String = """
        [
          {"id":"a","name":"Aral Hauptstr","brand":"Aral",
           "address":"Hauptstr. 1, 10115 Berlin","lat":52.5,"lng":13.4,
           "price":1.799,"priceText":"1.799","fuelLabel":"E10","band":"cheap",
           "bandColor":4282621761,"distanceKm":1.2,"currency":"€"}
        ]
    """.trimIndent()
}
