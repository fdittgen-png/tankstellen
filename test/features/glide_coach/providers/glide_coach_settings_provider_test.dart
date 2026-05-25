// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/features/glide_coach/domain/entities/glide_coach_settings.dart';
import 'package:tankstellen/features/glide_coach/providers/glide_coach_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  group('GlideCoachSettingsNotifier (#1125 phase 3b)', () {
    test(
      'defaults to disabled GlideCoachSettings on first launch',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final settings = container.read(glideCoachSettingsProvider);
        expect(settings, const GlideCoachSettings());
        expect(settings.enabled, isFalse);
      },
    );

    test(
      'feature flag wins — Feature.glideCoach is off by default so '
      'setEnabled(true) MUST keep state.enabled at false',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          glideCoachSettingsProvider.notifier,
        );
        await notifier.setEnabled(true);

        // Feature.glideCoach is default-off (#1824). The layered gate
        // dictates that an opted-in user toggle MUST still surface as
        // disabled in-memory until the feature flag is enabled.
        expect(
          container.read(glideCoachSettingsProvider).enabled,
          isFalse,
          reason:
              'A disabled Feature.glideCoach MUST gate state.enabled to '
              'false even after setEnabled(true). The user toggle is '
              'layered on top of the feature flag, never below it.',
        );
      },
    );

    test(
      'persists the user-toggle write to SharedPreferences regardless '
      'of the master flag — preserving opt-in across a future flip',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(glideCoachSettingsProvider.notifier)
            .setEnabled(true);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(GlideCoachSettingsNotifier.prefsKey),
          isTrue,
          reason:
              'setEnabled(true) writes the raw user choice to '
              'SharedPreferences even with kGlideCoachEnabled false, '
              'so a future master-flag flip rehydrates the user as '
              'opted-in instead of silently losing their preference.',
        );
      },
    );

    test(
      'setEnabled(false) writes the persisted value back to false',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          GlideCoachSettingsNotifier.prefsKey: true,
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container
            .read(glideCoachSettingsProvider.notifier)
            .setEnabled(false);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(GlideCoachSettingsNotifier.prefsKey),
          isFalse,
        );
        expect(
          container.read(glideCoachSettingsProvider).enabled,
          isFalse,
        );
      },
    );

    test(
      'restores the persisted value on startup (gated by master flag)',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          GlideCoachSettingsNotifier.prefsKey: true,
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // _load fires async on build; give the microtask queue a
        // chance to settle, mirroring the themeModeSettingProvider
        // test's pattern.
        container.read(glideCoachSettingsProvider);
        await Future<void>.delayed(Duration.zero);

        // The persisted value is `true` — but Feature.glideCoach is
        // default-off, so the gated state stays false. Enabling the
        // feature later surfaces the same persisted value as enabled
        // without the user having to toggle again.
        expect(
          container.read(glideCoachSettingsProvider).enabled,
          isFalse,
          reason:
              'Restored state must equal `persisted-true && feature-flag` '
              '— with Feature.glideCoach off it gates to false.',
        );
      },
    );
  });
}
