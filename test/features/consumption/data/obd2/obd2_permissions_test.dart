// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_permissions.dart';

void main() {
  group('Obd2PermissionState (#740)', () {
    test('has three distinct values the UI can switch on', () {
      expect(Obd2PermissionState.values, hasLength(3));
      expect(
        Obd2PermissionState.values.toSet(),
        {
          Obd2PermissionState.granted,
          Obd2PermissionState.denied,
          Obd2PermissionState.permanentlyDenied,
        },
      );
    });
  });

  group('Obd2Permissions contract (#740)', () {
    // These tests lock the abstract interface against regressions.
    // The real plugin-backed impl is exercised on-device; CI
    // coverage lives on the fake consumers wire up downstream.
    test('is an abstract class with request() and current()', () {
      final fake = _FakePermissions(Obd2PermissionState.granted);
      expect(fake, isA<Obd2Permissions>());
    });

    test('request() returns whatever the implementation decides',
        () async {
      final fake = _FakePermissions(Obd2PermissionState.denied);
      expect(await fake.request(), Obd2PermissionState.denied);
    });

    test('current() returns whatever the implementation decides',
        () async {
      final fake =
          _FakePermissions(Obd2PermissionState.permanentlyDenied);
      expect(await fake.current(), Obd2PermissionState.permanentlyDenied);
    });

    test('request() and current() can return different states '
        '(e.g. user grants during a prompt)', () async {
      final fake = _FakePermissions(
        Obd2PermissionState.denied,
        onRequest: Obd2PermissionState.granted,
      );
      expect(await fake.current(), Obd2PermissionState.denied);
      expect(await fake.request(), Obd2PermissionState.granted);
    });
  });

  group('requestNotifications() contract (#2282 concern 2)', () {
    test('reports the implementation grant decision', () async {
      final granting = _FakePermissions(
        Obd2PermissionState.granted,
        notificationsGranted: true,
      );
      final denying = _FakePermissions(
        Obd2PermissionState.granted,
        notificationsGranted: false,
      );
      expect(await granting.requestNotifications(), isTrue);
      expect(await denying.requestNotifications(), isFalse);
    });

    test('is callable independently of the Bluetooth permission state',
        () async {
      // POST_NOTIFICATIONS is a separate runtime grant from the BLE
      // scan/connect permissions — a denied Bluetooth state must not
      // prevent the notification probe from being asked + answered.
      final fake = _FakePermissions(
        Obd2PermissionState.denied,
        notificationsGranted: true,
      );
      expect(await fake.requestNotifications(), isTrue);
      expect(fake.notificationRequestCalls, 1);
    });
  });
}

/// Hand-rolled fake that stand-ins for the real plugin-backed
/// `PluginObd2Permissions`. Downstream code (#741, #742) will reuse
/// this shape in their own tests rather than importing it from here —
/// the helper is intentionally inlined to avoid cross-test coupling.
class _FakePermissions implements Obd2Permissions {
  final Obd2PermissionState _current;
  final Obd2PermissionState? _onRequest;
  final bool _notificationsGranted;
  int notificationRequestCalls = 0;

  _FakePermissions(
    this._current, {
    Obd2PermissionState? onRequest,
    bool notificationsGranted = true,
  })  : _onRequest = onRequest,
        _notificationsGranted = notificationsGranted;

  @override
  Future<Obd2PermissionState> current() async => _current;

  @override
  Future<Obd2PermissionState> request() async => _onRequest ?? _current;

  @override
  Future<bool> requestNotifications() async {
    notificationRequestCalls++;
    return _notificationsGranted;
  }
}
