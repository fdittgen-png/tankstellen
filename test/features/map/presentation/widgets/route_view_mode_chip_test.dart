import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_view_mode_chip.dart';

void main() {
  Widget buildChip({
    String label = 'All stations',
    IconData icon = Icons.local_gas_station,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RouteViewModeChip(
          label: label,
          icon: icon,
          selected: selected,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('RouteViewModeChip', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(buildChip(label: 'Best stops'));
      expect(find.text('Best stops'), findsOneWidget);
    });

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(buildChip(icon: Icons.star));
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('selected chip has primary container background',
        (tester) async {
      await tester.pumpWidget(buildChip(selected: true));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(decoration.color, theme.colorScheme.primaryContainer);
    });

    testWidgets('unselected chip has transparent background', (tester) async {
      await tester.pumpWidget(buildChip(selected: false));

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildChip(onTap: () => tapped = true));
      await tester.tap(find.text('All stations'));
      expect(tapped, isTrue);
    });

    testWidgets('has rounded border', (tester) async {
      await tester.pumpWidget(buildChip());

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16));
    });
  });
}
