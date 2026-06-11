// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_capability.dart';
import 'package:tankstellen/features/obd2/data/oem_pid_registry.dart';
import 'package:tankstellen/features/obd2/data/oem_pid_table.dart';
import 'package:tankstellen/features/consumption/providers/trip_oem_fuel_level_controller.dart';

/// Unit tests for [TripOemFuelLevelController] — the #1615 experimental
/// OEM-PID exact-fuel-level poll.
///
/// Covers the three acceptance cases from the issue:
///   1. flag-off — the controller never resolves a table or polls;
///   2. flag-on + OEM-capable adapter — the controller resolves the
///      manufacturer table and the OEM litres reach the sink;
///   3. flag-on + incapable adapter — `resolveForCapability` returns
///      null, so the controller never polls and the sink stays empty.
///
/// The registry is injected with a fake table so the test never
/// depends on a specific OEM wire protocol.

/// Fake [Obd2RawCommandPort] — the fake table below ignores the port
/// entirely, so a canned empty response is enough.
class _FakePort implements Obd2RawCommandPort {
  @override
  Future<String> sendRaw(String command) async => '';
}

/// Fake [OemPidTable] claiming the synthetic WMI prefix `TST`. Returns
/// a fixed litres value (or null when [litres] is null, to exercise the
/// "keep the last good value" branch).
class _FakeOemPidTable implements OemPidTable {
  _FakeOemPidTable(this.litres);

  final double? litres;
  int readCount = 0;

  @override
  String get oemKey => 'TEST';

  @override
  Set<String> get supportedWmiPrefixes => const {'TST'};

  @override
  Future<double?> readFuelLevelLitres(Obd2RawCommandPort port) async {
    readCount++;
    return litres;
  }
}

void main() {
  /// A VIN whose 3-char WMI prefix (`TST`) matches [_FakeOemPidTable].
  const matchingVin = 'TST0123456789ABCD';

  group('TripOemFuelLevelController — flag off (#1615 acceptance 1)', () {
    test('start does nothing when the feature flag is disabled', () async {
      final table = _FakeOemPidTable(42.0);
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry(tables: [table]),
      );
      addTearDown(controller.stop);

      double? pushed;
      controller.start(
        enabled: false,
        vin: matchingVin,
        capability: Obd2AdapterCapability.oemPidsCapable,
        port: _FakePort(),
        onLitres: (litres) => pushed = litres,
      );

      // No poll armed, the registry was never consulted, the sink is
      // untouched — the percent×capacity path runs unchanged.
      expect(controller.debugIsPolling, isFalse);
      await controller.debugReadOnce();
      expect(table.readCount, 0);
      expect(pushed, isNull);
    });
  });

  group('TripOemFuelLevelController — flag on + OEM-capable '
      '(#1615 acceptance 2)', () {
    test('resolves the table and pushes the exact OEM litres', () async {
      final table = _FakeOemPidTable(41.5);
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry(tables: [table]),
      );
      addTearDown(controller.stop);

      double? pushed;
      controller.start(
        enabled: true,
        vin: matchingVin,
        capability: Obd2AdapterCapability.oemPidsCapable,
        port: _FakePort(),
        onLitres: (litres) => pushed = litres,
      );

      // The poll is armed; a read pushes the table's exact litres.
      expect(controller.debugIsPolling, isTrue);
      await controller.debugReadOnce();
      expect(pushed, 41.5);
    });

    test('passiveCanCapable adapters also resolve (capability superset)',
        () async {
      final table = _FakeOemPidTable(60.0);
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry(tables: [table]),
      );
      addTearDown(controller.stop);

      double? pushed;
      controller.start(
        enabled: true,
        vin: matchingVin,
        capability: Obd2AdapterCapability.passiveCanCapable,
        port: _FakePort(),
        onLitres: (litres) => pushed = litres,
      );

      expect(controller.debugIsPolling, isTrue);
      await controller.debugReadOnce();
      expect(pushed, 60.0);
    });

    test('a null OEM read leaves the sink untouched (keeps last good)',
        () async {
      // A read returning null (NO DATA / negative response) must NOT
      // forward — the sampler keeps its last good value rather than
      // flapping to the percent path on one bad poll.
      final table = _FakeOemPidTable(null);
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry(tables: [table]),
      );
      addTearDown(controller.stop);

      var pushCount = 0;
      controller.start(
        enabled: true,
        vin: matchingVin,
        capability: Obd2AdapterCapability.oemPidsCapable,
        port: _FakePort(),
        onLitres: (_) => pushCount++,
      );

      await controller.debugReadOnce();
      expect(table.readCount, greaterThan(0));
      expect(pushCount, 0);
    });
  });

  group('TripOemFuelLevelController — flag on + incapable adapter '
      '(#1615 acceptance 3)', () {
    test('standardOnly adapters never poll (resolveForCapability null)',
        () async {
      final table = _FakeOemPidTable(42.0);
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry(tables: [table]),
      );
      addTearDown(controller.stop);

      double? pushed;
      controller.start(
        enabled: true,
        vin: matchingVin,
        capability: Obd2AdapterCapability.standardOnly,
        port: _FakePort(),
        onLitres: (litres) => pushed = litres,
      );

      // standardOnly clones can't route OEM commands — the registry
      // gate returns null, so no poll arms and the sink stays empty.
      expect(controller.debugIsPolling, isFalse);
      await controller.debugReadOnce();
      expect(table.readCount, 0);
      expect(pushed, isNull);
    });

    test('a null VIN never polls even on an OEM-capable adapter',
        () async {
      final table = _FakeOemPidTable(42.0);
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry(tables: [table]),
      );
      addTearDown(controller.stop);

      double? pushed;
      controller.start(
        enabled: true,
        vin: null,
        capability: Obd2AdapterCapability.oemPidsCapable,
        port: _FakePort(),
        onLitres: (litres) => pushed = litres,
      );

      expect(controller.debugIsPolling, isFalse);
      expect(pushed, isNull);
    });

    test('a VIN with no matching table never polls', () async {
      final table = _FakeOemPidTable(42.0);
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry(tables: [table]),
      );
      addTearDown(controller.stop);

      double? pushed;
      controller.start(
        enabled: true,
        vin: 'XYZ0000000000000', // WMI 'XYZ' — no table claims it
        capability: Obd2AdapterCapability.oemPidsCapable,
        port: _FakePort(),
        onLitres: (litres) => pushed = litres,
      );

      expect(controller.debugIsPolling, isFalse);
      expect(pushed, isNull);
    });
  });

  group('TripOemFuelLevelController — teardown', () {
    test('stop cancels the poll and clears the resolved table', () async {
      final table = _FakeOemPidTable(30.0);
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry(tables: [table]),
      );

      controller.start(
        enabled: true,
        vin: matchingVin,
        capability: Obd2AdapterCapability.oemPidsCapable,
        port: _FakePort(),
        onLitres: (_) {},
      );
      expect(controller.debugIsPolling, isTrue);

      await controller.stop();
      expect(controller.debugIsPolling, isFalse);

      // After stop a stray read is inert — the table is cleared.
      final before = table.readCount;
      await controller.debugReadOnce();
      expect(table.readCount, before);
    });
  });
}
