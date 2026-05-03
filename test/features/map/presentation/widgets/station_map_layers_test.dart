import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/map/data/retry_network_tile_provider.dart';
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

  // The #496 `onMapReady` zoom-jiggle regression test was retired by
  // #757: the retry+evict tile provider makes the nudge unnecessary.
  // A failed tile now retries at the HTTP layer and, if still
  // unresolved, is evicted from the cache as soon as it scrolls out
  // of the keep-buffer margin. The structural assertion that
  // `MapOptions.onMapReady != null` no longer holds and should not
  // be resurrected — re-adding the jiggle would cancel in-flight
  // retries (the #709 regression that was itself rolled back).

  group('StationMapLayers tile provider stability (#1234)', () {
    testWidgets(
      'TileLayer keeps the same RetryNetworkTileProvider instance across '
      'parent rebuilds — does NOT re-instantiate on every build',
      (tester) async {
        // Wide-enough viewport so the FlutterMap actually mounts.
        tester.view.physicalSize = const Size(900, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mapController = MapController();
        addTearDown(mapController.dispose);

        // Helper to drive a fresh build with a different external key
        // (the kind of trivial rebuild that, before #1234, churned the
        // tile provider on every parent setState).
        Widget pumpAt(int rebuildToken) => MaterialApp(
              home: Scaffold(
                body: KeyedSubtree(
                  // ValueKey changes only the OUTER subtree wrapper —
                  // it's a no-op on StationMapLayers' own State, which
                  // is what we want. We only want the parent build()
                  // to run again.
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

        TileLayer findTileLayer() => tester.widget<TileLayer>(
              find.byType(TileLayer),
            );

        final providerOnFirstBuild = findTileLayer().tileProvider;
        expect(
          providerOnFirstBuild,
          isA<RetryNetworkTileProvider>(),
          reason:
              'StationMapLayers must wire RetryNetworkTileProvider into '
              'the TileLayer (not the default NetworkTileProvider) — the '
              '#757 retry policy depends on it.',
        );

        // Rebuild via a parent setState analogue. Same widget instance
        // (same State), but the TileLayer widget is re-instantiated.
        // The State must hand it the SAME tile provider instance.
        await tester.pumpWidget(pumpAt(0));
        await tester.pumpWidget(pumpAt(0));
        await tester.pumpWidget(pumpAt(0));

        final providerAfterRebuilds = findTileLayer().tileProvider;
        expect(
          identical(providerOnFirstBuild, providerAfterRebuilds),
          isTrue,
          reason:
              'TileLayer.tileProvider must remain identical across '
              'StationMapLayers parent rebuilds. Recreating the provider '
              'every build (the prior bug, #1234) churned http.Client '
              'instances and produced cold-start grey tiles. Holding it '
              'in State (initState/dispose) is the fix.',
        );
      },
    );

    testWidgets(
      'TileLayer.reset stream is wired so a settled-camera kick can drop '
      'tiles fetched against a degenerate viewport',
      (tester) async {
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

        final layer = tester.widget<TileLayer>(find.byType(TileLayer));
        expect(
          layer.reset,
          isNotNull,
          reason:
              'TileLayer.reset must be wired so the post-first-frame '
              'kick can force a tile reload — covers the cold-start case '
              'where TileLayer captured a degenerate viewport before the '
              'MapController settled (#1234).',
        );
      },
    );
  });

  group('StationMapLayers cold-start tile reset window (#1316 phase 3)', () {
    testWidgets(
      'reset stream re-fires on programmatic camera moves during the '
      'cold-start window so TileLayer reloads after `fitCamera` settles',
      (tester) async {
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

        // The initState first-paint reset fired during pumpWidget's
        // post-frame stage, so a listener attached now misses it
        // (broadcast streams do not replay). That part is already
        // covered by the existing "TileLayer.reset stream is wired"
        // test above. Here we focus on the phase-3 invariant: a
        // programmatic camera move during the cold-start window must
        // produce at least one fresh reset.
        final reset = tester.widget<TileLayer>(find.byType(TileLayer)).reset!;
        final emissions = <void>[];
        final sub = reset.listen(emissions.add);
        addTearDown(sub.cancel);

        // Simulate `NearbyMapView`s post-frame `fitCamera` arriving
        // AFTER the initState reset already fired. Before #1316
        // phase 3, this left TileLayer with whatever tile range it
        // computed at the bootstrap camera — typically only a handful
        // of tiles around the (possibly stale) initial centre. Now
        // the cold-start subscriber must catch this event and
        // re-emit reset so TileLayer reloads against the settled
        // camera.
        mapController.move(const LatLng(43.4500, 3.4900), 12);
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          emissions,
          isNotEmpty,
          reason:
              '#1316 — programmatic camera moves during the cold-start '
              'window must re-emit on the reset stream so TileLayer '
              'recomputes its visible-tile set against the settled '
              'camera. Previously the initState reset fired against the '
              'bootstrap camera; if `fitCamera` (or any controller move) '
              'arrived later, TileLayer kept the small tile set from '
              'the bootstrap camera, leaving most of the map grey.',
        );
      },
    );

    testWidgets(
      'after the cold-start window, programmatic moves no longer trigger '
      'extra resets (steady-state pans must not pop tiles)',
      (tester) async {
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

        final reset = tester.widget<TileLayer>(find.byType(TileLayer)).reset!;
        final emissions = <void>[];
        final sub = reset.listen(emissions.add);
        addTearDown(sub.cancel);

        // Burn past the 3-second cold-start window.
        await tester.pump(const Duration(seconds: 4));
        final baseline = emissions.length;

        // Programmatic move AFTER the window — must not re-emit on
        // the reset stream. TileLayer has its own load-on-event
        // handling for steady-state pans; gratuitous resets pop the
        // visible tiles back to their loading state.
        mapController.move(const LatLng(43.4500, 3.4900), 12);
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          emissions.length,
          baseline,
          reason:
              'After [_coldStartResetWindow] elapses, programmatic '
              'camera moves must no longer fire the reset stream — '
              'TileLayer\'s normal event-driven load path handles '
              'steady-state pans and an extra reset would briefly '
              'wipe the visible tiles. The cold-start subscription '
              'must self-cancel.',
        );
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
