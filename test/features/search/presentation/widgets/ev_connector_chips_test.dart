import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_connector_chips.dart';

void main() {
  group('EvConnectorChips', () {
    Future<void> pumpChips(
      WidgetTester tester, {
      required List<String> connectors,
      int? maxConnectors,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EvConnectorChips(
              connectors: connectors,
              maxConnectors: maxConnectors ?? 3,
            ),
          ),
        ),
      );
    }

    testWidgets('renders one pill per connector type', (tester) async {
      await pumpChips(tester, connectors: const ['CCS', 'Type 2']);
      expect(find.text('CCS'), findsOneWidget);
      expect(find.text('Type 2'), findsOneWidget);
    });

    testWidgets('caps the visible chips at maxConnectors', (tester) async {
      await pumpChips(
        tester,
        connectors: const ['CCS', 'Type 2', 'CHAdeMO', 'Tesla'],
        maxConnectors: 2,
      );
      // First two appear, last two are dropped.
      expect(find.text('CCS'), findsOneWidget);
      expect(find.text('Type 2'), findsOneWidget);
      expect(find.text('CHAdeMO'), findsNothing);
      expect(find.text('Tesla'), findsNothing);
    });

    testWidgets('returns brand colors from EvConnectorChips.colorFor',
        (tester) async {
      expect(EvConnectorChips.colorFor('CCS'), const Color(0xFF2196F3));
      expect(EvConnectorChips.colorFor('Type 2'), const Color(0xFF4CAF50));
      expect(EvConnectorChips.colorFor('CHAdeMO'), const Color(0xFFFF9800));
      expect(EvConnectorChips.colorFor('Tesla Supercharger'),
          const Color(0xFFE91E63));
    });

    testWidgets('falls back to neutral grey for unknown connector types',
        (tester) async {
      expect(EvConnectorChips.colorFor('Mystery Plug'),
          const Color(0xFF757575));
    });

    testWidgets('renders nothing visible when the connector list is empty',
        (tester) async {
      await pumpChips(tester, connectors: const []);
      // The Wrap still exists, but no Container chips inside it.
      expect(
        find.descendant(
          of: find.byType(EvConnectorChips),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
    });

    testWidgets(
        'exposes a group Semantics label listing connectors (#566 a11y)',
        (tester) async {
      await pumpChips(tester, connectors: const ['CCS', 'Type 2']);
      final handle = tester.ensureSemantics();

      // Parent Semantics announces the whole group — no chip-by-chip spam.
      expect(
        find.bySemanticsLabel('Available connectors: CCS, Type 2'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('empty list still exposes "no information" Semantics label',
        (tester) async {
      await pumpChips(tester, connectors: const []);
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel('No connector information'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
