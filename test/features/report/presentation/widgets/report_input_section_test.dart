import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/report/presentation/widgets/report_input_section.dart';
import 'package:tankstellen/features/report/presentation/screens/report_screen.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  late TextEditingController price;
  late TextEditingController text;

  setUp(() {
    price = TextEditingController();
    text = TextEditingController();
  });

  tearDown(() {
    price.dispose();
    text.dispose();
  });

  Widget build({required ReportType? type}) => ReportInputSection(
        selectedType: type,
        priceController: price,
        textController: text,
      );

  group('ReportInputSection', () {
    testWidgets('renders nothing when no type is selected',
        (tester) async {
      await pumpApp(tester, build(type: null));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('price type → renders a single numeric TextField with '
        'the € prefix', (tester) async {
      await pumpApp(tester, build(type: ReportType.wrongE10));

      final fields = find.byType(TextField);
      expect(fields, findsOneWidget);

      final field = tester.widget<TextField>(fields);
      final decoration = field.decoration!;
      expect(decoration.prefixText, '\u20ac ');
      // Numeric keyboard is part of the contract — the endpoint
      // parses the payload as a double.
      expect(field.keyboardType,
          const TextInputType.numberWithOptions(decimal: true));
    });

    testWidgets('price input flows into the priceController',
        (tester) async {
      await pumpApp(tester, build(type: ReportType.wrongDiesel));
      await tester.enterText(find.byType(TextField), '1.459');
      expect(price.text, '1.459');
      expect(text.text, '');
    });

    testWidgets('text type → renders a single TextField with the '
        'correction-text ValueKey', (tester) async {
      await pumpApp(tester, build(type: ReportType.wrongName));

      expect(
        find.byKey(const ValueKey('report-correction-text-field')),
        findsOneWidget,
      );
      // No prefix text on the free-text field.
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('report-correction-text-field')),
      );
      expect(field.decoration?.prefixText, isNull);
      expect(field.textCapitalization, TextCapitalization.sentences);
    });

    testWidgets('text input flows into the textController',
        (tester) async {
      await pumpApp(tester, build(type: ReportType.wrongAddress));
      await tester.enterText(
        find.byKey(const ValueKey('report-correction-text-field')),
        '12 Rue de la Paix',
      );
      expect(text.text, '12 Rue de la Paix');
      expect(price.text, '');
    });

    testWidgets('status type renders nothing (no payload required)',
        (tester) async {
      await pumpApp(tester, build(type: ReportType.wrongStatusOpen));
      expect(find.byType(TextField), findsNothing);
    });
  });
}
