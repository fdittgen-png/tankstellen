// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/feature_management/application/app_profile_provider.dart';
import 'package:tankstellen/features/feature_management/data/app_profile_repository.dart';
import 'package:tankstellen/features/feature_management/domain/app_profile.dart';
import 'package:tankstellen/features/setup/presentation/screens/onboarding_wizard_screen.dart';
import 'package:tankstellen/features/setup/presentation/widgets/onboarding_ios_standby_step.dart';
import 'package:tankstellen/features/setup/presentation/widgets/onboarding_progress_indicator.dart';
import 'package:tankstellen/features/setup/presentation/widgets/profile_choice_step.dart';
import 'package:tankstellen/features/setup/providers/onboarding_obd2_connector.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import '../../../../helpers/mock_providers.dart';

/// Wizard step layout under #1517 / #1518:
///
/// | idx | Basic | Medium | Full (these tests) |
/// | --- | :-: | :-: | :-: |
/// | 0 — Profile choice | ✓ | ✓ | ✓ |
/// | 1 — Country & Language | ✓ | ✓ | ✓ |
/// | 2 — Vehicle | — | ✓ | ✓ |
/// | 3 — OBD2 | — | — | ✓ |
/// | 4 — Preferences | ✓ | ✓ | ✓ |
/// | 5 — Landing screen | ✓ | ✓ | ✓ |
/// | 6 — API key (cond) | cond | cond | cond |
/// | 7 — Done | ✓ | ✓ | ✓ |
///
/// All flow tests below boot the wizard with `AppProfile.full` so every
/// step is visible — that exercises the most steps in one test and
/// matches the historical 8-step / 7-step shape the suite already
/// asserts. Step-gating per profile is covered by dedicated tests at
/// the bottom of this file.
void main() {
  group('OnboardingWizardScreen', () {
    late List<Object> overrides;

    setUp(() {
      final std = standardTestOverrides();
      overrides = [
        ...std.overrides,
        // #816 — the OBD2 step is part of the default wizard flow. Tests
        // that don't exercise the connect path still need the provider
        // overridden so the widget's `ref.read` is cheap and doesn't
        // reach into the real Bluetooth stack.
        onboardingObd2ConnectorProvider
            .overrideWithValue(_NullObd2Connector()),
        // #1517 — pre-select the Full profile so every wizard step is
        // visible. The profile-choice step itself is covered by
        // `profile_choice_step_test.dart`.
        appProfileRepositoryProvider
            .overrideWithValue(_FullProfileRepository()),
      ];
      when(() => std.mockStorage.isSetupComplete).thenReturn(false);
      when(() => std.mockStorage.isSetupSkipped).thenReturn(false);
      when(() => std.mockStorage.hasApiKey()).thenReturn(false);
    });

    Future<void> pumpWizard(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides.cast(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: OnboardingWizardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows profile-choice step initially with Sparkilo wordmark',
        (tester) async {
      await pumpWizard(tester);

      expect(find.byType(ProfileChoiceStep), findsOneWidget);
      expect(find.text('Sparkilo'), findsOneWidget);
      // Three preset cards visible.
      expect(find.byKey(const Key('profileCard_basic')), findsOneWidget);
      expect(find.byKey(const Key('profileCard_medium')), findsOneWidget);
      expect(find.byKey(const Key('profileCard_full')), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('shows progress indicator with 8 steps under Full profile',
        (tester) async {
      await pumpWizard(tester);

      expect(find.byType(OnboardingProgressIndicator), findsOneWidget);
      // 8 steps for Germany (Profile, Country, Vehicle, OBD2,
      // Preferences, Landing, API Key, Done). Vehicle now BEFORE OBD2
      // (#1518 — flipped from the prior order).
      expect(find.text('1 / 8'), findsOneWidget);
    });

    testWidgets('does not show Back button on first step', (tester) async {
      await pumpWizard(tester);

      expect(find.text('Back'), findsNothing);
    });

    testWidgets('navigates to second step on Next tap', (tester) async {
      await pumpWizard(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Now on step 2: country/language
      expect(find.text('2 / 8'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
    });

    testWidgets('Back button returns to previous step', (tester) async {
      await pumpWizard(tester);

      // Go to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 8'), findsOneWidget);

      // Go back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 8'), findsOneWidget);
    });

    testWidgets('shows Skip button on API key step', (tester) async {
      await pumpWizard(tester);

      // Profile -> Country -> Vehicle -> OBD2 -> Preferences -> Landing -> API
      await tester.tap(find.text('Next')); // to Country
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // to Vehicle
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // past Vehicle
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // past OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // to Landing
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // to API Key
      await tester.pumpAndSettle();

      // Step 7: API key (skippable)
      expect(find.text('7 / 8'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Skip button advances past API key step', (tester) async {
      await pumpWizard(tester);

      // Reach API key step.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicle
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // Preferences
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // Landing
      await tester.pumpAndSettle();

      expect(find.text('7 / 8'), findsOneWidget);

      // Skip API key
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('8 / 8'), findsOneWidget);
      expect(find.text('All set!'), findsOneWidget);
    });

    testWidgets('last step shows Get started button', (tester) async {
      await pumpWizard(tester);

      // Navigate to last step skipping Vehicle + OBD2 + API Key.
      await tester.tap(find.text('Next')); // Country
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // Vehicle
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // past Vehicle
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // past OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // Preferences
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // Landing
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // API Key
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('7-step flow when country does not require API key',
        (tester) async {
      final std = standardTestOverrides(country: Countries.france);
      when(() => std.mockStorage.isSetupComplete).thenReturn(false);
      when(() => std.mockStorage.isSetupSkipped).thenReturn(false);
      when(() => std.mockStorage.hasApiKey()).thenReturn(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...std.overrides,
            onboardingObd2ConnectorProvider
                .overrideWithValue(_NullObd2Connector()),
            appProfileRepositoryProvider
                .overrideWithValue(_FullProfileRepository()),
          ].cast(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: OnboardingWizardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 7 steps (Profile, Country, Vehicle, OBD2, Preferences, Landing, Done).
      expect(find.text('1 / 7'), findsOneWidget);

      // Navigate through all steps, skipping Vehicle + OBD2.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicle
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on completion step
      expect(find.text('7 / 7'), findsOneWidget);
      expect(find.text('All set!'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('no Skip button on profile-choice step', (tester) async {
      await pumpWizard(tester);

      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('no Skip button on country/language step', (tester) async {
      await pumpWizard(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('preferences step shows fuel type chips', (tester) async {
      await pumpWizard(tester);

      // Preferences is step 5 (after Profile/Country/Vehicle/OBD2).
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicle
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();

      expect(find.text('5 / 8'), findsOneWidget);
      expect(find.text('Your preferences'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('landing screen step shows options', (tester) async {
      await pumpWizard(tester);

      // Landing is step 6.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicle
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // Preferences
      await tester.pumpAndSettle();

      expect(find.text('6 / 8'), findsOneWidget);
      expect(find.text('Home screen'), findsOneWidget);
    });

    testWidgets(
        'vehicles step appears BEFORE obd2 (step 3) (#1518 flipped order)',
        (tester) async {
      await pumpWizard(tester);

      // Vehicle is step 3 — after Profile + Country.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('3 / 8'), findsOneWidget);
      expect(find.text('My vehicles (optional)'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('obd2 step sits AFTER vehicles (step 4)', (tester) async {
      await pumpWizard(tester);

      // OBD2 is now step 4 — after Profile + Country + Vehicle.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicle
      await tester.pumpAndSettle();

      expect(find.text('4 / 8'), findsOneWidget);
      expect(find.text('Connect your OBD2 adapter'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });
  });

  group('OnboardingWizardScreen — iOS standby step (#1542 phase 6)', () {
    // `debugDefaultTargetPlatformOverride` is verified by the test
    // framework before tearDown callbacks fire, so we set it at the
    // top of each test and reset before returning via try/finally.

    Future<void> pumpIosWizard(WidgetTester tester) async {
      final std = standardTestOverrides();
      when(() => std.mockStorage.isSetupComplete).thenReturn(false);
      when(() => std.mockStorage.isSetupSkipped).thenReturn(false);
      when(() => std.mockStorage.hasApiKey()).thenReturn(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...std.overrides,
            onboardingObd2ConnectorProvider
                .overrideWithValue(_NullObd2Connector()),
            appProfileRepositoryProvider
                .overrideWithValue(_FullProfileRepository()),
          ].cast(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: OnboardingWizardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'on iOS, Full profile, German country: 9 steps total (extra iOS '
      'standby explainer between Vehicle and OBD2)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await pumpIosWizard(tester);
          // 8 → 9: the platform-specific step is included.
          expect(find.text('1 / 9'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'walking past Vehicle lands on the iOS standby step (not OBD2)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await pumpIosWizard(tester);
          await tester.tap(find.text('Next')); // → Country
          await tester.pumpAndSettle();
          await tester.tap(find.text('Next')); // → Vehicle
          await tester.pumpAndSettle();
          await tester.tap(find.text('Skip')); // past Vehicle
          await tester.pumpAndSettle();

          expect(find.byType(OnboardingIosStandbyStep), findsOneWidget);
          expect(
            find.text("Stay out of the app — but don't quit it."),
            findsOneWidget,
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'on iOS the OBD2 step is informational-only: no wizard Skip, no '
      'Connect / Maybe later, Next advances (App Review 5.1.1(iv), #3535)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await pumpIosWizard(tester);
          await tester.tap(find.text('Next')); // → Country
          await tester.pumpAndSettle();
          await tester.tap(find.text('Next')); // → Vehicle
          await tester.pumpAndSettle();
          await tester.tap(find.text('Skip')); // past Vehicle
          await tester.pumpAndSettle();
          await tester.tap(find.text('Next')); // standby → OBD2
          await tester.pumpAndSettle();

          expect(find.text('5 / 9'), findsOneWidget);
          // Apple forbids the "Connect" + "maybe later/skip" pattern in
          // front of a permission request — neither may render on iOS.
          expect(find.text('Connect adapter'), findsNothing);
          expect(find.text('Maybe later'), findsNothing);
          expect(find.text('Skip'), findsNothing);

          // The wizard's neutral Next advances past the step.
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(find.text('6 / 9'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });
}

/// Test-only repo that pretends the user picked [AppProfile.full] on a
/// previous run. All wizard tests above boot with this so every step
/// is in the visible step list.
class _FullProfileRepository implements AppProfileRepository {
  @override
  AppProfile? load() => AppProfile.full;
  @override
  Future<void> save(AppProfile profile) async {}
  @override
  bool get isEmpty => false;
}

/// Test-only connector that never connects — the wizard navigation
/// tests just need the provider satisfied; they don't exercise the
/// picker path (that's covered by the dedicated OBD2 step test).
class _NullObd2Connector implements OnboardingObd2Connector {
  @override
  Future<OnboardingObd2Session?> connect(_) async => null;

  @override
  Future<String?> readVin(_) async => null;
}
