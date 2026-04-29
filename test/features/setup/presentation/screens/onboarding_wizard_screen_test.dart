import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/setup/presentation/screens/onboarding_wizard_screen.dart';
import 'package:tankstellen/features/setup/presentation/widgets/onboarding_progress_indicator.dart';
import 'package:tankstellen/features/setup/presentation/widgets/welcome_step.dart';
import 'package:tankstellen/features/setup/providers/onboarding_obd2_connector.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import '../../../../helpers/mock_providers.dart';

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
      ];
      // Default: Germany (requires API key) => 8 steps
      // (Welcome, Country, OBD2, Vehicles, Preferences, Landing, API Key, Done)
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

    testWidgets('shows welcome step initially', (tester) async {
      await pumpWizard(tester);

      expect(find.byType(WelcomeStep), findsOneWidget);
      expect(find.text('Fuel Prices'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('shows progress indicator', (tester) async {
      await pumpWizard(tester);

      expect(
        find.byType(OnboardingProgressIndicator),
        findsOneWidget,
      );
      // 8 steps for Germany (Welcome, Country, OBD2, Vehicles,
      // Preferences, Landing, API Key, Done). The OBD2 adapter step
      // (#816) sits BEFORE Vehicles so a successful VIN read can skip
      // the manual vehicle entry entirely.
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

      // Welcome -> Country -> OBD2 -> Vehicles -> Preferences -> Landing
      await tester.tap(find.text('Next')); // to Country
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // to OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // past OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // past Vehicles
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

      // Reach API key step via: Next, Next, Skip OBD2, Skip Vehicles, Next, Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicles
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
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

      // Navigate to last step skipping OBD2 + Vehicles + API Key.
      await tester.tap(find.text('Next')); // Country
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // past OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // past Vehicles
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

      // 7 steps (Welcome, Country, OBD2, Vehicles, Preferences,
      // Landing, Done). #816 — OBD2 is part of every country's flow.
      expect(find.text('1 / 7'), findsOneWidget);

      // Navigate through all steps, skipping OBD2 + Vehicles.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicles
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

    testWidgets('no Skip button on welcome step', (tester) async {
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

      // Preferences is step 5 (after Welcome/Country/OBD2/Vehicles).
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicles
      await tester.pumpAndSettle();

      expect(find.text('5 / 8'), findsOneWidget);
      expect(find.text('Your preferences'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('landing screen step shows options', (tester) async {
      await pumpWizard(tester);

      // Landing is step 6 (after Welcome/Country/OBD2/Vehicles/Preferences).
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // Vehicles
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next')); // Preferences
      await tester.pumpAndSettle();

      expect(find.text('6 / 8'), findsOneWidget);
      expect(find.text('Home screen'), findsOneWidget);
    });

    testWidgets('obd2 step appears BEFORE vehicles (step 3) (#816)',
        (tester) async {
      await pumpWizard(tester);

      // OBD2 is step 3 — after Welcome + Country.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('3 / 8'), findsOneWidget);
      expect(find.text('Connect your OBD2 adapter'), findsOneWidget);
      // Skip + Maybe-later both present — wizard skip fires
      // [_advanceFromObd2] which hands control to the manual vehicle
      // step below.
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('vehicles step sits AFTER obd2 (step 4)',
        (tester) async {
      await pumpWizard(tester);

      // Vehicles is now step 4 — after Welcome + Country + OBD2.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip')); // OBD2
      await tester.pumpAndSettle();

      expect(find.text('4 / 8'), findsOneWidget);
      expect(find.text('My vehicles (optional)'), findsOneWidget);
      // Vehicles step is skippable.
      expect(find.text('Skip'), findsOneWidget);
    });
  });
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
