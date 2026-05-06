import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/glide_coach/data/traffic_signal_repository.dart';
import 'package:tankstellen/features/glide_coach/providers/glide_coach_evaluator_provider.dart';

void main() {
  group('glideCoachEvaluatorProvider (#1125 phase 3b)', () {
    test(
      'returns null when kGlideCoachEnabled is false (production)',
      () {
        // Asserting the master flag explicitly so a future PR that
        // flips it to true makes this test fail loudly — the provider's
        // contract changes (it no longer short-circuits to null) and
        // the test author should swap to a Hive-backed scenario.
        expect(
          kGlideCoachEnabled,
          isFalse,
          reason:
              'This test pins the production contract. When the master '
              'flag flips, replace this assertion with a Hive setup that '
              'verifies the evaluator is constructed.',
        );

        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          container.read(glideCoachEvaluatorProvider),
          isNull,
          reason:
              'With kGlideCoachEnabled == false the provider MUST return '
              'null so consumers (trip_recording_provider) can early-out '
              'cleanly without touching Hive or the Overpass client.',
        );
      },
    );
  });
}
