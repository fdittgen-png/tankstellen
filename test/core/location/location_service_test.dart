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

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
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
