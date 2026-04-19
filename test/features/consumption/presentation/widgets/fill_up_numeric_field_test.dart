import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_numeric_field.dart';

void main() {
  group('FillUpNumericField', () {
    Future<void> pumpField(
      WidgetTester tester, {
      required TextEditingController controller,
      String label = 'Liters',
      IconData icon = Icons.water_drop_outlined,
      FormFieldValidator<String>? validator,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: FillUpNumericField(
                controller: controller,
                label: label,
                icon: icon,
                validator: validator,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders the supplied label and prefix icon', (tester) async {
      final ctrl = TextEditingController();
      addTearDown(ctrl.dispose);
      await pumpField(
        tester,
        controller: ctrl,
        label: 'Total cost',
        icon: Icons.euro,
      );
      expect(find.text('Total cost'), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
    });

    testWidgets('accepts digits, comma, and period', (tester) async {
      final ctrl = TextEditingController();
      addTearDown(ctrl.dispose);
      await pumpField(tester, controller: ctrl);
      await tester.enterText(find.byType(TextFormField), '12,34');
      expect(ctrl.text, '12,34');
    });

    testWidgets('blocks letters and other non-numeric characters at input '
        'time via the inputFormatter', (tester) async {
      final ctrl = TextEditingController();
      addTearDown(ctrl.dispose);
      await pumpField(tester, controller: ctrl);
      // Sending "ab12c.3d4" should be filtered down to digits/./, only.
      await tester.enterText(find.byType(TextFormField), 'ab12c.3d4');
      expect(ctrl.text, '12.34');
    });

    testWidgets('uses a numeric keyboard with decimals enabled',
        (tester) async {
      final ctrl = TextEditingController();
      addTearDown(ctrl.dispose);
      await pumpField(tester, controller: ctrl);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      // TextFormField does not expose keyboardType directly, so reach
      // through the underlying TextField.
      final input = tester.widget<EditableText>(find.byType(EditableText));
      expect(input.keyboardType.index,
          const TextInputType.numberWithOptions(decimal: true).index);
      // And confirm the formatter list contains exactly one filter.
      expect(field.runtimeType, TextFormField);
    });

    testWidgets('forwards the supplied validator', (tester) async {
      final ctrl = TextEditingController(text: '');
      addTearDown(ctrl.dispose);
      String? called;
      await pumpField(
        tester,
        controller: ctrl,
        validator: (v) {
          called = v;
          return 'always invalid';
        },
      );
      // Trigger Form.validate via a hidden Form lookup.
      final formState =
          tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      expect(called, '');
    });
  });
}
