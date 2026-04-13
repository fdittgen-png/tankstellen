import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vehicle_ev_section.dart';

void main() {
  group('VehicleEvSection', () {
    late TextEditingController batteryCtrl;
    late TextEditingController maxKwCtrl;
    late TextEditingController minSocCtrl;
    late TextEditingController maxSocCtrl;
    late Set<ConnectorType> connectors;

    setUp(() {
      batteryCtrl = TextEditingController(text: '75');
      maxKwCtrl = TextEditingController(text: '250');
      minSocCtrl = TextEditingController(text: '20');
      maxSocCtrl = TextEditingController(text: '80');
      connectors = {ConnectorType.values.first};
    });

    tearDown(() {
      batteryCtrl.dispose();
      maxKwCtrl.dispose();
      minSocCtrl.dispose();
      maxSocCtrl.dispose();
    });

    Future<void> pumpSection(
      WidgetTester tester, {
      ValueChanged<ConnectorType>? onToggle,
      String? Function(String?)? validator,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VehicleEvSection(
                batteryController: batteryCtrl,
                maxChargingKwController: maxKwCtrl,
                minSocController: minSocCtrl,
                maxSocController: maxSocCtrl,
                connectors: connectors,
                onToggleConnector: onToggle ?? (_) {},
                numberValidator: validator ?? (_) => null,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders all four numeric inputs + connector chips',
        (tester) async {
      await pumpSection(tester);
      // 4 numeric fields: battery, max kw, min soc, max soc
      expect(find.byType(TextFormField), findsNWidgets(4));
      // One FilterChip per connector type
      expect(
        find.byType(FilterChip),
        findsNWidgets(ConnectorType.values.length),
      );
    });

    testWidgets('initial controller values populate the fields',
        (tester) async {
      await pumpSection(tester);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
    });

    testWidgets('tapping an unselected connector chip invokes onToggleConnector',
        (tester) async {
      ConnectorType? captured;
      // Pick a connector that is NOT preselected.
      final unselected = ConnectorType.values
          .firstWhere((c) => !connectors.contains(c));

      await pumpSection(tester, onToggle: (c) => captured = c);

      await tester.tap(find.text(unselected.label));
      await tester.pump();

      expect(captured, unselected);
    });

    testWidgets('selected connectors render in selected state', (tester) async {
      await pumpSection(tester);
      final selected = ConnectorType.values.first;
      final chip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text(selected.label),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('numberValidator is wired to the battery + max kw fields',
        (tester) async {
      var calls = 0;
      await pumpSection(
        tester,
        validator: (_) {
          calls++;
          return null;
        },
      );
      // Find both number-bearing TextFormFields (the soc fields use a
      // bare TextInputType.number with no validator).
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .where((f) => f.validator != null)
          .toList();
      expect(fields, hasLength(2),
          reason: 'battery + max charging power should both be validated');
      for (final f in fields) {
        f.validator!('1.5');
      }
      expect(calls, 2);
    });
  });
}
