// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/location/location_service.dart';

class _FakeGeolocator extends GeolocatorWrapper {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission? requestResult;
  Position? positionToReturn;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async =>
      requestResult ?? permission;

  /// #3116 — captured so the test can assert the acquisition profile.
  LocationSettings? lastLocationSettings;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    lastLocationSettings = locationSettings;
    if (positionToReturn != null) return positionToReturn!;
    return Position(
      latitude: 52.52,
      longitude: 13.405,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  double distanceBetween(
    double startLat, double startLng, double endLat, double endLng,
  ) => 1000.0;
}

void main() {
  group('LocationService with GeolocatorWrapper', () {
    late _FakeGeolocator fakeGeolocator;
    late LocationService service;

    setUp(() {
      fakeGeolocator = _FakeGeolocator();
      service = LocationService(fakeGeolocator);
    });

    test(
        '#3116 — first fix uses medium accuracy + a 30s safety net (a cold '
        'high-accuracy A11/iPhone-8 lock blew the old 10s window, killing '
        'search + radar)', () async {
      await service.getCurrentPosition();
      final settings = fakeGeolocator.lastLocationSettings;
      expect(settings, isNotNull);
      expect(settings!.accuracy, LocationAccuracy.medium);
      expect(settings.timeLimit, const Duration(seconds: 30));
    });

    test('returns position when permission granted', () async {
      final position = await service.getCurrentPosition();
      expect(position.latitude, closeTo(52.52, 0.01));
      expect(position.longitude, closeTo(13.405, 0.01));
    });

    test('throws when location service disabled', () {
      fakeGeolocator.serviceEnabled = false;
      expect(
        () => service.getCurrentPosition(),
        throwsA(isA<LocationException>()),
      );
    });

    test('requests permission when denied, succeeds if granted', () async {
      fakeGeolocator.permission = LocationPermission.denied;
      fakeGeolocator.requestResult = LocationPermission.whileInUse;
      final position = await service.getCurrentPosition();
      expect(position.latitude, closeTo(52.52, 0.01));
    });

    test('throws when permission denied after request', () {
      fakeGeolocator.permission = LocationPermission.denied;
      fakeGeolocator.requestResult = LocationPermission.denied;
      expect(
        () => service.getCurrentPosition(),
        throwsA(isA<LocationException>()),
      );
    });

    // #2872 — a degenerate fix that slips through the platform must be
    // rejected at this single acquisition chokepoint so it can never seed
    // the route origin (→ OSRM routes from the Gulf of Guinea → the route
    // map centres in the Sahara) nor be persisted as the user position.
    Position degenerate(double lat, double lng) => Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

    test('throws on a (0,0) null-island fix (#2872)', () {
      fakeGeolocator.positionToReturn = degenerate(0, 0);
      expect(
        () => service.getCurrentPosition(),
        throwsA(isA<LocationException>()),
      );
    });

    test('throws on a one-axis-unacquired (lat,0) fix (#2872)', () {
      fakeGeolocator.positionToReturn = degenerate(42.7, 0);
      expect(
        () => service.getCurrentPosition(),
        throwsA(isA<LocationException>()),
      );
    });

    test('throws on a one-axis-unacquired (0,lng) fix (#2872)', () {
      fakeGeolocator.positionToReturn = degenerate(0, 2.86);
      expect(
        () => service.getCurrentPosition(),
        throwsA(isA<LocationException>()),
      );
    });

    test('returns a valid France fix unchanged — no regression (#2872)',
        () async {
      fakeGeolocator.positionToReturn = degenerate(42.7667, 2.8667);
      final position = await service.getCurrentPosition();
      expect(position.latitude, closeTo(42.7667, 0.0001));
      expect(position.longitude, closeTo(2.8667, 0.0001));
    });

    test('throws when permission permanently denied', () {
      fakeGeolocator.permission = LocationPermission.deniedForever;
      expect(
        () => service.getCurrentPosition(),
        throwsA(isA<LocationException>().having(
          (e) => e.message,
          'message',
          contains('permanently'),
        )),
      );
    });

    // #2316 — all LocationException messages must be English diagnostics
    // per the exceptions.dart contract; they appear verbatim in GitHub
    // error-report payloads (ErrorLocalizer maps to ARB for the UI).
    test('all LocationException messages are English (#2316)', () async {
      // disabled
      fakeGeolocator.serviceEnabled = false;
      LocationException? ex;
      try { await service.getCurrentPosition(); } on LocationException catch (e) { ex = e; }
      expect(ex?.message, isNot(contains('Standort')));
      expect(ex?.message, isNot(contains('deaktiviert')));

      // denied after request
      fakeGeolocator
        ..serviceEnabled = true
        ..permission = LocationPermission.denied
        ..requestResult = LocationPermission.denied;
      try { await service.getCurrentPosition(); } on LocationException catch (e) { ex = e; }
      expect(ex?.message, isNot(contains('verweigert')));

      // permanently denied
      fakeGeolocator
        ..permission = LocationPermission.deniedForever
        ..requestResult = null;
      try { await service.getCurrentPosition(); } on LocationException catch (e) { ex = e; }
      expect(ex?.message, isNot(contains('Standort')));
    });

    test('distanceBetween delegates to wrapper', () {
      final distance = service.distanceBetween(52.0, 13.0, 53.0, 14.0);
      expect(distance, 1000.0);
    });
  });

  group('GeolocatorWrapper source-level regression', () {
    test('LocationService uses GeolocatorWrapper, not static Geolocator', () {
      final source = File(
        'lib/core/location/location_service.dart',
      ).readAsStringSync();

      expect(source, contains('GeolocatorWrapper'));
      expect(
        source.contains('Geolocator.checkPermission'),
        isFalse,
        reason: 'Should use _geolocator.checkPermission, not static Geolocator',
      );
      expect(
        source.contains('Geolocator.requestPermission'),
        isFalse,
        reason: 'Should use _geolocator.requestPermission, not static Geolocator',
      );
      expect(
        source.contains('Geolocator.isLocationServiceEnabled'),
        isFalse,
        reason: 'Should use _geolocator.isLocationServiceEnabled, not static Geolocator',
      );
    });
  });
}
