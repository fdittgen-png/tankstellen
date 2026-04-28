import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_pinned_save_bar.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [FillUpPinnedSaveBar] (#751 phase 2 / #563 extraction).
/// The bar is a thin shell — a `Material` + `SafeArea` around a single
/// `FilledButton.icon`. Exists so the Save CTA is always one tap away
/// regardless of how far the user has scrolled the form. The tests
/// guard the localised label, the icon, and the callback contract.
void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required VoidCallback onSave,
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          // Keep the bottom-bar slot to mirror how the screen mounts it.
          bottomNavigationBar: FillUpPinnedSaveBar(onSave: onSave),
          body: const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('renders the localised Save label and the save icon',
      (tester) async {
    await pumpBar(tester, onSave: () {});
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.save_outlined), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('tap fires onSave exactly once', (tester) async {
    var taps = 0;
    await pumpBar(tester, onSave: () => taps++);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(taps, 1,
        reason:
            'The pinned bar is a one-shot Save trigger — one tap, one '
            'callback. Multiple firings would duplicate the fill-up record.');
  });
}
