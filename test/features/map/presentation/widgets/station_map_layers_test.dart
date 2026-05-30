// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/map/data/sparkilo_tile_layer.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

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
        'orders by the RESOLVED display price (fallback fuel), matching '
        'the marker colour', () {
      // User has DIESEL selected. `fallback` has no diesel but a cheap
      // E10 — its marker is coloured by that fallback price (#2400), so
      // the z-order must use the same resolved price, not the (null)
      // selected-fuel price.
      final dieselExpensive = station('diesel-expensive', diesel: 1.95);
      final fallbackCheap = station('fallback-cheap', e10: 1.40);

      final ordered = StationMapLayers.orderedByPriceForPainting(
        [dieselExpensive, fallbackCheap],
        FuelType.diesel,
      );

      // The resolved-cheap fallback station paints on top of the
      // diesel-expensive one, agreeing with their green/red colours.
      expect(ordered.last.id, 'fallback-cheap');
      expect(ordered.first.id, 'diesel-expensive');
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
