import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/vehicle/data/repositories/vehicle_profile_repository.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/domain/fuzzy_classifier.dart';
import 'package:tankstellen/features/vehicle/providers/calibration_mode_providers.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Fake `FuzzyClassifier` returning a caller-supplied membership map so
/// tests can drive the fuzzy code path deterministically without
/// re-stating the classifier's own membership-function semantics.
class _FakeFuzzyClassifier extends FuzzyClassifier {
  final Map<Situation, double> result;
  const _FakeFuzzyClassifier(this.result);

  @override
  Map<Situation, double> classify({
    required double speedKmh,
    required double accel,
    required double grade,
    required double throttlePct,
    required double rpm,
    bool isStopAndGoContext = false,
  }) =>
      result;
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

void main() {
  group('calibrationVotesProvider — rule mode (_ruleWinner)', () {
    late ProviderContainer container;

    Future<void> setupRuleProfile() async {
      final repo = VehicleProfileRepository(_FakeSettings());
      container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(id: 'v1', name: 'Rule car'),
          );
    }

    test('idle: speed ≤ 2 km/h → Situation.idle, weight 1, value carries through',
        () async {
      await setupRuleProfile();
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 1,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 10,
            rpm: 800,
            observedValue: 0.9,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.single.situation, Situation.idle);
      expect(votes.single.weight, 1.0);
      expect(votes.single.value, 0.9);
    });

    test('stopAndGo: caller-flagged context above idle → Situation.stopAndGo',
        () async {
      await setupRuleProfile();
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 30,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 20,
            rpm: 1500,
            observedValue: 4.0,
            isStopAndGoContext: true,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.single.situation, Situation.stopAndGo);
    });

    test('highway: speed ≥ 80 km/h with no climbing → Situation.highway',
        () async {
      await setupRuleProfile();
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 100,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 30,
            rpm: 2500,
            observedValue: 6.0,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.single.situation, Situation.highway);
    });

    test('climbing: grade ≥ 3 % under load beats highway/urban speed bands',
        () async {
      await setupRuleProfile();
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 50,
            accelMps2: 0,
            gradePct: 5,
            throttlePct: 40,
            rpm: 2500,
            observedValue: 7.5,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.single.situation, Situation.climbing);
    });

    test('urban fallback: speed in 2–80 km/h, no other signal → Situation.urban',
        () async {
      await setupRuleProfile();
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 40,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 25,
            rpm: 2000,
            observedValue: 5.5,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.single.situation, Situation.urban);
    });

    test('decel: accel < -0.5 m/s² with throttle off → Situation.decel '
        '(rpm low enough to skip fuel-cut gate)', () async {
      await setupRuleProfile();
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 50,
            accelMps2: -1.0,
            gradePct: 0,
            throttlePct: 2,
            // rpm ≤ 1500 keeps the fuel-cut gate closed so decel wins.
            rpm: 1400,
            observedValue: 0.2,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.single.situation, Situation.decel);
    });

    test('fuelCut: throttle < 5, rpm > 1500, speed > 20 → Situation.fuelCut '
        '(beats decel because the fuel-cut gate fires first)', () async {
      await setupRuleProfile();
      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 50,
            accelMps2: -1.0,
            gradePct: 0,
            throttlePct: 2,
            rpm: 2000,
            observedValue: 0.0,
          ),
        ),
      );
      expect(votes, hasLength(1));
      expect(votes.single.situation, Situation.fuelCut);
    });

    test('missing vehicle profile: defaults to rule mode and emits one vote',
        () {
      // No profile saved → vehicleId is unknown. Provider should fall
      // back to rule mode and apply _ruleWinner directly.
      final repo = VehicleProfileRepository(_FakeSettings());
      final container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'does-not-exist',
          sample: const CalibrationSample(
            speedKmh: 0,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 0,
            rpm: 800,
            observedValue: 1.0,
          ),
        ),
      );
      expect(votes, hasLength(1));
      // Speed ≤ 2 → idle.
      expect(votes.single.situation, Situation.idle);
      expect(votes.single.weight, 1.0);
    });
  });

  group('calibrationVotesProvider — fuzzy mode', () {
    test(
        'returns one vote per non-zero membership; weights match; '
        'all values equal observedValue', () async {
      const fakeMemberships = <Situation, double>{
        Situation.urban: 0.6,
        Situation.highway: 0.4,
      };
      final repo = VehicleProfileRepository(_FakeSettings());
      final container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
          fuzzyClassifierProvider.overrideWithValue(
            const _FakeFuzzyClassifier(fakeMemberships),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Fuzzy car',
              calibrationMode: VehicleCalibrationMode.fuzzy,
            ),
          );

      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 65,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 25,
            rpm: 2200,
            observedValue: 4.2,
          ),
        ),
      );

      expect(votes, hasLength(2));
      final byKey = {for (final v in votes) v.situation: v};
      expect(byKey[Situation.urban]!.weight, closeTo(0.6, 1e-9));
      expect(byKey[Situation.highway]!.weight, closeTo(0.4, 1e-9));
      // Every fuzzy vote carries the original observed value — the
      // Welford accumulator multiplies by weight, not value.
      for (final v in votes) {
        expect(v.value, 4.2);
      }
    });

    test('zero-weight memberships are filtered out of the vote list',
        () async {
      // Highway and idle memberships are exactly 0 — provider must
      // drop both.
      const fakeMemberships = <Situation, double>{
        Situation.urban: 1.0,
        Situation.highway: 0.0,
        Situation.idle: 0.0,
      };
      final repo = VehicleProfileRepository(_FakeSettings());
      final container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
          fuzzyClassifierProvider.overrideWithValue(
            const _FakeFuzzyClassifier(fakeMemberships),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(vehicleProfileListProvider.notifier).save(
            const VehicleProfile(
              id: 'v1',
              name: 'Fuzzy car',
              calibrationMode: VehicleCalibrationMode.fuzzy,
            ),
          );

      final votes = container.read(
        calibrationVotesProvider(
          vehicleId: 'v1',
          sample: const CalibrationSample(
            speedKmh: 30,
            accelMps2: 0,
            gradePct: 0,
            throttlePct: 20,
            rpm: 1800,
            observedValue: 3.3,
          ),
        ),
      );

      expect(votes, hasLength(1));
      expect(votes.single.situation, Situation.urban);
      expect(votes.single.weight, 1.0);
      // Make sure neither zero-weight bucket leaked in.
      expect(
        votes.where((v) => v.situation == Situation.highway),
        isEmpty,
      );
      expect(
        votes.where((v) => v.situation == Situation.idle),
        isEmpty,
      );
    });
  });

  group('CalibrationReplayQueue', () {
    late ProviderContainer container;

    setUp(() {
      final repo = VehicleProfileRepository(_FakeSettings());
      container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
    });

    test('build() returns an empty list initially', () {
      expect(container.read(calibrationReplayQueueProvider), isEmpty);
    });

    test('requestReplay enqueues distinct vehicle ids in order', () {
      final notifier =
          container.read(calibrationReplayQueueProvider.notifier);
      notifier.requestReplay('v1');
      notifier.requestReplay('v2');
      expect(
        container.read(calibrationReplayQueueProvider),
        ['v1', 'v2'],
      );
    });

    test('requestReplay is idempotent — the second call is a no-op', () {
      final notifier =
          container.read(calibrationReplayQueueProvider.notifier);
      notifier.requestReplay('v1');
      final stateAfterFirst =
          container.read(calibrationReplayQueueProvider);
      notifier.requestReplay('v1');
      final stateAfterSecond =
          container.read(calibrationReplayQueueProvider);
      expect(stateAfterFirst, ['v1']);
      expect(stateAfterSecond, ['v1']);
    });

    test('consume removes the matching vehicle id', () {
      final notifier =
          container.read(calibrationReplayQueueProvider.notifier);
      notifier.requestReplay('v1');
      notifier.requestReplay('v2');
      notifier.consume('v1');
      expect(container.read(calibrationReplayQueueProvider), ['v2']);
    });

    test('consume of an unknown id is a no-op', () {
      final notifier =
          container.read(calibrationReplayQueueProvider.notifier);
      notifier.requestReplay('v1');
      notifier.consume('v-unknown');
      expect(container.read(calibrationReplayQueueProvider), ['v1']);
    });
  });

  group('fuzzyClassifierProvider', () {
    test('builds a FuzzyClassifier instance without throwing', () {
      final repo = VehicleProfileRepository(_FakeSettings());
      final container = ProviderContainer(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final classifier = container.read(fuzzyClassifierProvider);
      expect(classifier, isA<FuzzyClassifier>());
    });
  });
}
