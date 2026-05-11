import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/onboarding_ios_standby_step.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #1542 phase 6 — coverage for the iOS-only onboarding explainer.
/// The widget is platform-agnostic by construction (the platform gate
/// lives in the wizard); these tests assert it renders the title plus
/// each of the three bullets verbatim from the docs guide.
void main() {
  Future<void> pumpStep(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(body: OnboardingIosStandbyStep()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OnboardingIosStandbyStep', () {
    testWidgets('renders the title from the docs guide', (tester) async {
      await pumpStep(tester);
      expect(
        find.text("Stay out of the app — but don't quit it."),
        findsOneWidget,
      );
    });

    testWidgets('renders all three bullet titles', (tester) async {
      await pumpStep(tester);
      expect(
        find.text('Open Sparkilo once after each reboot.'),
        findsOneWidget,
      );
      expect(
        find.text("Don't swipe Sparkilo away in the app switcher."),
        findsOneWidget,
      );
      expect(
        find.text('When iOS asks for "Always" location, please say yes.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'numbers the bullets 1, 2, 3 — order matches the docs guide',
      (tester) async {
        await pumpStep(tester);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      },
    );
  });
}
