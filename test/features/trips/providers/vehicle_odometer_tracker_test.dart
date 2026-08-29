// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3877 — the live odometer reading of a running recording lands in the
// per-vehicle snapshot store (once per distinct reading).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/obd2/domain/trip_live_reading.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/trips/providers/vehicle_odometer_tracker.dart';
import 'package:tankstellen/features/vehicle/api.dart';

class _Mem implements SettingsStorage {
  final Map<String, dynamic> m = {};
  @override
  dynamic getSetting(String key) => m[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => m[key] = value;
  @override
  bool get isSetupComplete => true;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

class _FakeRecording extends TripRecording {
  _FakeRecording(this._initial);
  final TripRecordingState _initial;
  @override
  TripRecordingState build() => _initial;
  void setLive(TripLiveReading? live) => state = state.copyWith(live: live);
}

class _ActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => const VehicleProfile(
      id: 'veh-1', name: 'Clio', type: VehicleType.combustion);
}

TripLiveReading _reading(double? odo) => TripLiveReading(
      distanceKmSoFar: 1,
      elapsed: const Duration(minutes: 1),
      odometerNowKm: odo,
    );

void main() {
  test('a live reading is persisted for the active vehicle; the same '
      'reading again is not rewritten', () async {
    final mem = _Mem();
    final store = VehicleOdometerSnapshotStore(mem);
    final recording = _FakeRecording(TripRecordingState(
        phase: TripRecordingPhase.recording, live: _reading(120000)));
    final container = ProviderContainer(overrides: [
      tripRecordingProvider.overrideWith(() => recording),
      activeVehicleProfileProvider.overrideWith(_ActiveVehicle.new),
      vehicleOdometerSnapshotStoreProvider.overrideWithValue(store),
      appClockProvider.overrideWithValue(FixedClock(DateTime(2026, 8, 29, 9))),
    ]);
    addTearDown(container.dispose);

    // Riverpod 3 pauses an unlistened provider — the banner listens in
    // production; the test keeps it live the same way.
    container.listen(vehicleOdometerTrackerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(store.read('veh-1')?.km, 120000);
    expect(store.read('veh-1')?.source, VehicleOdometerSource.obd2);

    final writes = mem.m.length;
    recording.setLive(_reading(120000)); // unchanged reading
    await Future<void>.delayed(Duration.zero);
    expect(mem.m.length, writes);

    recording.setLive(_reading(120004)); // a refresh landed
    await Future<void>.delayed(Duration.zero);
    expect(store.read('veh-1')?.km, 120004);
  });

  test('no reading → nothing written', () async {
    final store = VehicleOdometerSnapshotStore(_Mem());
    final container = ProviderContainer(overrides: [
      tripRecordingProvider.overrideWith(() => _FakeRecording(
          TripRecordingState(phase: TripRecordingPhase.recording, live: _reading(null)))),
      activeVehicleProfileProvider.overrideWith(_ActiveVehicle.new),
      vehicleOdometerSnapshotStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(container.dispose);
    container.listen(vehicleOdometerTrackerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(store.read('veh-1'), isNull);
  });
}
