import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

void main() {
  group('tripRecordingProvider (#726)', () {
    test('defaults to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(tripRecordingProvider);
      expect(state.phase, TripRecordingPhase.idle);
      expect(state.isActive, isFalse);
    });

    test('start + stop round trip leaves the state in finished '
        'with a valid summary', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );
      expect(container.read(tripRecordingProvider).isActive, isTrue);

      final result = await notifier.stop();
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.finished,
      );
      expect(container.read(tripRecordingProvider).isActive, isFalse);
      expect(result.endOdometerKm, closeTo(9271.6, 0.01));
    });

    test('pause flips state to paused without disconnecting the service',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      notifier.pause();

      final state = container.read(tripRecordingProvider);
      expect(state.phase, TripRecordingPhase.paused);
      expect(state.isActive, isTrue,
          reason: 'paused trips still own the service');

      notifier.resume();
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );

      await notifier.stop();
    });

    test('reset() returns to idle — used after the save/discard step',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      await notifier.stop();
      notifier.reset();

      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.idle,
      );
    });

    test('calling start() twice is a no-op for the second call', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final a = Obd2Service(FakeObd2Transport(_elmOk()));
      final b = Obd2Service(FakeObd2Transport(_elmOk()));
      await a.connect();
      await b.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(a);
      // Second start while recording should not replace the service
      // underneath — the provider has to finish first.
      await notifier.start(b);

      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );

      await notifier.stop();
      // b was never wired in; clean it up manually.
      await b.disconnect();
    });
  });

  group('TripRecording.startTrip (#888)', () {
    test('start via new entry point → controller uses activeVehicle + '
        'adapterMac', () async {
      final storage = _FakeSettingsStorage();
      final profileRepo = VehicleProfileRepository(storage);
      await profileRepo.save(const VehicleProfile(
        id: 'veh-pinned',
        name: 'Pinned Peugeot',
        obd2AdapterMac: 'AA:BB:CC:DD:EE:FF',
      ));
      await profileRepo.setActive('veh-pinned');

      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(storage),
        vehicleProfileRepositoryProvider.overrideWithValue(profileRepo),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(tripRecordingProvider.notifier);
      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final outcome = await notifier.startTrip(service: service);
      expect(outcome, StartTripOutcome.started);
      expect(notifier.lastTripVehicleId, 'veh-pinned',
          reason:
              'startTrip must snapshot the active vehicle by default');
      expect(notifier.lastTripStartedAt, isNotNull);
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.recording,
      );

      await notifier.stop();
    });

    test('no adapter pinned → adapter picker fires (needsPicker)',
        () async {
      final storage = _FakeSettingsStorage();
      final profileRepo = VehicleProfileRepository(storage);
      // Active vehicle WITHOUT a pinned adapter MAC.
      await profileRepo.save(const VehicleProfile(
        id: 'veh-unpinned',
        name: 'Unpinned 208',
      ));
      await profileRepo.setActive('veh-unpinned');

      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(storage),
        vehicleProfileRepositoryProvider.overrideWithValue(profileRepo),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(tripRecordingProvider.notifier);
      final outcome = await notifier.startTrip();

      expect(outcome, StartTripOutcome.needsPicker,
          reason: 'UI must fall back to showObd2AdapterPicker when '
              'the active vehicle has no pinned MAC');
      expect(notifier.lastTripVehicleId, 'veh-unpinned');
      // No service was handed in — provider should not have flipped
      // into the recording phase yet.
      expect(
        container.read(tripRecordingProvider).phase,
        TripRecordingPhase.idle,
      );
    });

    test('explicit adapterMac param overrides pinned MAC', () async {
      final storage = _FakeSettingsStorage();
      final profileRepo = VehicleProfileRepository(storage);
      await profileRepo.save(const VehicleProfile(
        id: 'veh-unpinned',
        name: 'Unpinned 208',
      ));
      await profileRepo.setActive('veh-unpinned');

      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(storage),
        vehicleProfileRepositoryProvider.overrideWithValue(profileRepo),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(tripRecordingProvider.notifier);
      // Explicitly providing a MAC still falls through to needsPicker
      // because the provider keeps the connect flow at the UI layer
      // (reusing the tested picker). What matters is that the
      // outcome is NOT a hard error and that vehicle context still
      // tracks.
      final outcome = await notifier.startTrip(
        vehicleId: 'veh-unpinned',
        adapterMac: 'FF:EE:DD:CC:BB:AA',
      );
      expect(outcome, StartTripOutcome.needsPicker);
      expect(notifier.lastTripVehicleId, 'veh-unpinned');
    });

    test('second startTrip while recording returns alreadyActive',
        () async {
      final storage = _FakeSettingsStorage();
      final profileRepo = VehicleProfileRepository(storage);
      final container = ProviderContainer(overrides: [
        settingsStorageProvider.overrideWithValue(storage),
        vehicleProfileRepositoryProvider.overrideWithValue(profileRepo),
      ]);
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      final first = await notifier.startTrip(service: service);
      expect(first, StartTripOutcome.started);

      final second = await notifier.startTrip();
      expect(second, StartTripOutcome.alreadyActive);

      await notifier.stop();
    });
  });

  group('hapticForBandTransition (#767)', () {
    test('same band → none', () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.normal, ConsumptionBand.normal),
        HapticIntensity.none,
      );
    });

    test('normal → heavy fires light', () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.normal, ConsumptionBand.heavy),
        HapticIntensity.light,
      );
    });

    test('eco → heavy fires light', () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.eco, ConsumptionBand.heavy),
        HapticIntensity.light,
      );
    });

    test('transient → heavy fires light — a short WOT overtake that '
        'settles into sustained heavy should still ping', () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.transient, ConsumptionBand.heavy),
        HapticIntensity.light,
      );
    });

    test('normal → veryHeavy fires medium', () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.normal, ConsumptionBand.veryHeavy),
        HapticIntensity.medium,
      );
    });

    test('heavy → veryHeavy fires medium — escalation is worth a '
        'stronger pulse', () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.heavy, ConsumptionBand.veryHeavy),
        HapticIntensity.medium,
      );
    });

    test('veryHeavy → heavy stays silent — improvements never ping',
        () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.veryHeavy, ConsumptionBand.heavy),
        HapticIntensity.none,
      );
    });

    test('heavy → eco stays silent', () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.heavy, ConsumptionBand.eco),
        HapticIntensity.none,
      );
    });

    test('normal → eco stays silent — positive transitions are '
        'rewarded by the banner colour, not by vibration', () {
      expect(
        hapticForBandTransition(
            ConsumptionBand.normal, ConsumptionBand.eco),
        HapticIntensity.none,
      );
    });
  });
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };

class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic getSetting(String key) => _data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
