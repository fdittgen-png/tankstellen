import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/discard_changes_dialog.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Tests for [showDiscardChangesDialog] (#1693) — the unsaved-changes
/// confirm dialog shared by the fill-up and vehicle-edit forms.

void main() {
  /// Pumps a button that opens the dialog; [resultSink] captures the
  /// dialog's resolved outcome.
  Future<void> pumpOpener(
    WidgetTester tester,
    void Function(bool) resultSink,
  ) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              resultSink(await showDiscardChangesDialog(context));
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the title, body and both actions', (tester) async {
    await pumpOpener(tester, (_) {});

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(find.textContaining('unsaved changes'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
    expect(find.text('Keep editing'), findsOneWidget);
  });

  testWidgets('tapping Discard resolves true', (tester) async {
    bool? result;
    await pumpOpener(tester, (r) => result = r);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('tapping Keep editing resolves false', (tester) async {
    bool? result;
    await pumpOpener(tester, (r) => result = r);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('dismissing the dialog (barrier tap) resolves false',
      (tester) async {
    bool? result;
    await pumpOpener(tester, (r) => result = r);

    // Tap outside the dialog to dismiss it.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(result, isFalse,
        reason: 'a dismissed dialog must be treated as "keep editing"');
  });
}
