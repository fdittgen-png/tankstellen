import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

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

  group('StationMapLayers onMapReady nudge (#496)', () {
    testWidgets(
        'FlutterMap is configured with an onMapReady callback so the '
        'tile layer gets re-triggered once the controller is attached',
        (tester) async {
      final controller = MapController();
      await pumpApp(
        tester,
        SizedBox(
          width: 400,
          height: 400,
          child: StationMapLayers(
            mapController: controller,
            stations: const [],
            center: const LatLng(48.8566, 2.3522),
            zoom: 12,
            searchRadiusKm: 10,
            selectedFuel: FuelType.e10,
          ),
        ),
      );

      // The regression from #496 is that MapOptions.onMapReady was null
      // and the initState-based nudge in MapScreen fires before the
      // controller attaches. Asserting onMapReady != null locks in the
      // fix — if someone removes it, this test fails and the tiles go
      // blank again on cold visits to the Carte tab.
      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(flutterMap.options.onMapReady, isNotNull,
          reason: 'MapOptions.onMapReady must be set so the TileLayer '
              'retriggers its viewport fetch once the controller '
              'attaches — otherwise the map renders blank white tiles '
              'until the user pans (#496)');
    });
  });
}
