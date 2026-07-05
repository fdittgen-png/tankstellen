// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/feedback/review_prompter.dart';
import 'package:tankstellen/core/platform/app_flavor.dart';

void main() {
  group('NoopReviewPrompter (libre build)', () {
    test('reports unavailable and never performs a review request', () async {
      const prompter = NoopReviewPrompter();
      expect(await prompter.isAvailable(), isFalse);
      // Must complete without throwing or touching any plugin.
      await expectLater(prompter.requestReview(), completes);
    });
  });

  group('reviewPrompterProvider selection', () {
    test('resolves the store prompter when Google services are present', () {
      // Tests run without the FORCE_LOCATION_MANAGER dart-define, so
      // AppFlavor.isLibre is false — the provider must pick the real store
      // prompter (the libre path is selected only in the fdroid build).
      expect(AppFlavor.isLibre, isFalse);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(reviewPrompterProvider), isA<StoreReviewPrompter>());
    });

    test('is overridable for tests', () {
      final c = ProviderContainer(overrides: [
        reviewPrompterProvider.overrideWithValue(const NoopReviewPrompter()),
      ]);
      addTearDown(c.dispose);
      expect(c.read(reviewPrompterProvider), isA<NoopReviewPrompter>());
    });
  });

  group('AppFlavor', () {
    test('isLibre and hasGoogleServices are inverses', () {
      expect(AppFlavor.hasGoogleServices, !AppFlavor.isLibre);
    });
  });
}
