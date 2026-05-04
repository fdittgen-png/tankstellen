import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_variance_prompt.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [showFillUpVarianceDialog] (#1401 phase 7b).
///
/// The dialog is the gate between user-typed litres and the persisted
/// [FillUp]. Three concrete outcomes:
///   - "Keep my entry" → returns [FillUpVarianceChoice.keepUser]
///   - "Use adapter value" → returns [FillUpVarianceChoice.useAdapter]
///   - dismiss / barrier tap → returns [FillUpVarianceChoice.keepUser]
///
/// We pump a tiny harness that calls the dialog from a button so the
/// dialog mounts inside a real Navigator + MaterialApp tree (the
/// production path).
void main() {
  Future<FillUpVarianceChoice?> openAndChoose(
    WidgetTester tester, {
    required String userL,
    required String adapterL,
    String? buttonText,
  }) async {
    FillUpVarianceChoice? captured;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  captured = await showFillUpVarianceDialog(
                    context: context,
                    userL: userL,
                    adapterL: adapterL,
                  );
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
    if (buttonText != null) {
      await tester.tap(find.text(buttonText));
      await tester.pumpAndSettle();
    }
    return captured;
  }

  testWidgets('renders title, body and both action buttons (en)',
      (tester) async {
    await openAndChoose(tester, userL: '40.00', adapterL: '45.00');

    expect(find.text("Doesn't match adapter reading"), findsOneWidget);
    expect(
      find.textContaining('Your entry: 40.00 L'),
      findsOneWidget,
      reason: 'body must show pre-formatted user value',
    );
    expect(
      find.textContaining('Adapter says: 45.00 L'),
      findsOneWidget,
      reason: 'body must show pre-formatted adapter value',
    );
    expect(find.text('Keep my entry'), findsOneWidget);
    expect(find.text('Use adapter value'), findsOneWidget);
  });

  testWidgets('Keep my entry returns FillUpVarianceChoice.keepUser',
      (tester) async {
    final result = await openAndChoose(
      tester,
      userL: '40.00',
      adapterL: '45.00',
      buttonText: 'Keep my entry',
    );
    expect(result, FillUpVarianceChoice.keepUser);
  });

  testWidgets('Use adapter value returns FillUpVarianceChoice.useAdapter',
      (tester) async {
    final result = await openAndChoose(
      tester,
      userL: '40.00',
      adapterL: '45.00',
      buttonText: 'Use adapter value',
    );
    expect(result, FillUpVarianceChoice.useAdapter);
  });

  testWidgets('dismiss (tap scrim) is treated as Keep my entry',
      (tester) async {
    FillUpVarianceChoice? captured;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  captured = await showFillUpVarianceDialog(
                    context: context,
                    userL: '40.00',
                    adapterL: '45.00',
                  );
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

    // Tap the scrim (offset outside the AlertDialog content) to
    // dismiss without choosing — Flutter's barrierDismissible:true
    // pops with null, which the helper coerces to keepUser so the
    // user's typed value wins by default.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(captured, FillUpVarianceChoice.keepUser);
  });
}
