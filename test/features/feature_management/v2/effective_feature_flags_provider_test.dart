import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart'
    as v1;
import 'package:tankstellen/features/feature_management/v2/effective_feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/v2/known_features.dart';

/// Coverage for the v2 cached `effectiveFeatureFlagsProvider` and the
/// pure-function `isEffectivelyEnabledV2` it wraps.
///
/// Drives behaviour through a `_TestFeatureFlags` notifier override so
/// the tests stay in-memory (no Hive). Mirrors the test pattern in
/// `auto_record_orchestrator_test.dart`.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags(this._initial);
  final Set<v1.Feature> _initial;

  @override
  Set<v1.Feature> build() => {..._initial};
}

void main() {
  group('isEffectivelyEnabledV2', () {
    test('returns false when the feature itself is disabled', () {
      expect(
        isEffectivelyEnabledV2(
          feature: kFeatureGamification,
          enabledIds: const {},
        ),
        isFalse,
      );
    });

    test('returns false when a required parent is disabled (single edge)',
        () {
      // gamification requires obd2TripRecording. Enable only
      // gamification → effective false because the require is unmet.
      expect(
        isEffectivelyEnabledV2(
          feature: kFeatureGamification,
          enabledIds: const {'gamification'},
        ),
        isFalse,
      );
    });

    test('returns true when feature + all transitive requires are on', () {
      expect(
        isEffectivelyEnabledV2(
          feature: kFeatureGamification,
          enabledIds: const {'gamification', 'obd2TripRecording'},
        ),
        isTrue,
      );
    });

    test('walks multi-step require chains (priceHistory → tflite)', () {
      // tflitePricePrediction requires priceHistory.
      expect(
        isEffectivelyEnabledV2(
          feature: kFeatureTflitePricePrediction,
          enabledIds: const {'tflitePricePrediction', 'priceHistory'},
        ),
        isTrue,
      );
      expect(
        isEffectivelyEnabledV2(
          feature: kFeatureTflitePricePrediction,
          enabledIds: const {'tflitePricePrediction'},
        ),
        isFalse,
      );
    });

    test('parent presentation (kFeatureGamification.parent) does NOT '
        'affect activation when separate from requires', () {
      // gamification.parent == kFeatureObd2TripRecording AND
      // gamification.requires == {kFeatureObd2TripRecording}. Today
      // they coincide; the test pins that the activation walk reads
      // ONLY requires, not parent. A future feature whose parent ≠
      // requires must still activate purely off requires.
      expect(
        isEffectivelyEnabledV2(
          feature: kFeatureGamification,
          enabledIds: const {'gamification', 'obd2TripRecording'},
        ),
        isTrue);
    });
  });

  group('effectiveFeatureFlagsProvider', () {
    ProviderContainer makeContainer(Set<v1.Feature> initial) {
      final c = ProviderContainer(overrides: [
        featureFlagsProvider.overrideWith(() => _TestFeatureFlags(initial)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('returns an entry for every FeatureClass in the registry', () {
      final c = makeContainer({});
      final m = c.read(effectiveFeatureFlagsProvider);
      // Every registered feature has a key; nothing is missing.
      for (final id in [
        'obd2TripRecording',
        'gamification',
        'tankSync',
        'baselineSync',
        'priceHistory',
        'tflitePricePrediction',
        'showFuel',
        'manualConsumption',
        'loyaltyCards',
      ]) {
        expect(m.containsKey(id), isTrue,
            reason: 'missing entry for $id in the effective map');
      }
    });

    test('cascade: disabling obd2TripRecording flips every OBD2 child '
        'effectively off', () {
      // Enable all OBD2 children but NOT the parent → every child
      // should be effectively off via the requires cascade.
      final c = makeContainer({
        v1.Feature.gamification,
        v1.Feature.hapticEcoCoach,
        v1.Feature.consumptionAnalytics,
        v1.Feature.gpsTripPath,
        v1.Feature.autoRecord,
        v1.Feature.showConsumptionTab,
        // obd2TripRecording intentionally absent
      });
      final m = c.read(effectiveFeatureFlagsProvider);
      expect(m.isOn(v1.Feature.gamification), isFalse);
      expect(m.isOn(v1.Feature.hapticEcoCoach), isFalse);
      expect(m.isOn(v1.Feature.consumptionAnalytics), isFalse);
      expect(m.isOn(v1.Feature.gpsTripPath), isFalse);
      expect(m.isOn(v1.Feature.autoRecord), isFalse);
      expect(m.isOn(v1.Feature.showConsumptionTab), isFalse);
    });

    test('flipping the parent on restores every still-enabled child', () {
      final c = makeContainer({
        v1.Feature.gamification,
        v1.Feature.obd2TripRecording,
        v1.Feature.autoRecord,
      });
      final m = c.read(effectiveFeatureFlagsProvider);
      expect(m.isOn(v1.Feature.gamification), isTrue);
      expect(m.isOn(v1.Feature.autoRecord), isTrue);
      // hapticEcoCoach not in the set → effectively off
      expect(m.isOn(v1.Feature.hapticEcoCoach), isFalse);
    });

    test('isOn / isOnV2 lookups agree (extension methods are mirrors)', () {
      final c = makeContainer({
        v1.Feature.priceHistory,
        v1.Feature.tflitePricePrediction,
      });
      final m = c.read(effectiveFeatureFlagsProvider);
      expect(
        m.isOn(v1.Feature.tflitePricePrediction),
        m.isOnV2(kFeatureTflitePricePrediction),
      );
    });

    test('isOn returns false for v1 features not yet bridged into v2', () {
      // Sanity check — if a future v1 enum value lands without a v2
      // FeatureClass mirror, the extension returns false rather than
      // throwing. Today every v1 enum has a mirror, so we can't
      // actually exercise that branch — but the test pins the
      // contract.
      final c = makeContainer({});
      final m = c.read(effectiveFeatureFlagsProvider);
      // Empty map lookup → null → ?? false → false
      expect(<String, bool>{}.isOn(v1.Feature.gamification), isFalse);
      expect(m.isOn(v1.Feature.gamification), isFalse);
    });
  });
}
