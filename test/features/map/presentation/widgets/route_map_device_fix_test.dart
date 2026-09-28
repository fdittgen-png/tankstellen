// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/position_fix_policy.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_map_view.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #4432 — checkpoint 2, "map correctness", on the production path.
///
/// The field report's green dot near Belley was the camera centre (the
/// bounding box of the found stations), not a GPS measurement. These pin
/// the three separate map inputs — camera target, route endpoints,
/// device fix — plus the device fix's own lifecycle: fed only by a
/// validated sample from the SHARED position stream, dropped when it
/// ages out, and released when the map is paused or disposed. The fake
/// sits under `GeolocatorWrapper.getPositionStream`, so the real shared
/// multiplexer (and its replay-to-late-joiner) is exercised too.
class _FakeGeolocator extends GeolocatorWrapper {
  StreamController<Position>? upstream;
  int opens = 0;
  int cancels = 0;

  bool get isOpen => upstream != null;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    opens++;
    // Released by the shared source's cancel — which is what these
    // tests assert — so it is never closed here.
    // ignore: close_sinks
    final ctl = StreamController<Position>(onCancel: () {
      cancels++;
      upstream = null;
    });
    upstream = ctl;
    return ctl.stream;
  }
}

class _StepClock implements AppClock {
  _StepClock(this.instant);
  DateTime instant;
  @override
  DateTime now() => instant;
}

Position _fix(LatLng at, DateTime measured, {double accuracy = 15}) =>
    Position(
      latitude: at.latitude,
      longitude: at.longitude,
      timestamp: measured,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Station _station(String id, double lat, double lng) => Station(
      id: id,
      name: id,
      brand: 'B',
      street: '',
      postCode: '',
      place: 'P',
      lat: lat,
      lng: lng,
      dist: 1,
      e10: 1.7,
      isOpen: true,
    );

void main() {
  // Three deliberately different points (the acceptance fixture).
  const routeStart = LatLng(45.7594, 5.6842); // Belley
  const destination = LatLng(46.2044, 6.1432); // Geneva
  const deviceFix = LatLng(45.8120, 5.7310); // where the car really is
  // Two stations whose bounding-box centre is (46.00, 5.85).
  final stations = [
    _station('s1', 45.95, 5.95),
    _station('s2', 46.05, 5.75),
  ];
  const boundsCentre = LatLng(46.00, 5.85);

  final t0 = DateTime(2026, 3, 11, 14, 30);
  late _StepClock clock;
  late _FakeGeolocator geo;

  setUp(() {
    clock = _StepClock(t0);
    geo = _FakeGeolocator();
  });

  RouteSearchResult result({
    int revision = 7,
    bool currentPosition = true,
    List<Station>? found,
    bool partial = false,
    RouteInfo? route,
  }) {
    return RouteSearchResult(
      route: route ??
          const RouteInfo(
            geometry: [routeStart, LatLng(45.95, 5.85), destination],
            distanceKm: 70,
            durationMinutes: 60,
            samplePoints: [routeStart, destination],
          ),
      stations: [for (final s in found ?? stations) FuelStationResult(s)],
      isPartial: partial,
      request: RouteSearchRequest(
        revision: revision,
        waypoints: [
          RouteWaypoint(
            lat: routeStart.latitude,
            lng: routeStart.longitude,
            label: 'Current location',
            isVehiclePosition: currentPosition,
          ),
          RouteWaypoint(
            lat: destination.latitude,
            lng: destination.longitude,
            label: 'Genève',
          ),
        ],
        fuelType: FuelType.e10,
        searchRadiusKm: 5,
        strategyType: RouteSearchStrategyType.uniform,
        originCapturedAt: t0,
      ),
    );
  }

  Future<ValueNotifier<RouteSearchResult?>> pumpMap(
    WidgetTester tester,
    RouteSearchResult initial,
  ) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    final shown = ValueNotifier<RouteSearchResult?>(initial);
    addTearDown(shown.dispose);
    final test = standardTestOverrides();
    when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
    await pumpApp(
      tester,
      SizedBox(
        width: 800,
        height: 1000,
        child: ValueListenableBuilder<RouteSearchResult?>(
          valueListenable: shown,
          builder: (_, value, _) => value == null
              ? const SizedBox.shrink()
              : RouteMapView(
                  routeResult: value,
                  selectedFuel: FuelType.e10,
                  mapController: controller,
                ),
        ),
      ),
      overrides: [
        ...test.overrides,
        geolocatorWrapperProvider.overrideWithValue(geo),
        appClockProvider.overrideWithValue(clock),
      ],
    );
    return shown;
  }

  Iterable<Marker> markers(WidgetTester tester) => tester
      .widgetList<MarkerLayer>(find.byType(MarkerLayer))
      .expand((layer) => layer.markers);

  Marker? keyed(WidgetTester tester, String key) {
    final hits = markers(tester).where((m) => m.key == ValueKey(key));
    return hits.isEmpty ? null : hits.single;
  }

  Future<void> emit(WidgetTester tester, Position p) async {
    geo.upstream!.add(p);
    await tester.pump(); // deliver through the shared multiplexer
    await tester.pump(); // rebuild the layer
  }

  /// The shared source's cancel chain awaits a broadcast subscription's
  /// cancel, whose already-completed future lives in the ROOT zone, so
  /// fake-async pumps alone never finish it. Give real time one turn.
  Future<void> settleCancel(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }

  group('three separate inputs (#4432)', () {
    testWidgets(
        'device fix, route start and bounds centre each get their own '
        'marker — and nothing is drawn at the bounds centre', (tester) async {
      await pumpMap(tester, result());
      await emit(tester, _fix(deviceFix, t0));

      expect(keyed(tester, 'device-fix-marker')?.point, deviceFix);
      expect(keyed(tester, 'route-start-marker')?.point, routeStart);
      expect(keyed(tester, 'route-destination-marker')?.point, destination);
      // The camera target really is the bounds centre (the bounds are
      // epsilon-padded, #3488)…
      final layers =
          tester.widget<StationMapLayers>(find.byType(StationMapLayers));
      expect(layers.center.latitude, closeTo(boundsCentre.latitude, 1e-3));
      expect(layers.center.longitude, closeTo(boundsCentre.longitude, 1e-3));
      expect(layers.originMarker, isNull);
      // …and no marker of any kind claims it.
      expect(
        markers(tester).where((m) =>
            (m.point.latitude - layers.center.latitude).abs() < 1e-2 &&
            (m.point.longitude - layers.center.longitude).abs() < 1e-2),
        isEmpty,
      );
    });

    testWidgets('no accepted fix means no device marker at all',
        (tester) async {
      await pumpMap(tester, result());

      expect(geo.isOpen, isTrue, reason: 'the listener is subscribed');
      expect(keyed(tester, 'device-fix-marker'), isNull);
      expect(find.bySemanticsLabel('Your current position'), findsNothing);
    });

    testWidgets('a replayed / cached fix older than the bound is not drawn',
        (tester) async {
      await pumpMap(tester, result());
      await emit(
          tester,
          _fix(deviceFix,
              t0.subtract(kRouteOriginMaxFixAge + const Duration(seconds: 5))));

      expect(keyed(tester, 'device-fix-marker'), isNull);
    });

    testWidgets('a too-imprecise fix is not drawn', (tester) async {
      await pumpMap(tester, result());
      await emit(tester,
          _fix(deviceFix, t0, accuracy: kRouteOriginMaxAccuracyMeters * 4));

      expect(keyed(tester, 'device-fix-marker'), isNull);
    });

    testWidgets('the device marker is labelled for screen readers',
        (tester) async {
      await pumpMap(tester, result());
      // Inside the framed viewport — MarkerLayer builds only visible
      // markers' children.
      await emit(tester, _fix(const LatLng(46.02, 5.80), t0));

      expect(find.bySemanticsLabel('Your current position'), findsOneWidget);
    });

    testWidgets('a fixed-origin route opens no GPS listener and claims no '
        'position', (tester) async {
      await pumpMap(tester, result(currentPosition: false));

      expect(geo.opens, 0);
      expect(keyed(tester, 'device-fix-marker'), isNull);
    });
  });

  group('foreground listener freshness + lifecycle (#4432)', () {
    testWidgets('the marker follows newer fixes and disappears once the '
        'last one ages out', (tester) async {
      await pumpMap(tester, result());
      await emit(tester, _fix(deviceFix, t0));
      expect(keyed(tester, 'device-fix-marker')?.point, deviceFix);

      const moved = LatLng(45.8300, 5.7600);
      clock.instant = t0.add(const Duration(seconds: 30));
      await emit(tester, _fix(moved, clock.instant));
      expect(keyed(tester, 'device-fix-marker')?.point, moved);

      // Nothing newer for longer than the bound: the claim is withdrawn.
      clock.instant = t0.add(
          const Duration(seconds: 30) + kRouteOriginMaxFixAge +
              const Duration(seconds: 1));
      await tester.pump(kRouteOriginMaxFixAge + const Duration(seconds: 1));
      expect(keyed(tester, 'device-fix-marker'), isNull);
    });

    testWidgets('disposing the map cancels the subscription', (tester) async {
      final shown = await pumpMap(tester, result());
      expect(geo.isOpen, isTrue);

      shown.value = null; // the route surface leaves the tree
      await tester.pump();
      await settleCancel(tester);

      expect(geo.isOpen, isFalse);
      expect(geo.cancels, 1);
    });

    testWidgets('paused / hidden release the stream; resume re-subscribes',
        (tester) async {
      await pumpMap(tester, result());
      expect(geo.opens, 1);

      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(geo.isOpen, isTrue,
          reason: 'inactive is still visible (a shade swipe)');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settleCancel(tester);
      expect(geo.isOpen, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settleCancel(tester);
      expect(geo.isOpen, isTrue);
      expect(geo.opens, 2);
    });

    testWidgets('a fix older than the bound on resume is dropped at once',
        (tester) async {
      await pumpMap(tester, result());
      await emit(tester, _fix(deviceFix, t0));
      expect(keyed(tester, 'device-fix-marker'), isNotNull);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settleCancel(tester);

      clock.instant = t0.add(const Duration(minutes: 15));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(keyed(tester, 'device-fix-marker'), isNull);
    });
  });

  group('revision-aware framing (#4432)', () {
    LatLngBounds? fitBounds(WidgetTester tester) => tester
        .widget<StationMapLayers>(find.byType(StationMapLayers))
        .cameraFitBounds;

    testWidgets('partial → final of the SAME revision holds the camera',
        (tester) async {
      final shown = await pumpMap(
        tester,
        result(partial: true, found: [stations.first]),
      );
      final before = fitBounds(tester);

      // Same submission, more stations streamed in, then the final.
      final same = shown.value!;
      shown.value = RouteSearchResult(
        route: same.route,
        stations: [for (final s in stations) FuelStationResult(s)],
        request: same.request,
      );
      await tester.pump();

      expect(fitBounds(tester), before);
    });

    testWidgets('a NEW revision reframes the camera', (tester) async {
      final shown = await pumpMap(tester, result(revision: 7));
      final before = fitBounds(tester);

      shown.value = result(
        revision: 8,
        found: [_station('far', 46.60, 6.60), _station('far2', 46.70, 6.50)],
      );
      await tester.pump();

      final after = fitBounds(tester)!;
      expect(after, isNot(before));
      expect(after.contains(const LatLng(46.60, 6.60)), isTrue);
    });
  });
}
