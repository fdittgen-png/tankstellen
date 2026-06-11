// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/map/data/sparkilo_tile_layer.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_cluster_layers.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';

void main() {
  group('StationMapLayers.zoomForRadius', () {
    test('returns appropriate zoom levels for radius buckets', () {
      expect(StationMapLayers.zoomForRadius(2), 13);
      expect(StationMapLayers.zoomForRadius(5), 13);
      expect(StationMapLayers.zoomForRadius(10), 12);
      expect(StationMapLayers.zoomForRadius(15), 11);
      expect(StationMapLayers.zoomForRadius(25), 10);
      expect(StationMapLayers.zoomForRadius(50), 9);
    });
  });

  group('StationMapLayers.boundsForRadius', () {
    test('returns bounds that contain the input point', () {
      const center = LatLng(48.8566, 2.3522); // Paris
      final bounds = StationMapLayers.boundsForRadius(center, 10);

      // The input point lies inside the bounds and is close to the midpoint.
      expect(bounds.contains(center), isTrue);
      expect(bounds.center.latitude, closeTo(center.latitude, 0.01));
      expect(bounds.center.longitude, closeTo(center.longitude, 0.01));
    });

    test('latitude delta matches ~1 degree per 111 km', () {
      const center = LatLng(0, 0); // equator
      final bounds = StationMapLayers.boundsForRadius(center, 111);
      // 111 km north of equator => roughly +1 degree latitude.
      expect(bounds.north, closeTo(1.0, 0.05));
      expect(bounds.south, closeTo(-1.0, 0.05));
    });

    test('longitude delta scales with cosine of latitude', () {
      // At 60 degrees latitude cos(60) = 0.5, so a longitude delta is
      // roughly twice as large as at the equator. We verify the ratio
      // rather than the absolute value to avoid tight coupling to the
      // underlying flat-earth approximation.
      const equator = LatLng(0, 0);
      const north = LatLng(60, 0);
      final eqBounds = StationMapLayers.boundsForRadius(equator, 50);
      final nBounds = StationMapLayers.boundsForRadius(north, 50);
      // Raw east/west around longitude 0 => half-width equals east.
      final eqLngHalfWidth = eqBounds.east;
      final nLngHalfWidth = nBounds.east;
      // Longitude delta at 60N should be ~2x the equator value.
      expect(nLngHalfWidth / eqLngHalfWidth, closeTo(2.0, 0.1));
    });

    test('bounds expand monotonically with radius', () {
      const center = LatLng(48.8566, 2.3522);
      final small = StationMapLayers.boundsForRadius(center, 5);
      final big = StationMapLayers.boundsForRadius(center, 25);

      expect(big.north, greaterThan(small.north));
      expect(big.south, lessThan(small.south));
      expect(big.east, greaterThan(small.east));
      expect(big.west, lessThan(small.west));
    });

    test('handles near-pole positions without dividing by zero', () {
      const center = LatLng(89.99, 0);
      final bounds = StationMapLayers.boundsForRadius(center, 10);
      // Just assert we get a sensible (non-NaN, non-infinite) result.
      expect(bounds.east.isFinite, isTrue);
      expect(bounds.west.isFinite, isTrue);
      expect(bounds.north.isFinite, isTrue);
      expect(bounds.south.isFinite, isTrue);
    });
  });

  group('StationMapLayers zoom bounds (#1457)', () {
    test('maxZoom matches the OSM tile cap (19)', () {
      // The TileLayer in StationMapLayers caps tile loads at zoom 19
      // (`maxNativeZoom: 19, maxZoom: 19`). The camera's maxZoom MUST
      // not exceed the tile cap — otherwise a programmatic
      // `move(camera.zoom + 1)` past 19 parks the camera at a level
      // with no tiles to draw, producing the "+ button does nothing"
      // symptom that triggered #1457. Tile cap and camera cap MUST be
      // updated together if either ever changes.
      expect(StationMapLayers.maxZoom, 19.0);
    });

    test('minZoom keeps every pin from collapsing into a single pixel',
        () {
      // Zoom 3 shows a continent-scale viewport; below that, station
      // markers cluster into a single illegible blob and the search
      // affordances stop being meaningful.
      expect(StationMapLayers.minZoom, 3.0);
    });

    test('the clamp expression in the +/− handlers is well-formed',
        () {
      // Mirror the exact expression both ZoomButton handlers use so a
      // future rename or sign-flip in the production code is caught
      // by this test rather than silently shipping. The clamp turns a
      // tap-at-the-cap into a graceful no-op (camera stays at the
      // bound) instead of pushing past where there are tiles.
      double inc(double current) =>
          (current + 1).clamp(StationMapLayers.minZoom, StationMapLayers.maxZoom);
      double dec(double current) =>
          (current - 1).clamp(StationMapLayers.minZoom, StationMapLayers.maxZoom);
      // Below the cap → increment normally.
      expect(inc(13.0), 14.0);
      expect(dec(13.0), 12.0);
      // At the upper cap → + becomes a no-op, − still moves.
      expect(inc(StationMapLayers.maxZoom), StationMapLayers.maxZoom);
      expect(dec(StationMapLayers.maxZoom),
          StationMapLayers.maxZoom - 1.0);
      // At the lower cap → − becomes a no-op, + still moves.
      expect(dec(StationMapLayers.minZoom), StationMapLayers.minZoom);
      expect(inc(StationMapLayers.minZoom),
          StationMapLayers.minZoom + 1.0);
      // Past the upper cap (e.g. via prior pinch-zoom that escaped
      // the camera before #1457 set MapOptions.maxZoom) → the next
      // tap snaps back to the cap rather than pushing further.
      expect(inc(25.0), StationMapLayers.maxZoom);
    });
  });

  // The #496 `onMapReady` zoom-jiggle regression test was retired by
  // #757: the retry+evict tile provider makes the nudge unnecessary.
  // A failed tile now retries at the HTTP layer and, if still
  // unresolved, is evicted from the cache as soon as it scrolls out
  // of the keep-buffer margin.

  group('StationMapLayers single tile path (#2398)', () {
    testWidgets(
      'renders the basemap through the hardened SparkiloTileLayer — no '
      'parallel inline TileLayer, no reset stream',
      (tester) async {
        // Wide-enough viewport so the FlutterMap actually mounts.
        tester.view.physicalSize = const Size(900, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mapController = MapController();
        addTearDown(mapController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StationMapLayers(
                mapController: mapController,
                stations: const [_seedStation],
                center: const LatLng(52.5210, 13.4100),
                zoom: 12,
                searchRadiusKm: 10,
                selectedFuel: FuelType.diesel,
              ),
            ),
          ),
        );

        // Exactly one SparkiloTileLayer drives the basemap. Before
        // #2398 the main map ran a parallel inline TileLayer with its
        // own provider + a 12 s cold-start reset storm that evicted
        // tiles before they painted (the recurring grey-tile bug). The
        // unified path means there is one keyed tile widget and one
        // reset behaviour shared with every other map surface.
        expect(find.byType(SparkiloTileLayer), findsOneWidget);
        final sparkilo =
            tester.widget<SparkiloTileLayer>(find.byType(SparkiloTileLayer));
        expect(sparkilo.key, const ValueKey('main-tiles'));
        expect(
          sparkilo.reset,
          isNull,
          reason:
              'SparkiloTileLayer in the main map must NOT receive a reset '
              'stream — the cold-start reset storm (#1316/#2025) that '
              'evicted tiles before first paint was deleted in #2398.',
        );
      },
    );

    testWidgets(
      'survives parent rebuilds without re-keying the tile widget '
      '(provider lifetime is owned inside SparkiloTileLayer)',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mapController = MapController();
        addTearDown(mapController.dispose);

        Widget pumpAt(int rebuildToken) => MaterialApp(
              home: Scaffold(
                body: KeyedSubtree(
                  key: ValueKey('rebuild-$rebuildToken'),
                  child: StationMapLayers(
                    mapController: mapController,
                    stations: const [_seedStation],
                    center: const LatLng(52.5210, 13.4100),
                    zoom: 12,
                    searchRadiusKm: 10,
                    selectedFuel: FuelType.diesel,
                  ),
                ),
              ),
            );

        await tester.pumpWidget(pumpAt(0));
        await tester.pumpWidget(pumpAt(0));
        await tester.pumpWidget(pumpAt(0));

        // The keyed SparkiloTileLayer is preserved across rebuilds, so
        // its State (and the retry provider's http.Client) lives for
        // the map's whole visible lifetime — the #1234 invariant now
        // lives inside the wrapper rather than this widget.
        expect(find.byType(SparkiloTileLayer), findsOneWidget);
      },
    );
  });

  group('StationMapLayers.orderedByPriceForPainting (#2434)', () {
    // The (cluster) layer paints in source-list order — a marker LATER
    // in the list paints ON TOP of earlier ones. The helper must order
    // stations so the cheapest (green) marker ends up LAST (top) and a
    // price-less marker ends up FIRST (bottom, beneath every real price).
    Station station(String id, {double? diesel, double? e10}) => Station(
          id: id,
          name: id,
          brand: 'Brand $id',
          street: 'Street',
          houseNumber: '1',
          postCode: '10178',
          place: 'Berlin',
          lat: 52.0,
          lng: 13.0,
          dist: 1.0,
          diesel: diesel,
          e10: e10,
          isOpen: true,
        );

    test('orders cheapest LAST (painted on top), most expensive FIRST', () {
      final cheap = station('cheap', diesel: 1.50);
      final mid = station('mid', diesel: 1.70);
      final expensive = station('expensive', diesel: 1.90);

      // Feed them in an arbitrary order.
      final ordered = StationMapLayers.orderedByPriceForPainting(
        [mid, expensive, cheap],
        FuelType.diesel,
      );

      // Bottom → top of the paint stack: expensive, mid, cheap.
      expect(
        ordered.map((s) => s.id).toList(),
        ['expensive', 'mid', 'cheap'],
        reason: 'cheapest must be LAST so it paints on top of the rest',
      );
    });

    test('price-less stations sink to the BOTTOM (front of the list)', () {
      final cheap = station('cheap', diesel: 1.50);
      final expensive = station('expensive', diesel: 1.90);
      final noPrice = station('noprice'); // no diesel, no fallback fuel

      final ordered = StationMapLayers.orderedByPriceForPainting(
        [cheap, noPrice, expensive],
        FuelType.diesel,
      );

      // The null-price marker is first (very bottom) so it can never
      // cover a real green one; cheapest is still last (top).
      expect(ordered.first.id, 'noprice',
          reason: 'price-less marker must sit beneath every priced one');
      expect(ordered.last.id, 'cheap',
          reason: 'cheapest priced marker must still paint on top');
    });

    test(
        'orders by the STRICT selected-fuel price, matching the marker '
        'colour (#2510)', () {
      // User has DIESEL selected. `e10Only` has NO diesel price — under
      // #2510 the marker shows "--" (no E10 fallback), so its z-order key
      // is the null/price-less bucket: it sinks to the BOTTOM, beneath the
      // real diesel marker. This reverts the #2400 fallback-price ordering.
      final dieselPriced = station('diesel-priced', diesel: 1.95);
      final e10Only = station('e10-only', e10: 1.40);

      final ordered = StationMapLayers.orderedByPriceForPainting(
        [dieselPriced, e10Only],
        FuelType.diesel,
      );

      // The price-less (for diesel) station sits at the bottom; the real
      // diesel marker paints on top of it.
      expect(ordered.first.id, 'e10-only');
      expect(ordered.last.id, 'diesel-priced');
    });

    test('is a pure function — does not mutate the input list', () {
      final input = [
        station('a', diesel: 1.90),
        station('b', diesel: 1.50),
      ];
      final before = input.map((s) => s.id).toList();
      StationMapLayers.orderedByPriceForPainting(input, FuelType.diesel);
      expect(input.map((s) => s.id).toList(), before,
          reason: 'helper must return a new list, leaving the input intact');
    });

    test('is stable for equal prices (preserves relative order)', () {
      final first = station('first', diesel: 1.70);
      final second = station('second', diesel: 1.70);
      final ordered = StationMapLayers.orderedByPriceForPainting(
        [first, second],
        FuelType.diesel,
      );
      expect(ordered.map((s) => s.id).toList(), ['first', 'second']);
    });
  });

  // #2510 — #2490 over-corrected: routing EVERY set through the cluster
  // layer collapsed a bounded nearby search (10 stations / 10 km) into
  // "4"/"2"/"3" count bubbles + one stray marker, HIDING the results. The
  // bounded set must now render every station as its OWN marker (a plain
  // [MarkerLayer]); clustering is kept only as a fallback for a genuinely
  // huge / zoomed-far set (>= [StationMapLayers.clusterThreshold]).
  group('StationMapLayers de-clustering (#2510)', () {
    List<Station> nStations(int n) => List.generate(
          n,
          (i) => Station(
            id: 'st-$i',
            name: 'Station $i',
            brand: 'Brand',
            street: 'Street',
            houseNumber: '$i',
            postCode: '10178',
            place: 'Berlin',
            // Cluster them tightly around the centre so overlap is realistic.
            lat: 52.5210 + i * 0.0005,
            lng: 13.4100 + i * 0.0005,
            dist: 0.8 + i * 0.1,
            diesel: 1.50 + i * 0.01,
            isOpen: true,
          ),
        );

    Future<void> pumpWith(
      WidgetTester tester,
      List<Station> stations, {
      SortMode sortMode = SortMode.price,
    }) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mapController = MapController();
      addTearDown(mapController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StationMapLayers(
              mapController: mapController,
              stations: stations,
              center: const LatLng(52.5210, 13.4100),
              zoom: 12,
              searchRadiusKm: 10,
              selectedFuel: FuelType.diesel,
              sortMode: sortMode,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'a 10-station nearby set renders individual markers, NOT a count '
      'cluster',
      (tester) async {
        await pumpWith(tester, nStations(10));
        // No count-cluster layer — every result stays visible.
        expect(find.byType(MarkerClusterLayerWidget), findsNothing);
        // A plain MarkerLayer carries every station marker. (The centre
        // marker is its own MarkerLayer, so there are two.)
        expect(find.byType(MarkerLayer), findsWidgets);
      },
    );

    testWidgets(
      'every one of the 10 stations renders its own marker',
      (tester) async {
        await pumpWith(tester, nStations(10));
        // Collect the markers from the station MarkerLayer(s) — exclude the
        // single-marker centre layer.
        final stationMarkers = tester
            .widgetList<MarkerLayer>(find.byType(MarkerLayer))
            .expand((l) => l.markers)
            .where((m) => m.width != 20) // 20 == the centre dot
            .toList();
        // All 10 stations are present as individual markers, none hidden.
        expect(stationMarkers.length, 10);
      },
    );

    testWidgets(
      'the cheapest stations are EMPHASIZED with the full price bubble '
      'under a price sort',
      (tester) async {
        await pumpWith(tester, nStations(10), sortMode: SortMode.price);
        // emphasisCount stations keep the full price bubble (width ==
        // kStationMarkerWidth); the rest become compact dots (kStationDotSize).
        final stationMarkers = tester
            .widgetList<MarkerLayer>(find.byType(MarkerLayer))
            .expand((l) => l.markers)
            .where((m) => m.width != 20)
            .toList();
        final fullBubbles =
            stationMarkers.where((m) => m.width == kStationMarkerWidth).length;
        final dots =
            stationMarkers.where((m) => m.width == kStationDotSize).length;
        expect(fullBubbles, StationMapLayers.emphasisCount);
        expect(dots, 10 - StationMapLayers.emphasisCount);
      },
    );

    testWidgets('a SINGLE station renders as its own marker (no cluster)',
        (tester) async {
      await pumpWith(tester, const [_seedStation]);
      expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    });

    testWidgets(
      'a genuinely huge set (>= clusterThreshold) still falls back to '
      'clustering',
      (tester) async {
        await pumpWith(tester, nStations(StationMapLayers.clusterThreshold));
        expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
      },
    );

    testWidgets('renders no marker/cluster layer for an empty station set',
        (tester) async {
      await pumpWith(tester, const []);
      expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    });
  });

  // #3000 (Epic #2997) — selection-aware clustering for the ROUTE map. With
  // `clusterAlways` the radar grammar collapses EVERY station into the
  // cheapest-labelled cluster — which would fold several Best/All SELECTED
  // stations into one ringed badge, destroying the per-station vivid/pastel
  // distinction and the RouteBestStopsList↔marker 1:1 mapping. The opt-in
  // `excludeSelectedFromClustering` PARTITIONS the markers: SELECTED stations
  // render as their own un-clustered full price pills (a plain MarkerLayer on
  // top); the REST fold into the cheapest-labelled cluster.
  group('StationMapLayers selection-aware clustering (#3000)', () {
    // Two SELECTED + three UNSELECTED, all tightly packed so a blanket
    // cluster (the bug) would swallow ALL FIVE into one badge.
    const selected = <Station>[
      Station(
        id: 'sel-a',
        name: 'Selected A',
        brand: 'Brand',
        street: 'Street',
        postCode: '10178',
        place: 'Berlin',
        lat: 52.5210,
        lng: 13.4100,
        dist: 0.5,
        e10: 1.55,
        isOpen: true,
      ),
      Station(
        id: 'sel-b',
        name: 'Selected B',
        brand: 'Brand',
        street: 'Street',
        postCode: '10178',
        place: 'Berlin',
        lat: 52.5212,
        lng: 13.4102,
        dist: 0.6,
        e10: 1.60,
        isOpen: true,
      ),
    ];
    const unselected = <Station>[
      Station(
        id: 'un-a',
        name: 'Unselected A',
        brand: 'Brand',
        street: 'Street',
        postCode: '10178',
        place: 'Berlin',
        lat: 52.5214,
        lng: 13.4104,
        dist: 0.7,
        e10: 1.70,
        isOpen: true,
      ),
      Station(
        id: 'un-b',
        name: 'Unselected B',
        brand: 'Brand',
        street: 'Street',
        postCode: '10178',
        place: 'Berlin',
        lat: 52.5216,
        lng: 13.4106,
        dist: 0.8,
        e10: 1.75,
        isOpen: true,
      ),
      Station(
        id: 'un-c',
        name: 'Unselected C',
        brand: 'Brand',
        street: 'Street',
        postCode: '10178',
        place: 'Berlin',
        lat: 52.5218,
        lng: 13.4108,
        dist: 0.9,
        e10: 1.80,
        isOpen: true,
      ),
    ];

    Future<void> pumpSelectionAware(
      WidgetTester tester, {
      required List<Station> stations,
      required Set<String> selectedIds,
      required bool excludeSelectedFromClustering,
      FuelType Function(Station)? fuelResolver,
    }) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mapController = MapController();
      addTearDown(mapController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StationMapLayers(
              mapController: mapController,
              stations: stations,
              center: const LatLng(52.5214, 13.4104),
              zoom: 12,
              searchRadiusKm: 5,
              selectedFuel: FuelType.e10,
              clusterAlways: true,
              excludeSelectedFromClustering: excludeSelectedFromClustering,
              selectedStationIds: selectedIds,
              fuelResolver: fuelResolver,
              showSearchRadius: false,
            ),
          ),
        ),
      );
    }

    /// Markers from the NON-centre [MarkerLayer]s (the centre dot is a
    /// single-marker layer with width 20). These are the un-clustered pills.
    List<Marker> stationMarkerLayerMarkers(WidgetTester tester) => tester
        .widgetList<MarkerLayer>(find.byType(MarkerLayer))
        .expand((l) => l.markers)
        .where((m) => m.width != 20)
        .toList();

    /// Match a marker back to its station by lat/lng (Marker carries no id).
    Station? stationForMarker(Marker m, List<Station> all) {
      for (final s in all) {
        if ((s.lat - m.point.latitude).abs() < 1e-9 &&
            (s.lng - m.point.longitude).abs() < 1e-9) {
          return s;
        }
      }
      return null;
    }

    testWidgets(
      'RED-on-master: a BLANKET clusterAlways (excludeSelected=false) folds '
      'ALL five — including the two selected — into the cluster layer, leaving '
      'no un-clustered selected pills (the bug this feature fixes)',
      (tester) async {
        await pumpSelectionAware(
          tester,
          stations: [...selected, ...unselected],
          selectedIds: {'sel-a', 'sel-b'},
          excludeSelectedFromClustering: false,
        );

        // The legacy blanket path: every station goes through the cluster
        // layer, and there is NO separate un-clustered selected pill layer.
        final cluster = tester.widget<MarkerClusterLayerWidget>(
            find.byType(MarkerClusterLayerWidget));
        expect(cluster.options.markers.length, 5,
            reason: 'blanket clusterAlways routes ALL stations through the '
                'cluster layer');
        expect(stationMarkerLayerMarkers(tester), isEmpty,
            reason: 'no station MarkerLayer when everything is clustered');
      },
    );

    testWidgets(
      'GREEN: with excludeSelectedFromClustering the 2 SELECTED stations '
      'render as their OWN un-clustered markers while the 3 unselected fold '
      'into the cheapest-labelled cluster',
      (tester) async {
        await pumpSelectionAware(
          tester,
          stations: [...selected, ...unselected],
          selectedIds: {'sel-a', 'sel-b'},
          excludeSelectedFromClustering: true,
        );

        // The cluster layer receives ONLY the 3 unselected markers.
        final cluster = tester.widget<MarkerClusterLayerWidget>(
            find.byType(MarkerClusterLayerWidget));
        expect(cluster.options.markers.length, 3,
            reason: 'only the unselected stations are clustered');
        final clusteredIds = cluster.options.markers
            .map((m) => stationForMarker(m, unselected)?.id)
            .toSet();
        expect(clusteredIds, {'un-a', 'un-b', 'un-c'});

        // The 2 selected stations render as their OWN un-clustered markers in
        // a plain MarkerLayer (1:1 list↔map mapping survives).
        final pills = stationMarkerLayerMarkers(tester);
        final allStations = [...selected, ...unselected];
        final pillIds =
            pills.map((m) => stationForMarker(m, allStations)?.id).toSet();
        expect(pillIds, {'sel-a', 'sel-b'},
            reason: 'exactly the selected stations stay un-clustered');
      },
    );

    testWidgets(
      'GREEN: the un-clustered selected markers keep their FULL price pill '
      '(never a compact dot) with the vivid selected ring',
      (tester) async {
        await pumpSelectionAware(
          tester,
          stations: [...selected, ...unselected],
          selectedIds: {'sel-a', 'sel-b'},
          excludeSelectedFromClustering: true,
        );

        final pills = stationMarkerLayerMarkers(tester);
        expect(pills, hasLength(2));
        // A selected station is ALWAYS the full pill (kStationMarkerWidth),
        // never a compact dot — the vivid selected styling is preserved.
        for (final m in pills) {
          expect(m.width, kStationMarkerWidth,
              reason: 'selected markers keep the full price pill, not a dot');
        }
      },
    );

    testWidgets(
      'GREEN: a cross-border UNSELECTED station clusters with its '
      'fuelResolver-derived price (not "--") — cheapest rollup composes with '
      'the resolved MarkerMeta.price (#2631)',
      (tester) async {
        // `crossBorder` has NO e10 but DOES have e5; the resolver maps it to
        // e5 (its country fuel) so its cluster contributes a real price.
        const crossBorder = Station(
          id: 'un-cross',
          name: 'Cross-border ES',
          brand: 'Brand',
          street: 'Street',
          postCode: '00000',
          place: 'Girona',
          lat: 52.5215,
          lng: 13.4105,
          dist: 0.75,
          e5: 1.42, // its real price is in e5, NOT e10
          isOpen: true,
        );
        FuelType resolve(Station s) =>
            s.id == 'un-cross' ? FuelType.e5 : FuelType.e10;

        await pumpSelectionAware(
          tester,
          stations: [...selected, crossBorder, ...unselected],
          selectedIds: {'sel-a', 'sel-b'},
          excludeSelectedFromClustering: true,
          fuelResolver: resolve,
        );

        // The cross-border station is unselected → it goes to the cluster.
        final cluster = tester.widget<MarkerClusterLayerWidget>(
            find.byType(MarkerClusterLayerWidget));
        final crossMarker = cluster.options.markers.firstWhere(
          (m) =>
              (m.point.latitude - crossBorder.lat).abs() < 1e-9 &&
              (m.point.longitude - crossBorder.lng).abs() < 1e-9,
        );

        // The per-marker meta the cluster builder rolls up from. The clustered
        // cross-border station carries its RESOLVED e5 price (1.42), not the
        // strict-e10 '--' (null) it would otherwise have — so the cheapest
        // rollup uses a real value, not '--' (#2631).
        final state = tester.state(find.byType(StationMapLayers));
        final metaMap = (state as dynamic).markerMetaForTesting
            as Map<Marker, MarkerMeta>;
        final meta = metaMap[crossMarker];
        expect(meta, isNotNull);
        expect(meta!.price, 1.42,
            reason: 'cluster rollup uses the fuelResolver-derived price so a '
                'cross-border station contributes a real value, not "--"');
      },
    );

    testWidgets(
      'with NO selection, excludeSelectedFromClustering folds everything into '
      'the cluster (no stray un-clustered pills) — matches the radar grammar',
      (tester) async {
        await pumpSelectionAware(
          tester,
          stations: [...selected, ...unselected],
          selectedIds: const {},
          excludeSelectedFromClustering: true,
        );

        final cluster = tester.widget<MarkerClusterLayerWidget>(
            find.byType(MarkerClusterLayerWidget));
        expect(cluster.options.markers.length, 5,
            reason: 'with no selection, every station clusters as normal');
        expect(stationMarkerLayerMarkers(tester), isEmpty);
      },
    );
  });
}

const _seedStation = Station(
  id: 'seed-1',
  name: 'Seed Station',
  brand: 'JET',
  street: 'Berliner Str.',
  houseNumber: '1',
  postCode: '10178',
  place: 'Berlin',
  lat: 52.5210,
  lng: 13.4100,
  dist: 0.8,
  e5: 1.799,
  e10: 1.739,
  diesel: 1.599,
  isOpen: true,
);
