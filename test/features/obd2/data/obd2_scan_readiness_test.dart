// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/obd2_scan_readiness.dart';

class _NoopRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {}

  @override
  noSuchMethod(Invocation invocation) => null;
}

class _FakePermissions implements Obd2Permissions {
  _FakePermissions(this.state, {this.throws = false});

  final Obd2PermissionState state;
  final bool throws;

  @override
  Future<Obd2PermissionState> current() async {
    if (throws) throw StateError('permission plugin unavailable');
    return state;
  }

  @override
  Future<Obd2PermissionState> request() async => state;

  @override
  Future<bool> requestNotifications() async => true;
}

Obd2ScanReadinessProbe probe({
  bool supported = true,
  Obd2PermissionState permission = Obd2PermissionState.granted,
  bool permissionThrows = false,
  BluetoothAdapterState adapter = BluetoothAdapterState.on,
  bool locationServices = true,
  bool android = true,
  Future<bool> Function()? isSupportedOverride,
  Future<bool> Function()? locationOverride,
}) =>
    Obd2ScanReadinessProbe(
      permissions: _FakePermissions(permission, throws: permissionThrows),
      isSupported: isSupportedOverride ?? () async => supported,
      adapterState: () async => adapter,
      locationServicesEnabled: locationOverride ?? () async => locationServices,
      isAndroid: () => android,
    );

void main() {
  setUp(() => errorLogger.testRecorderOverride = _NoopRecorder());
  tearDown(() => errorLogger.resetForTest());

  group('Obd2ScanReadinessProbe — the five causes of an empty scan', () {
    test('everything satisfied → ready', () async {
      expect(await probe().resolve(), Obd2ScanReadiness.ready);
    });

    test('no BLE hardware → unsupported', () async {
      expect(
        await probe(supported: false).resolve(),
        Obd2ScanReadiness.unsupported,
      );
    });

    test('adapter reports unavailable → unsupported', () async {
      expect(
        await probe(adapter: BluetoothAdapterState.unavailable).resolve(),
        Obd2ScanReadiness.unsupported,
      );
    });

    test('radio off → bluetoothOff', () async {
      expect(
        await probe(adapter: BluetoothAdapterState.off).resolve(),
        Obd2ScanReadiness.bluetoothOff,
      );
    });

    test('radio turning off is treated as off', () async {
      expect(
        await probe(adapter: BluetoothAdapterState.turningOff).resolve(),
        Obd2ScanReadiness.bluetoothOff,
      );
    });

    test('permission denied → permissionDenied', () async {
      expect(
        await probe(permission: Obd2PermissionState.denied).resolve(),
        Obd2ScanReadiness.permissionDenied,
      );
    });

    test('permission permanently denied → its own state', () async {
      expect(
        await probe(permission: Obd2PermissionState.permanentlyDenied)
            .resolve(),
        Obd2ScanReadiness.permissionPermanentlyDenied,
      );
    });

    test(
      'THE SILENT ONE: Android location services off → locationServicesOff',
      () async {
        // Everything green — hardware, permission, radio — and the scan
        // still returns nothing. This is the state that used to be
        // indistinguishable from "no adapter in range".
        expect(
          await probe(locationServices: false).resolve(),
          Obd2ScanReadiness.locationServicesOff,
        );
      },
    );

    test('location services are NOT checked on non-Android', () async {
      expect(
        await probe(android: false, locationServices: false).resolve(),
        Obd2ScanReadiness.ready,
      );
    });
  });

  group('ordering — the state names the blocker to clear NEXT', () {
    test('unsupported outranks every other blocker', () async {
      expect(
        await probe(
          supported: false,
          permission: Obd2PermissionState.denied,
          adapter: BluetoothAdapterState.off,
          locationServices: false,
        ).resolve(),
        Obd2ScanReadiness.unsupported,
      );
    });

    test('permission is resolved before the radio state', () async {
      // On Android 12+ reading adapterState can itself require
      // BLUETOOTH_CONNECT, so an ungranted app may observe a misleading
      // value — permission must be reported first.
      expect(
        await probe(
          permission: Obd2PermissionState.denied,
          adapter: BluetoothAdapterState.off,
        ).resolve(),
        Obd2ScanReadiness.permissionDenied,
      );
    });

    test('radio is resolved before location services', () async {
      expect(
        await probe(
          adapter: BluetoothAdapterState.off,
          locationServices: false,
        ).resolve(),
        Obd2ScanReadiness.bluetoothOff,
      );
    });
  });

  group('never throws — every probe fault degrades, none propagates', () {
    test(
      'a throwing isSupported probe is OPTIMISTIC — only a positive '
      '"false" may hide the scan path',
      () async {
        // resolve() gates the scan; a probe FAULT (missing platform
        // binding, flaky channel) must fail open, or a transient error
        // hides the whole feature — and every widget-test harness,
        // where the FlutterBluePlus binding is absent, would divert to
        // `unsupported` before the faked scan could run.
        await expectLater(
          probe(
            isSupportedOverride: () =>
                Future<bool>.error(StateError('no binding')),
          ).resolve(),
          completion(Obd2ScanReadiness.ready),
        );
      },
    );

    test('a throwing permission probe degrades to permissionDenied', () async {
      await expectLater(
        probe(permissionThrows: true).resolve(),
        completion(Obd2ScanReadiness.permissionDenied),
      );
    });

    test(
      'a throwing location probe is OPTIMISTIC — it must not block a scan '
      'that would have worked',
      () async {
        await expectLater(
          probe(
            locationOverride: () =>
                Future<bool>.error(StateError('geolocator unavailable')),
          ).resolve(),
          completion(Obd2ScanReadiness.ready),
        );
      },
    );
  });

  group('Obd2ScanReadinessX', () {
    test('canScan is true only for ready', () {
      for (final s in Obd2ScanReadiness.values) {
        expect(s.canScan, s == Obd2ScanReadiness.ready, reason: '$s');
      }
    });

    test('isPromptable is true only for a re-promptable denial', () {
      for (final s in Obd2ScanReadiness.values) {
        expect(
          s.isPromptable,
          s == Obd2ScanReadiness.permissionDenied,
          reason: '$s',
        );
      }
    });
  });
}
