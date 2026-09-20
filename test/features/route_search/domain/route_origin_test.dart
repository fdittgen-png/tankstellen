// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/location/location_service.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/route_search/domain/route_origin.dart';

/// #4432 — "Position actuelle" was a snapshot: GPS was read once, when
/// the driver tapped the button, and the route was drawn from there for
/// as long as the sheet stayed open. These pin the replacement contract:
/// the origin is resolved afresh at submission, the RETURNED sample is
/// validated rather than trusted, and an unusable answer degrades to the
/// previous position WITH its age rather than to an unqualified claim.
class _MockLocationService extends Mock implements LocationService {}

Position _fix(
  double lat,
  double lng, {
  required DateTime at,
  double accuracy = 8,
}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: at,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  // Mid-month Wednesday, per the AppClock docstring.
  final now = DateTime(2026, 3, 11, 14, 30);
  final clock = FixedClock(now);

  // Belley (where the driver actually is) and La Tour-du-Pin (where the
  // stale fix put them) — the two points from the field report.
  const belley = LatLng(45.7594, 5.6842);
  const laTourDuPin = LatLng(45.5636, 5.4456);

  late _MockLocationService location;

  setUp(() => location = _MockLocationService());

  void answers(Position position) => when(() => location.getCurrentPosition())
      .thenAnswer((_) async => position);

  Future<ResolvedRouteOrigin> resolve({
    LatLng? stored = laTourDuPin,
    Duration storedAge = const Duration(minutes: 37),
    Duration? watchdog,
  }) =>
      resolveCurrentPositionOrigin(
        locationService: location,
        clock: clock,
        stored: stored,
        capturedAt: stored == null ? null : now.subtract(storedAge),
        watchdog: watchdog ?? kRouteOriginAcquireWatchdog,
      );

  group('acceptAsCurrentFix — thresholds, both sides (#4432)', () {
    test('a sample measured at the age limit is still current', () {
      expect(
        acceptAsCurrentFix(
          _fix(belley.latitude, belley.longitude,
              at: now.subtract(kRouteOriginMaxFixAge)),
          now,
        ),
        isTrue,
      );
    });

    test('one second past the age limit is not', () {
      expect(
        acceptAsCurrentFix(
          _fix(belley.latitude, belley.longitude,
              at: now.subtract(
                  kRouteOriginMaxFixAge + const Duration(seconds: 1))),
          now,
        ),
        isFalse,
      );
    });

    test('accuracy exactly at the limit passes, past it does not', () {
      expect(
        acceptAsCurrentFix(
          _fix(belley.latitude, belley.longitude,
              at: now, accuracy: kRouteOriginMaxAccuracyMeters),
          now,
        ),
        isTrue,
      );
      expect(
        acceptAsCurrentFix(
          _fix(belley.latitude, belley.longitude,
              at: now, accuracy: kRouteOriginMaxAccuracyMeters + 1),
          now,
        ),
        isFalse,
      );
    });

    test('an unestimated accuracy is unknown, not disqualifying', () {
      // Platforms report 0 (or a negative) when they did not estimate.
      expect(
        acceptAsCurrentFix(
          _fix(belley.latitude, belley.longitude, at: now, accuracy: 0),
          now,
        ),
        isTrue,
      );
    });

    test('a far-future timestamp is a broken clock, not a fresh fix', () {
      expect(
        acceptAsCurrentFix(
          _fix(belley.latitude, belley.longitude,
              at: now.add(const Duration(hours: 2))),
          now,
        ),
        isFalse,
      );
    });

    test('#2872 — a degenerate coordinate is never current', () {
      expect(
        acceptAsCurrentFix(_fix(45.7594, 0, at: now), now),
        isFalse,
      );
      expect(acceptAsCurrentFix(_fix(0, 0, at: now), now), isFalse);
    });
  });

  group('resolveCurrentPositionOrigin (#4432)', () {
    test('a fresh, accurate fix wins over the stored one', () async {
      answers(_fix(belley.latitude, belley.longitude, at: now));

      final origin = await resolve();

      expect(origin.freshness, RouteOriginFreshness.fresh);
      expect(origin.coords, belley);
      expect(origin.age, Duration.zero);
      expect(origin.isStale, isFalse);
    });

    test(
        'a method that returns a STALE cached sample does not pass as '
        'current', () async {
      // Android's fused provider may answer a current-location request
      // from a recent cached fix: the call returning is not evidence.
      answers(_fix(belley.latitude, belley.longitude,
          at: now.subtract(const Duration(minutes: 20))));

      final origin = await resolve();

      expect(origin.freshness, RouteOriginFreshness.stale);
      expect(origin.coords, laTourDuPin);
      expect(origin.age, const Duration(minutes: 37));
    });

    test(
        'GPS refused at search time falls back to the stored fix and '
        'reports its age', () async {
      when(() => location.getCurrentPosition()).thenThrow(
        const LocationException(message: 'Location permission denied.'),
      );

      final origin = await resolve();

      expect(origin.freshness, RouteOriginFreshness.stale);
      expect(origin.isStale, isTrue);
      expect(origin.coords, laTourDuPin);
      expect(origin.age, const Duration(minutes: 37));
    });

    test('a disabled location service degrades the same way', () async {
      when(() => location.getCurrentPosition()).thenThrow(
        const LocationException(message: 'Location services are disabled.'),
      );

      expect((await resolve()).freshness, RouteOriginFreshness.stale);
    });

    test('an acquisition past the watchdog degrades instead of hanging',
        () async {
      // Never completes. The service's own 30 s limit is preserved (see
      // kRouteOriginAcquireWatchdog); this is the outer bound for the
      // case where that limit does not fire at all.
      when(() => location.getCurrentPosition())
          .thenAnswer((_) => Completer<Position>().future);

      final origin = await resolve(
        storedAge: const Duration(minutes: 5),
        watchdog: const Duration(milliseconds: 20),
      ).timeout(const Duration(seconds: 5));

      expect(origin.freshness, RouteOriginFreshness.stale);
      expect(origin.coords, laTourDuPin);
      expect(origin.age, const Duration(minutes: 5));
    });

    test('the watchdog never shortens the platform acquisition', () {
      // #3116 — a cold high-accuracy lock on older hardware routinely
      // exceeds 10 s, so the service asks for 30 s. The route origin
      // must not quietly cut that down.
      expect(
        kRouteOriginAcquireWatchdog,
        greaterThanOrEqualTo(const Duration(seconds: 30)),
      );
    });

    test('#2872 — a degenerate refresh is rejected, not adopted', () async {
      answers(_fix(45.7594, 0, at: now));

      final origin = await resolve();

      expect(origin.freshness, RouteOriginFreshness.stale);
      expect(origin.coords, laTourDuPin);
    });

    test('#2872 — a degenerate STORED origin is not a fallback', () async {
      when(() => location.getCurrentPosition())
          .thenThrow(const LocationException(message: 'disabled'));

      final origin = await resolve(stored: const LatLng(0, 0));

      expect(origin.freshness, RouteOriginFreshness.none);
      expect(origin.coords, isNull);
    });

    test('no stored origin and no fix yields none, never a throw', () async {
      when(() => location.getCurrentPosition())
          .thenThrow(const LocationException(message: 'disabled'));

      final origin = await resolve(stored: null);

      expect(origin.freshness, RouteOriginFreshness.none);
      expect(origin.age, Duration.zero);
    });
  });

  group('captureCurrentPositionOrigin (#4432)', () {
    Future<ResolvedRouteOrigin> capture() => captureCurrentPositionOrigin(
          locationService: location,
          clock: clock,
        );

    test('a fresh fix is adopted as current', () async {
      answers(_fix(belley.latitude, belley.longitude, at: now));

      final origin = await capture();

      expect(origin.freshness, RouteOriginFreshness.fresh);
      expect(origin.coords, belley);
    });

    test(
        'a cached sample is adopted but carries its real age, so the '
        'field can say so', () async {
      answers(_fix(belley.latitude, belley.longitude,
          at: now.subtract(const Duration(minutes: 12))));

      final origin = await capture();

      expect(origin.freshness, RouteOriginFreshness.stale);
      expect(origin.coords, belley);
      expect(origin.age, const Duration(minutes: 12));
    });

    test('#2872 — a degenerate capture yields nothing to adopt', () async {
      answers(_fix(0, 5.6842, at: now));

      expect((await capture()).coords, isNull);
    });

    test('a refused permission yields nothing, never a throw', () async {
      when(() => location.getCurrentPosition()).thenThrow(
        const LocationException(message: 'Location permission denied.'),
      );

      expect((await capture()).freshness, RouteOriginFreshness.none);
    });
  });

  group('buildRouteWaypoints (#2872 / #4432)', () {
    test('marks the start as the vehicle position when asked', () {
      final waypoints = buildRouteWaypoints(
        start: belley,
        startLabel: 'Current location',
        end: const LatLng(46.2044, 6.1432),
        endLabel: 'Geneva',
        stops: const [],
        stopLabels: const [],
        originIsVehiclePosition: true,
      );

      expect(waypoints, hasLength(2));
      expect(waypoints!.first.isVehiclePosition, isTrue);
      expect(waypoints.last.isVehiclePosition, isFalse);
    });

    test('a named origin is not a vehicle position', () {
      final waypoints = buildRouteWaypoints(
        start: laTourDuPin,
        startLabel: 'La Tour-du-Pin',
        end: const LatLng(46.2044, 6.1432),
        endLabel: 'Geneva',
        stops: const [],
        stopLabels: const [],
      );

      expect(waypoints!.first.isVehiclePosition, isFalse);
    });

    test('#2872 — a degenerate anchor returns null, not a route', () {
      expect(
        buildRouteWaypoints(
          start: const LatLng(45.7594, 0),
          startLabel: 'x',
          end: const LatLng(46.2044, 6.1432),
          endLabel: 'Geneva',
          stops: const [],
          stopLabels: const [],
        ),
        isNull,
      );
      expect(
        buildRouteWaypoints(
          start: belley,
          startLabel: 'x',
          end: const LatLng(0, 0),
          endLabel: 'y',
          stops: const [],
          stopLabels: const [],
        ),
        isNull,
      );
    });

    test('#2872 — a degenerate optional stop is dropped, not fatal', () {
      final waypoints = buildRouteWaypoints(
        start: belley,
        startLabel: 'Current location',
        end: const LatLng(46.2044, 6.1432),
        endLabel: 'Geneva',
        stops: const [LatLng(45.9, 0), LatLng(45.9, 5.9)],
        stopLabels: const ['broken', 'Culoz'],
      );

      expect(waypoints, hasLength(3));
      expect(
        waypoints!.map((w) => w.label),
        ['Current location', 'Culoz', 'Geneva'],
      );
    });
  });
}
