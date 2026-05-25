// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/providers/current_obd2_fuel_level_provider.dart';
import 'package:tankstellen/features/consumption/providers/psa_fuel_level_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Unit tests for [currentObd2FuelLevelLitresProvider] (#1434).
///
/// The provider's only job is to bridge:
///   * [tripRecordingProvider]'s `state.live?.fuelLevelPercent`
///   * [activeVehicleProfileProvider]'s `tankCapacityL`
///
/// into a litres value — gating on isActive (staleness proxy) and
/// dropping any null / out-of-range input. These tests pin the gates
/// + the conversion math.

/// Manual trip-recording fake — same pattern the haptic-eco-coach
/// provider tests use. We bypass `start`/`stop` and pin the state
/// directly so the test stays free of OBD2 / Hive setup.
class _ManualTripRecording extends TripRecording {
  _ManualTripRecording(this._initial);
  final TripRecordingState _initial;

  @override
  TripRecordingState build() => _initial;
}

/// Stub `ActiveVehicleProfile` — same pattern as [tank_level_provider_test].
class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

void main() {
  TripRecordingState recordingWith({
    double? fuelLevelPercent,
    double? fuelLevelLitres,
  }) {
    return TripRecordingState(
      phase: TripRecordingPhase.recording,
      live: TripLiveReading(
        fuelLevelPercent: fuelLevelPercent,
        fuelLevelLitres: fuelLevelLitres,
        distanceKmSoFar: 0,
        elapsed: const Duration(seconds: 1),
      ),
    );
  }

  const vehicleWithCapacity = VehicleProfile(
    id: 'v1',
    name: 'Test Car',
    type: VehicleType.combustion,
    tankCapacityL: 50,
  );

  const vehicleNoCapacity = VehicleProfile(
    id: 'v2',
    name: 'No-tank Car',
    type: VehicleType.combustion,
  );

  ProviderContainer makeContainer({
    required TripRecordingState tripState,
    VehicleProfile? activeVehicle,
    Stream<double>? psaCanStream,
  }) {
    final c = ProviderContainer(overrides: [
      tripRecordingProvider
          .overrideWith(() => _ManualTripRecording(tripState)),
      activeVehicleProfileProvider
          .overrideWith(() => _StubActiveVehicle(activeVehicle)),
      // #1616 — when a test drives the PSA passive-CAN path, override
      // the stream provider directly with a canned stream. Tests that
      // omit this exercise the real provider, whose production
      // `psaFuelLevelObd2Service` seam is null → empty stream → the
      // passive-CAN branch falls through (the absent-stream fallback).
      if (psaCanStream != null)
        psaFuelLevelProvider.overrideWith((ref) => psaCanStream),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('currentObd2FuelLevelLitresProvider — null gates', () {
    test('returns null when no trip is recording (idle phase)', () {
      // Even with a vehicle + a fuelLevelPercent in the live reading,
      // an idle phase means isActive == false and the provider must
      // refuse the value (staleness guard). The default
      // TripRecordingState constructor is idle.
      final c = makeContainer(
        tripState: const TripRecordingState(),
        activeVehicle: vehicleWithCapacity,
      );

      expect(c.read(currentObd2FuelLevelLitresProvider), isNull);
    });

    test('returns null when trip is finished (post-stop, stale state)', () {
      // Finished phase keeps the last live reading on the state but
      // isActive is false — the gate must reject this stale value.
      const state = TripRecordingState(
        phase: TripRecordingPhase.finished,
        live: TripLiveReading(
          fuelLevelPercent: 75,
          distanceKmSoFar: 0,
          elapsed: Duration(seconds: 1),
        ),
      );

      final c = makeContainer(
        tripState: state,
        activeVehicle: vehicleWithCapacity,
      );

      expect(c.read(currentObd2FuelLevelLitresProvider), isNull);
    });

    test('returns null when fuelLevelPercent is null (PID unsupported)', () {
      // Active recording but no PID 0x2F → live.fuelLevelPercent is
      // null. The provider must surface that through, not throw.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: null),
        activeVehicle: vehicleWithCapacity,
      );

      expect(c.read(currentObd2FuelLevelLitresProvider), isNull);
    });

    test('returns null when no active vehicle is selected', () {
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50),
        activeVehicle: null,
      );

      expect(c.read(currentObd2FuelLevelLitresProvider), isNull);
    });

    test('returns null when active vehicle has null tankCapacityL', () {
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50),
        activeVehicle: vehicleNoCapacity,
      );

      expect(c.read(currentObd2FuelLevelLitresProvider), isNull);
    });

    test('returns null when active vehicle has zero tankCapacityL', () {
      // Defensive: a malformed vehicle row with capacity 0 must not
      // multiply through to 0 L — null is the honest answer.
      const zeroCapacity = VehicleProfile(
        id: 'v3',
        name: 'Bad Car',
        type: VehicleType.combustion,
        tankCapacityL: 0,
      );

      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50),
        activeVehicle: zeroCapacity,
      );

      expect(c.read(currentObd2FuelLevelLitresProvider), isNull);
    });

    test('returns null when fuelLevelPercent is out of [0, 100] range', () {
      // PID 0x2F encodes 0-100% by spec; an out-of-range read is a
      // decoder bug or transport corruption — refuse rather than
      // multiply through to a nonsense value.
      final overRange = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 120),
        activeVehicle: vehicleWithCapacity,
      );
      expect(overRange.read(currentObd2FuelLevelLitresProvider), isNull);

      final underRange = makeContainer(
        tripState: recordingWith(fuelLevelPercent: -5),
        activeVehicle: vehicleWithCapacity,
      );
      expect(underRange.read(currentObd2FuelLevelLitresProvider), isNull);
    });
  });

  group('currentObd2FuelLevelLitresProvider — happy path conversion', () {
    test('50% on a 50 L tank yields 25 L', () {
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50),
        activeVehicle: vehicleWithCapacity,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(25, 0.0001),
      );
    });

    test('full tank reading yields full capacity', () {
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 100),
        activeVehicle: vehicleWithCapacity,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(50, 0.0001),
      );
    });

    test('empty tank reading yields 0 L (not null)', () {
      // 0% is a valid in-range reading — the gate is "out of [0,100]",
      // not "0 is null". A truly empty tank is information.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 0),
        activeVehicle: vehicleWithCapacity,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(0, 0.0001),
      );
    });

    test('fractional percent on a different capacity converts correctly',
        () {
      // 37.5 % × 60 L = 22.5 L. Pins the math against a vehicle whose
      // capacity differs from the 50 L base fixture.
      const sixtyLCar = VehicleProfile(
        id: 'v-sixty',
        name: 'Big Tank',
        type: VehicleType.combustion,
        tankCapacityL: 60,
      );

      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 37.5),
        activeVehicle: sixtyLCar,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(22.5, 0.0001),
      );
    });
  });

  group('currentObd2FuelLevelLitresProvider — OEM-PID native litres (#1615)',
      () {
    test('prefers the exact OEM litres over the percent×capacity path', () {
      // When the trip-recording sampler has populated fuelLevelLitres
      // (flag on + OEM-capable adapter), the provider returns that
      // value verbatim — NOT 50 % × 50 L = 25 L. The OEM read is exact;
      // the percentage path is the coarse fallback.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50, fuelLevelLitres: 41.5),
        activeVehicle: vehicleWithCapacity,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(41.5, 0.0001),
      );
    });

    test('OEM litres are returned even with no vehicle / no capacity', () {
      // The OEM read is litres-native, so it does not need the
      // user-entered tank capacity at all — it must surface even when
      // the percent path would have been gated out by a null capacity.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelLitres: 33.0),
        activeVehicle: null,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(33.0, 0.0001),
      );
    });

    test('falls through to percent×capacity when OEM litres are null', () {
      // Flag off / incapable adapter / no table for the VIN — the
      // sampler leaves fuelLevelLitres null and the coarse path runs
      // unchanged (50 % × 50 L = 25 L).
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50, fuelLevelLitres: null),
        activeVehicle: vehicleWithCapacity,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(25, 0.0001),
      );
    });

    test('a negative OEM litres value falls through to the percent path', () {
      // Defensive: a corrupt/negative OEM read is treated as "no
      // reading" and the percent×capacity fallback takes over.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50, fuelLevelLitres: -1),
        activeVehicle: vehicleWithCapacity,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(25, 0.0001),
      );
    });
  });

  group('currentObd2FuelLevelLitresProvider — PSA passive-CAN (#1616)', () {
    test('a live passive-CAN stream surfaces its exact decoded litres', () async {
      // A passiveCan-capable STN-chip adapter decodes litres straight
      // off the instrument-cluster broadcast — the highest-fidelity
      // source. 50 % × 50 L would be 25 L; the CAN read wins.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50),
        activeVehicle: vehicleWithCapacity,
        psaCanStream: Stream<double>.value(38.5),
      );
      // Drain the stream's first event so the StreamProvider holds a
      // value before the synchronous badge-provider read.
      // Keep the autoDispose StreamProvider alive across the await so
      // it isn't torn down before the canned stream emits.
      c.listen(psaFuelLevelProvider, (_, _) {});
      await c.read(psaFuelLevelProvider.future);

      expect(c.read(currentObd2FuelLevelLitresProvider), 38.5);
    });

    test('passive-CAN litres win over the OEM-PID litres', () async {
      // Both native sources present — passive-CAN is the more accurate
      // tier, so it takes precedence over the OEM-PID value.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50, fuelLevelLitres: 41.5),
        activeVehicle: vehicleWithCapacity,
        psaCanStream: Stream<double>.value(39.0),
      );
      // Keep the autoDispose StreamProvider alive across the await so
      // it isn't torn down before the canned stream emits.
      c.listen(psaFuelLevelProvider, (_, _) {});
      await c.read(psaFuelLevelProvider.future);

      expect(c.read(currentObd2FuelLevelLitresProvider), 39.0);
    });

    test('a negative passive-CAN value falls through to the OEM litres',
        () async {
      // Defensive: a corrupt/negative CAN decode is "no reading" — the
      // next source (OEM-PID litres) takes over.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50, fuelLevelLitres: 41.5),
        activeVehicle: vehicleWithCapacity,
        psaCanStream: Stream<double>.value(-1),
      );
      // Keep the autoDispose StreamProvider alive across the await so
      // it isn't torn down before the canned stream emits.
      c.listen(psaFuelLevelProvider, (_, _) {});
      await c.read(psaFuelLevelProvider.future);

      expect(c.read(currentObd2FuelLevelLitresProvider), 41.5);
    });

    test('no passive-CAN stream → the chain falls through unchanged', () {
      // The default (no override) provider has a null
      // `psaFuelLevelObd2Service` seam → empty stream → the passive-CAN
      // branch is skipped and the percent×capacity path runs (#1616
      // absent-stream fallback). 50 % × 50 L = 25 L.
      final c = makeContainer(
        tripState: recordingWith(fuelLevelPercent: 50),
        activeVehicle: vehicleWithCapacity,
      );

      expect(
        c.read(currentObd2FuelLevelLitresProvider),
        closeTo(25, 0.0001),
      );
    });
  });
}
