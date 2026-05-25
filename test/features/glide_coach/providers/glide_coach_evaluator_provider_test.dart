// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/glide_coach/providers/glide_coach_evaluator_provider.dart';

void main() {
  group('glideCoachEvaluatorProvider (#1125 phase 3b)', () {
    test(
      'returns null when Feature.glideCoach is disabled (production default)',
      () {
        // Feature.glideCoach is default-off in the manifest (#1824), so
        // a bare container has the feature disabled and the provider
        // short-circuits to null without touching Hive or Overpass.
        final container = ProviderContainer();
        addTearDown(container.dispose);

        expect(
          container.read(glideCoachEvaluatorProvider),
          isNull,
          reason:
              'With Feature.glideCoach disabled the provider MUST return '
              'null so consumers (trip_recording_provider) can early-out '
              'cleanly without touching Hive or the Overpass client.',
        );
      },
    );
  });
}
