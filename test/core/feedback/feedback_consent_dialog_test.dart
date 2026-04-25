import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/feedback/feedback_consent.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [FeedbackConsentDialog] (#952 phase 3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  Future<FeedbackConsentChoice> pumpAndTap(
    WidgetTester tester, {
    required Locale locale,
    required String buttonLabel,
  }) async {
    late FeedbackConsentChoice result;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await FeedbackConsentDialog.show(ctx);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackConsentDialog), findsOneWidget);

    await tester.tap(find.text(buttonLabel));
    await tester.pumpAndSettle();
    return result;
  }

  group('FeedbackConsentDialog (en)', () {
    testWidgets('renders title + body in English', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FeedbackConsentDialog()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Send report to GitHub?'), findsOneWidget);
      expect(
        find.textContaining('public ticket on our GitHub'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('Continue returns granted', (tester) async {
      final choice = await pumpAndTap(
        tester,
        locale: const Locale('en'),
        buttonLabel: 'Continue',
      );
      expect(choice, FeedbackConsentChoice.granted);
    });

    testWidgets('Cancel returns denied', (tester) async {
      final choice = await pumpAndTap(
        tester,
        locale: const Locale('en'),
        buttonLabel: 'Cancel',
      );
      expect(choice, FeedbackConsentChoice.denied);
    });

    testWidgets('Later returns later', (tester) async {
      final choice = await pumpAndTap(
        tester,
        locale: const Locale('en'),
        buttonLabel: 'Later',
      );
      expect(choice, FeedbackConsentChoice.later);
    });
  });

  group('FeedbackConsentDialog (fr)', () {
    testWidgets('renders the French copy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FeedbackConsentDialog()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Envoyer le rapport à GitHub ?'), findsOneWidget);
      expect(
        find.textContaining('ticket public sur notre dépôt GitHub'),
        findsOneWidget,
      );
      expect(find.text('Continuer'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);
    });
  });

  group('Persisted state after dialog choice', () {
    testWidgets('granted choice persisted by FeedbackConsent.write',
        (tester) async {
      final choice = await pumpAndTap(
        tester,
        locale: const Locale('en'),
        buttonLabel: 'Continue',
      );
      expect(choice, FeedbackConsentChoice.granted);
      // Caller persists. Mirror that here.
      await FeedbackConsent.write(FeedbackConsentState.granted);
      expect(await FeedbackConsent.read(), FeedbackConsentState.granted);
    });

    testWidgets('denied choice persisted by FeedbackConsent.write',
        (tester) async {
      final choice = await pumpAndTap(
        tester,
        locale: const Locale('en'),
        buttonLabel: 'Cancel',
      );
      expect(choice, FeedbackConsentChoice.denied);
      await FeedbackConsent.write(FeedbackConsentState.denied);
      expect(await FeedbackConsent.read(), FeedbackConsentState.denied);
    });

    testWidgets('Later does NOT mutate the persisted state',
        (tester) async {
      // Ensure starting state is unset.
      expect(await FeedbackConsent.read(), FeedbackConsentState.unset);
      final choice = await pumpAndTap(
        tester,
        locale: const Locale('en'),
        buttonLabel: 'Later',
      );
      expect(choice, FeedbackConsentChoice.later);
      // No write happened — should still be unset.
      expect(await FeedbackConsent.read(), FeedbackConsentState.unset);
    });
  });
}
