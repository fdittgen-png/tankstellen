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
      // Default: Germany (requires API key) => 4 steps
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
      // Shows step counter
      expect(find.text('1 / 4'), findsOneWidget);
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
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      // Country selector should be visible
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
    });

    testWidgets('Back button returns to previous step', (tester) async {
      await pumpWizard(tester);

      // Go to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 4'), findsOneWidget);

      // Go back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 4'), findsOneWidget);
    });

    testWidgets('shows Skip button on API key step', (tester) async {
      await pumpWizard(tester);

      // Step 1 -> 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2 -> 3 (API key step)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('3 / 4'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Skip button advances past API key step', (tester) async {
      await pumpWizard(tester);

      // Navigate to API key step (step 3)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('3 / 4'), findsOneWidget);

      // Skip
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.text('All set!'), findsOneWidget);
    });

    testWidgets('last step shows Get started button', (tester) async {
      await pumpWizard(tester);

      // Navigate to last step
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('3-step flow when country does not require API key',
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

      // Should show 3 steps (no API key step)
      expect(find.text('1 / 3'), findsOneWidget);

      // Step 1 -> 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);

      // No Skip button (country/language is not skippable)
      expect(find.text('Skip'), findsNothing);

      // Step 2 -> 3 (completion)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
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
  });
}
