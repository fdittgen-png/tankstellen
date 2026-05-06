import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/features/glide_coach/data/traffic_signal_repository.dart';
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
      'master flag wins — kGlideCoachEnabled is false in production so '
      'setEnabled(true) MUST keep state.enabled at false',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(
          glideCoachSettingsProvider.notifier,
        );
        await notifier.setEnabled(true);

        // Production today has kGlideCoachEnabled == false. The
        // layered gate dictates that an opted-in user toggle MUST
        // still surface as disabled in-memory until the master flag
        // flips. This is the safety: a stale debug-build write or a
        // future schema change cannot leak the feature on for users.
        expect(
          kGlideCoachEnabled,
          isFalse,
          reason:
              'This test is meaningful only while the master flag is '
              'false. If kGlideCoachEnabled is flipped to true in a '
              'future PR, update this test to assert the new contract.',
        );
        expect(
          container.read(glideCoachSettingsProvider).enabled,
          isFalse,
          reason:
              'kGlideCoachEnabled == false MUST gate state.enabled to '
              'false even after setEnabled(true). The user toggle is '
              'layered on top of the master flag, never below it.',
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

        // The persisted value is `true` — but the master flag is
        // false in production, so the gated state stays false. When
        // the master flag flips in a future PR, the same persisted
        // value will surface as enabled without the user having to
        // toggle again.
        expect(
          container.read(glideCoachSettingsProvider).enabled,
          kGlideCoachEnabled,
          reason:
              'Restored state must equal `persisted-true && master-flag` '
              '— production today is false on both axes once gated.',
        );
      },
    );
  });
}
