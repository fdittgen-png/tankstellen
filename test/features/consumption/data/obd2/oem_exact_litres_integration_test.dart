// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_capability.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/oem_pid_table.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/providers/current_obd2_fuel_level_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_oem_fuel_level_controller.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// End-to-end coverage for the OEM exact-litres path (#1620): a
/// capability-tiered fake adapter → `OemPidRegistry.withDefaults()` →
/// the real `PsaOemPidTable` wire sequence → `TripOemFuelLevelController`
/// → the litres value that lights the verified-by-adapter badge.
///
/// Unlike `trip_oem_fuel_level_controller_test.dart` (which injects a
/// fake `OemPidTable`), this suite drives the REAL shipped registry and
/// PSA table so the probe → resolve → read chain is exercised exactly
/// as production runs it — only the adapter transport is faked.

// ---------------------------------------------------------------------------
// Fake-adapter fixtures — one per capability tier (#1620 acceptance 1).
// ---------------------------------------------------------------------------

/// OEM-PID-capable adapter on a PSA car. Serves the BSI wire sequence
/// `AT SH 6FA` → `2151` → `AT SH 7DF`; the `2151` response carries
/// byte `0x5A` (90), which the PSA `× 0.5` scaling maps to 45.0 L.
class _OemCapablePsaAdapter implements Obd2RawCommandPort {
  final List<String> sent = <String>[];

  @override
  Future<String> sendRaw(String command) async {
    sent.add(command.trim());
    switch (command.trim()) {
      case 'AT SH 6FA':
        return 'OK\r>';
      case '2151':
        return '67A 03 61 51 5A\r>';
      case 'AT SH 7DF':
        return 'OK\r>';
      default:
        return 'NO DATA\r>';
    }
  }
}

/// Standard-only adapter (cheap ELM327 clone). The capability gate in
/// `resolveForCapability` rejects this tier before any command is sent,
/// so a call to [sendRaw] is a test failure — the OBD-II loop must
/// never route an OEM command at a `standardOnly` adapter.
class _StandardOnlyAdapter implements Obd2RawCommandPort {
  @override
  Future<String> sendRaw(String command) async {
    fail('A standardOnly adapter must never receive an OEM command, '
        'got: $command');
  }
}

/// Lying-clone adapter — probed as OEM-capable but cannot actually
/// route header-switching commands. A real clone answers `?` to an
/// `AT SH` it does not support; the PSA table must detect that and bail
/// to null rather than hang the loop or fabricate a litres value.
class _LyingCloneAdapter implements Obd2RawCommandPort {
  final List<String> sent = <String>[];

  @override
  Future<String> sendRaw(String command) async {
    sent.add(command.trim());
    return '?\r>';
  }
}

/// Manual `TripRecording` fake — pins the live reading directly so the
/// badge-value assertion stays free of OBD2 / Hive setup. Mirrors the
/// pattern in `current_obd2_fuel_level_provider_test.dart`.
class _ManualTripRecording extends TripRecording {
  _ManualTripRecording(this._initial);
  final TripRecordingState _initial;

  @override
  TripRecordingState build() => _initial;
}

class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

void main() {
  /// A 17-char PSA VIN — WMI prefix `VF3` (Peugeot), which the shipped
  /// `PsaOemPidTable` claims.
  const psaVin = 'VF3AAAAAAAAAAAAAA';

  /// The litres a `0x5A` BSI byte decodes to (90 × 0.5).
  const expectedLitres = 45.0;

  group('OEM exact-litres path — OEM-capable adapter (#1620)', () {
    test(
        'probe → resolve(withDefaults) → PSA wire read yields exact litres',
        () async {
      final adapter = _OemCapablePsaAdapter();
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry.withDefaults(),
      );
      addTearDown(controller.stop);

      double? latched;
      controller.start(
        enabled: true,
        vin: psaVin,
        capability: Obd2AdapterCapability.oemPidsCapable,
        port: adapter,
        onLitres: (litres) => latched = litres,
      );

      expect(controller.debugIsPolling, isTrue,
          reason: 'an OEM-capable PSA adapter must resolve a table');
      await controller.debugReadOnce();

      expect(latched, expectedLitres);
      // The real PSA wire sequence ran against the adapter.
      expect(adapter.sent, containsAllInOrder(<String>[
        'AT SH 6FA',
        '2151',
        'AT SH 7DF',
      ]));
    });

    test('the resolved table is the shipped PSA table', () {
      final table = OemPidRegistry.withDefaults().resolveForCapability(
        psaVin,
        Obd2AdapterCapability.oemPidsCapable,
      );
      expect(table, isNotNull);
      expect(table!.oemKey, 'PSA');
    });
  });

  group('OEM exact-litres path — OEM-incapable adapter (#1620)', () {
    test('a standardOnly adapter never polls and never reads OEM litres',
        () async {
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry.withDefaults(),
      );
      addTearDown(controller.stop);

      double? latched;
      controller.start(
        enabled: true,
        vin: psaVin,
        capability: Obd2AdapterCapability.standardOnly,
        port: _StandardOnlyAdapter(),
        onLitres: (litres) => latched = litres,
      );

      // resolveForCapability gates standardOnly out — no poll, and the
      // adapter's sendRaw (which `fail()`s) is never reached.
      expect(controller.debugIsPolling, isFalse);
      await controller.debugReadOnce();
      expect(latched, isNull);
    });
  });

  group('OEM exact-litres path — lying-clone adapter (#1620)', () {
    test('a clone that rejects AT SH yields null, not a fabricated litres',
        () async {
      final adapter = _LyingCloneAdapter();
      final controller = TripOemFuelLevelController(
        registry: OemPidRegistry.withDefaults(),
      );
      addTearDown(controller.stop);

      double? latched;
      var pushCount = 0;
      controller.start(
        enabled: true,
        vin: psaVin,
        // The clone lied during the capability probe — it claims the
        // OEM tier but cannot route the commands.
        capability: Obd2AdapterCapability.oemPidsCapable,
        port: adapter,
        onLitres: (litres) {
          latched = litres;
          pushCount++;
        },
      );

      // The table still resolves (capability says capable), so the poll
      // arms — but the read bails at the rejected `AT SH 6FA`.
      expect(controller.debugIsPolling, isTrue);
      await controller.debugReadOnce();

      expect(latched, isNull);
      expect(pushCount, 0,
          reason: 'a null OEM read must not push — no fabricated litres');
      // The table bailed at the header switch; it never sent `2151`.
      expect(adapter.sent, isNot(contains('2151')));
    });
  });

  group('OEM exact-litres reaches the verified-by-adapter badge (#1620)', () {
    test('currentObd2FuelLevelLitres surfaces the exact OEM litres', () {
      // The OEM read above produces 45.0 L; once it lands on the live
      // reading, the badge-feeding provider returns it verbatim — NOT a
      // coarse percent×capacity approximation.
      final container = ProviderContainer(overrides: [
        tripRecordingProvider.overrideWith(
          () => _ManualTripRecording(
            const TripRecordingState(
              phase: TripRecordingPhase.recording,
              live: TripLiveReading(
                fuelLevelPercent: 50,
                fuelLevelLitres: expectedLitres,
                distanceKmSoFar: 0,
                elapsed: Duration(seconds: 1),
              ),
            ),
          ),
        ),
        activeVehicleProfileProvider.overrideWith(
          () => _StubActiveVehicle(const VehicleProfile(
            id: 'v1',
            name: 'Peugeot 308',
            type: VehicleType.combustion,
            tankCapacityL: 50,
          )),
        ),
      ]);
      addTearDown(container.dispose);

      // 50 % × 50 L would be 25 L; the exact OEM read wins.
      expect(
        container.read(currentObd2FuelLevelLitresProvider),
        expectedLitres,
      );
    });
  });
}
