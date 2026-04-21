import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_notes_field.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('FillUpNotesField', () {
    Future<void> pumpField(
      WidgetTester tester, {
      required TextEditingController controller,
      Locale locale = const Locale('en'),
    }) {
      return tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FillUpNotesField(controller: controller)),
        ),
      );
    }

    testWidgets('renders the localised label and the edit-note icon',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller);
      await tester.pumpAndSettle();

      expect(find.text('Notes (optional)'), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
    });

    testWidgets('renders the French ARB label on fr locale', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpField(
        tester,
        controller: controller,
        locale: const Locale('fr'),
      );
      await tester.pumpAndSettle();

      // App ships `notesOptional: "Notes (facultatif)"` in app_fr.arb
      // (added in PR #803). The widget must route through the ARB
      // rather than hard-coding English.
      expect(find.text('Notes (facultatif)'), findsOneWidget);
    });

    testWidgets('forwards text entry through the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'pumped 30 L fast');
      expect(controller.text, 'pumped 30 L fast');
    });

    testWidgets('field is multiline with minLines:4 and maxLines:8 '
        '(#695 — user requested more room)', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpField(tester, controller: controller);
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 4);
      expect(field.maxLines, 8);
      expect(field.keyboardType, TextInputType.multiline);
      expect(field.textInputAction, TextInputAction.newline);
    });
  });
}
