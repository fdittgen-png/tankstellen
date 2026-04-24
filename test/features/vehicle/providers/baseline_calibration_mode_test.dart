import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/domain/fuzzy_classifier.dart';
import 'package:tankstellen/features/vehicle/providers/calibration_mode_providers.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

void main() {
  group('VehicleProfile calibrationMode persistence', () {
    test('defaults to rule for profiles created without the field', () {
      const profile = VehicleProfile(id: 'v1', name: 'Golf');
      expect(profile.calibrationMode, VehicleCalibrationMode.rule);
    });

    test('pre-#894 JSON (no calibrationMode field) deserialises with rule',
        () {
      // Hand-crafted payload that predates #894 — the calibrationMode
      // key is simply absent from storage.
      final legacy = <String, dynamic>{
        'id': 'legacy',
        'name': 'Old car',
        'type': 'combustion',
        'tankCapacityL': 55.0,
        'preferredFuelType': 'e10',
      };
      final restored = VehicleProfile.fromJson(legacy);
      expect(restored.calibrationMode, VehicleCalibrationMode.rule);
    });

    test('round-trips .fuzzy through JSON', () {
      const profile = VehicleProfile(
        id: 'v1',
        name: 'Car',
        calibrationMode: VehicleCalibrationMode.fuzzy,
      );
      final json = profile.toJson();
      expect(json['calibrationMode'], 'fuzzy');
      final restored = VehicleProfile.fromJson(json);
      expect(restored.calibrationMode, VehicleCalibrationMode.fuzzy);
    });
  });

  group('calibrationVotes provider', () {
    late ProviderContainer container;
    late VehicleProfileRepository repo;

    setUp(() {
      repo = VehicleProfileRepository(_FakeSettings());
      container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
    });

    test('rule mode emits exactly one winner-take-all vote', () async {
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(id: 'v1', name: 'Rule car'),
          );

      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 30,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 20,
            rpm: 2000,
            observedValue: 5.5,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.first.weight, 1.0);
      expect(votes.first.situation, Situation.urban);
      expect(votes.first.value, 5.5);
    });

    test('fuzzy mode spreads a borderline sample across buckets', () async {
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Fuzzy car',
              calibrationMode: VehicleCalibrationMode.fuzzy,
            ),
          );

      // 50 km/h sits on the urban trapezoid plateau — classifier
      // should return urban 1.0 (after normalisation).
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 50,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 20,
            rpm: 1800,
            observedValue: 3.0,
          ),
        ),
      );

      expect(votes, isNotEmpty);
      final totalWeight =
          votes.fold<double>(0, (acc, v) => acc + v.weight);
      expect(totalWeight, closeTo(1.0, 1e-6));
      // Each vote carries the same observedValue — the downstream
      // Welford update multiplies by weight, not value.
      for (final v in votes) {
        expect(v.value, 3.0);
      }
    });

    test('switching rule → fuzzy re-runs classification on the last trip',
        () async {
      // Set up the vehicle in rule mode and take a "baseline" snapshot
      // of the winner-take-all vote at 60 km/h.
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(id: 'v1', name: 'Car'),
          );
      // 35 km/h is inside the urban trapezoid AND the stopAndGo
      // trapezoid (flag on). Grade 4 % adds a climbing contribution.
      // Fuzzy should produce ≥2 distinct situation votes.
      const sample = CalibrationSample(
        speedKmh: 35,
        accelMps2: 0,
        gradePct: 4,
        throttlePct: 15,
        rpm: 2000,
        observedValue: 4.2,
        isStopAndGoContext: true,
      );
      final ruleVotes = container.read(
        calibrationVotesProvider(vehicleId: 'v1', sample: sample),
      );
      expect(ruleVotes, hasLength(1));

      // Flip mode to fuzzy. The replay queue should get this vehicle
      // enqueued, and the votes provider should now return the
      // fuzzy-expanded vector.
      final current =
          container.read(vehicleProfileListProvider).single;
      await container.read(vehicleProfileListProvider.notifier).save(
            current.copyWith(calibrationMode: VehicleCalibrationMode.fuzzy),
          );
      container
          .read(calibrationReplayQueueProvider.notifier)
          .requestReplay('v1');

      final queue = container.read(calibrationReplayQueueProvider);
      expect(queue, contains('v1'));

      final fuzzyVotes = container.read(
        calibrationVotesProvider(vehicleId: 'v1', sample: sample),
      );
      // Urban + stopAndGo + climbing all fire → fuzzy yields several
      // votes. More than one means the re-run happened.
      expect(fuzzyVotes.length, greaterThan(1));
      final totalWeight =
          fuzzyVotes.fold<double>(0, (acc, v) => acc + v.weight);
      expect(totalWeight, closeTo(1.0, 1e-6));
    });

    test('consume() drains the replay queue', () {
      container
          .read(calibrationReplayQueueProvider.notifier)
          .requestReplay('v1');
      container
          .read(calibrationReplayQueueProvider.notifier)
          .requestReplay('v2');
      expect(container.read(calibrationReplayQueueProvider), ['v1', 'v2']);

      container
          .read(calibrationReplayQueueProvider.notifier)
          .consume('v1');
      expect(container.read(calibrationReplayQueueProvider), ['v2']);
    });

    test('duplicate requestReplay is idempotent', () {
      final notifier =
          container.read(calibrationReplayQueueProvider.notifier);
      notifier.requestReplay('v1');
      notifier.requestReplay('v1');
      expect(container.read(calibrationReplayQueueProvider), ['v1']);
    });

    test('unknown vehicleId falls back to rule mode (one vote)', () {
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'does-not-exist',
          sample: const CalibrationSample(
            speedKmh: 0,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 0,
            rpm: 800,
            observedValue: 0.7,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.first.situation, Situation.idle);
    });
  });
}

class _FakeSettings implements SettingsStorage {
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
