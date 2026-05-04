import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/providers/current_obd2_fuel_level_provider.dart';
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
  }) {
    return TripRecordingState(
      phase: TripRecordingPhase.recording,
      live: TripLiveReading(
        fuelLevelPercent: fuelLevelPercent,
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
  }) {
    final c = ProviderContainer(overrides: [
      tripRecordingProvider
          .overrideWith(() => _ManualTripRecording(tripState)),
      activeVehicleProfileProvider
          .overrideWith(() => _StubActiveVehicle(activeVehicle)),
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
}
