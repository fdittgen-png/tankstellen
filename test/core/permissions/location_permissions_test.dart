// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3614 — unit tests for the LocationPermissions facade. All backends
// are injected fakes; the assertions pin the exact prompt sequences
// and status mappings the two call sites relied on before extraction.
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:tankstellen/core/permissions/location_permissions.dart';

void main() {
  group('ensureWhileInUse (geolocator backend)', () {
    test('already granted → no request prompt fires', () async {
      var requests = 0;
      final p = LocationPermissions(
        checkWhileInUseBackend: () async => geo.LocationPermission.whileInUse,
        requestWhileInUseBackend: () async {
          requests++;
          return geo.LocationPermission.whileInUse;
        },
      );
      expect(await p.ensureWhileInUse(), LocationPermissionOutcome.granted);
      expect(requests, 0);
    });

    test('always counts as granted', () async {
      final p = LocationPermissions(
        checkWhileInUseBackend: () async => geo.LocationPermission.always,
        requestWhileInUseBackend: () async =>
            fail('must not prompt when already granted'),
      );
      expect(await p.ensureWhileInUse(), LocationPermissionOutcome.granted);
    });

    test('plain denial → one request prompt, its result wins', () async {
      var requests = 0;
      final p = LocationPermissions(
        checkWhileInUseBackend: () async => geo.LocationPermission.denied,
        requestWhileInUseBackend: () async {
          requests++;
          return geo.LocationPermission.whileInUse;
        },
      );
      expect(await p.ensureWhileInUse(), LocationPermissionOutcome.granted);
      expect(requests, 1);
    });

    test('deniedForever → permanentlyDenied WITHOUT re-prompting '
        '(the pre-#3614 sequence never re-requested a forever-denial)',
        () async {
      final p = LocationPermissions(
        checkWhileInUseBackend: () async =>
            geo.LocationPermission.deniedForever,
        requestWhileInUseBackend: () async =>
            fail('must not prompt on deniedForever'),
      );
      expect(
        await p.ensureWhileInUse(),
        LocationPermissionOutcome.permanentlyDenied,
      );
    });

    test('unableToDetermine → denied without prompting', () async {
      final p = LocationPermissions(
        checkWhileInUseBackend: () async =>
            geo.LocationPermission.unableToDetermine,
        requestWhileInUseBackend: () async =>
            fail('must not prompt on unableToDetermine'),
      );
      expect(await p.ensureWhileInUse(), LocationPermissionOutcome.denied);
    });

    test('request after denial can stay denied', () async {
      final p = LocationPermissions(
        checkWhileInUseBackend: () async => geo.LocationPermission.denied,
        requestWhileInUseBackend: () async => geo.LocationPermission.denied,
      );
      expect(await p.ensureWhileInUse(), LocationPermissionOutcome.denied);
    });
  });

  group('requestWhileInUse / requestAlways (permission_handler backend)', () {
    test('granted maps to granted', () async {
      final p = LocationPermissions(
        foregroundPromptBackend: () async => ph.PermissionStatus.granted,
        alwaysPromptBackend: () async => ph.PermissionStatus.granted,
      );
      expect(await p.requestWhileInUse(), LocationPermissionOutcome.granted);
      expect(await p.requestAlways(), LocationPermissionOutcome.granted);
    });

    test('permanentlyDenied and restricted both map to permanentlyDenied',
        () async {
      final p1 = LocationPermissions(
        alwaysPromptBackend: () async => ph.PermissionStatus.permanentlyDenied,
      );
      expect(
        await p1.requestAlways(),
        LocationPermissionOutcome.permanentlyDenied,
      );

      final p2 = LocationPermissions(
        alwaysPromptBackend: () async => ph.PermissionStatus.restricted,
      );
      expect(
        await p2.requestAlways(),
        LocationPermissionOutcome.permanentlyDenied,
      );
    });

    test('denied and limited map to plain denied', () async {
      final p1 = LocationPermissions(
        foregroundPromptBackend: () async => ph.PermissionStatus.denied,
      );
      expect(await p1.requestWhileInUse(), LocationPermissionOutcome.denied);

      final p2 = LocationPermissions(
        foregroundPromptBackend: () async => ph.PermissionStatus.limited,
      );
      expect(await p2.requestWhileInUse(), LocationPermissionOutcome.denied);
    });
  });

  test('openAppSettings routes through the injected backend', () async {
    var opened = 0;
    final p = LocationPermissions(
      openSettingsBackend: () async {
        opened++;
        return true;
      },
    );
    await p.openAppSettings();
    expect(opened, 1);
  });
}
