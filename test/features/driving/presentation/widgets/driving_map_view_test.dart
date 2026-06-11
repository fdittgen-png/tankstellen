// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_map_view.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Station _station({
  required String id,
  double lat = 52.0,
  double lng = 13.0,
  double dist = 1.0,
  double? e10 = 1.799,
  double? diesel = 1.659,
}) {
  return Station(
    id: id,
    name: id,
    brand: 'BRAND',
    street: 'Street',
    houseNumber: '1',
    postCode: '10000',
    place: 'Place',
    lat: lat,
    lng: lng,
    dist: dist,
    e5: 1.859,
    e10: e10,
    diesel: diesel,
    isOpen: true,
  );
}

void main() {
  group('DrivingMapView.computeCenter', () {
    test('returns the geographic centroid of the given stations', () {
      final stations = [
        _station(id: 'a', lat: 50.0, lng: 10.0),
        _station(id: 'b', lat: 52.0, lng: 12.0),
      ];

      final center = DrivingMapView.computeCenter(stations);

      expect(center.latitude, closeTo(51.0, 1e-9));
      expect(center.longitude, closeTo(11.0, 1e-9));
    });

    test('handles a single station', () {
      final center = DrivingMapView.computeCenter([
        _station(id: 'a', lat: 48.137, lng: 11.575),
      ]);
      expect(center.latitude, closeTo(48.137, 1e-9));
      expect(center.longitude, closeTo(11.575, 1e-9));
    });
  });

  group('DrivingMapView.computePriceRange', () {
    test('returns (min, max) across stations that price the active fuel', () {
      final stations = [
        _station(id: 'a', e10: 1.799),
        _station(id: 'b', e10: 1.659),
        _station(id: 'c', e10: 1.749),
      ];

      final (min, max) = DrivingMapView.computePriceRange(
        stations,
        FuelType.e10,
      );

      expect(min, closeTo(1.659, 1e-9));
      expect(max, closeTo(1.799, 1e-9));
    });

    test('returns (0, 0) when no station has a price for the active fuel', () {
      final stations = [
        _station(id: 'a', e10: null, diesel: 1.6),
        _station(id: 'b', e10: null, diesel: 1.7),
      ];

      final (min, max) = DrivingMapView.computePriceRange(
        stations,
        FuelType.e10,
      );

      expect(min, 0);
      expect(max, 0);
    });

    test('ignores stations missing the active fuel price', () {
      final stations = [
        _station(id: 'a', e10: null),
        _station(id: 'b', e10: 1.50),
      ];

      final (min, max) = DrivingMapView.computePriceRange(
        stations,
        FuelType.e10,
      );

      expect(min, closeTo(1.50, 1e-9));
      expect(max, closeTo(1.50, 1e-9));
    });
  });

  group('DrivingMapView adopts the shared stack (#3002, Epic #2997)', () {
    Future<void> pumpView(
      WidgetTester tester, {
      required MapController controller,
      required List<Station> stations,
      void Function(Station)? onMarkerTap,
      VoidCallback? onInteraction,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: DrivingMapView(
                mapController: controller,
                stations: stations,
                selectedFuel: FuelType.e10,
                onMarkerTap: onMarkerTap ?? (_) {},
                onInteraction: onInteraction ?? () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'renders the shared StationMapLayers, not a bespoke MarkerLayer',
      (tester) async {
        final controller = MapController();
        addTearDown(controller.dispose);
        await pumpView(
          tester,
          controller: controller,
          stations: [
            _station(id: 'a', lat: 52.0, lng: 13.0),
            _station(id: 'b', lat: 52.1, lng: 13.1),
          ],
        );

        // Driving now consumes the ONE shared map stack.
        expect(find.byType(StationMapLayers), findsOneWidget);
      },
    );

    testWidgets('passes the driving marker variant + NO clustering', (
      tester,
    ) async {
      final controller = MapController();
      addTearDown(controller.dispose);
      await pumpView(
        tester,
        controller: controller,
        stations: [
          _station(id: 'a', lat: 52.0, lng: 13.0),
          _station(id: 'b', lat: 52.1, lng: 13.1),
        ],
      );

      final layers = tester.widget<StationMapLayers>(
        find.byType(StationMapLayers),
      );
      // The big driver-legible marker variant.
      expect(layers.markerVariant, StationMarkerVariant.driving);
      // Driving shows few stations and needs immediate tap-to-open-sheet —
      // never clustered.
      expect(layers.clusterAlways, isFalse);
    });

    testWidgets('a marker tap dispatches onMarkerTap (opens the sheet), '
        'NOT a navigation push', (tester) async {
      final controller = MapController();
      addTearDown(controller.dispose);
      Station? tappedStation;
      var interacted = false;
      final stations = [
        _station(id: 'a', lat: 52.0, lng: 13.0),
        _station(id: 'b', lat: 52.1, lng: 13.1),
      ];
      await pumpView(
        tester,
        controller: controller,
        stations: stations,
        onMarkerTap: (s) => tappedStation = s,
        onInteraction: () => interacted = true,
      );

      final layers = tester.widget<StationMapLayers>(
        find.byType(StationMapLayers),
      );
      // The shared layer surfaces a station-id tap hook; driving wires it to
      // its onMarkerTap (which shows DrivingStationSheet), not a GoRouter push.
      expect(layers.onStationTap, isNotNull);
      layers.onStationTap!('a');
      expect(tappedStation?.id, 'a');
      // The same tap also keeps the auto-lock timer alive.
      expect(interacted, isTrue);
    });

    testWidgets('keeps the restricted driving interaction (no pinch zoom)', (
      tester,
    ) async {
      final controller = MapController();
      addTearDown(controller.dispose);
      await pumpView(
        tester,
        controller: controller,
        stations: [_station(id: 'a', lat: 52.0, lng: 13.0)],
      );

      final layers = tester.widget<StationMapLayers>(
        find.byType(StationMapLayers),
      );
      final flags = layers.interactionOptions!.flags;
      // Drag + fling + double-tap-zoom are allowed; pinch/rotate are not.
      expect(flags & InteractiveFlag.drag, isNot(0));
      expect(flags & InteractiveFlag.flingAnimation, isNot(0));
      expect(flags & InteractiveFlag.doubleTapZoom, isNot(0));
      expect(flags & InteractiveFlag.pinchZoom, 0);
    });
  });
}
