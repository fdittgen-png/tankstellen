import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/setup/presentation/screens/onboarding_wizard_screen.dart';
import 'package:tankstellen/features/setup/presentation/widgets/onboarding_progress_indicator.dart';
import 'package:tankstellen/features/setup/presentation/widgets/welcome_step.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import '../../../../helpers/mock_providers.dart';

void main() {
  group('OnboardingWizardScreen', () {
    late List<Object> overrides;

    setUp(() {
      final std = standardTestOverrides();
      overrides = std.overrides;
      // Default: Germany (requires API key) => 7 steps
      // (Welcome, Country, Preferences, Landing, Vehicles, API Key, Done)
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
      // 7 steps for Germany (Welcome, Country, Preferences, Landing,
      // Vehicles, API Key, Done)
      expect(find.text('1 / 7'), findsOneWidget);
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
      expect(find.text('2 / 7'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
    });

    testWidgets('Back button returns to previous step', (tester) async {
      await pumpWizard(tester);

      // Go to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 7'), findsOneWidget);

      // Go back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 7'), findsOneWidget);
    });

    testWidgets('shows Skip button on API key step', (tester) async {
      await pumpWizard(tester);

      // Steps 1-5: Welcome -> Country -> Preferences -> Landing -> Vehicles
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Step 6: API key (skippable)
      expect(find.text('6 / 7'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Skip button advances past API key step', (tester) async {
      await pumpWizard(tester);

      // Navigate to API key step (step 6)
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('6 / 7'), findsOneWidget);

      // Skip
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('7 / 7'), findsOneWidget);
      expect(find.text('All set!'), findsOneWidget);
    });

    testWidgets('last step shows Get started button', (tester) async {
      await pumpWizard(tester);

      // Navigate to last step (skip API key)
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('6-step flow when country does not require API key',
        (tester) async {
      final std = standardTestOverrides(country: Countries.france);
      when(() => std.mockStorage.isSetupComplete).thenReturn(false);
      when(() => std.mockStorage.isSetupSkipped).thenReturn(false);
      when(() => std.mockStorage.hasApiKey()).thenReturn(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: std.overrides.cast(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: OnboardingWizardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 6 steps (Welcome, Country, Preferences, Landing, Vehicles, Done)
      expect(find.text('1 / 6'), findsOneWidget);

      // Navigate through all steps
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Should be on completion step
      expect(find.text('6 / 6'), findsOneWidget);
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

      // Navigate to preferences step (step 3)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('3 / 7'), findsOneWidget);
      expect(find.text('Your preferences'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('landing screen step shows options', (tester) async {
      await pumpWizard(tester);

      // Navigate to landing step (step 4)
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('4 / 7'), findsOneWidget);
      expect(find.text('Home screen'), findsOneWidget);
    });

    testWidgets('vehicles step appears between landing and API key',
        (tester) async {
      await pumpWizard(tester);

      // Navigate to vehicles step (step 5 — index 4)
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('5 / 7'), findsOneWidget);
      expect(find.text('My vehicles (optional)'), findsOneWidget);
      // Vehicles step is skippable.
      expect(find.text('Skip'), findsOneWidget);
    });
  });
}
