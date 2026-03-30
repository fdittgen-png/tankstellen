import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/mode_chip.dart';

void main() {
  group('ModeChip', () {
    Widget buildSubject({
      required bool selected,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ModeChip(
            label: 'Nearby',
            icon: Icons.near_me,
            selected: selected,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(buildSubject(selected: false));
      expect(find.text('Nearby'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildSubject(selected: false));
      expect(find.byIcon(Icons.near_me), findsOneWidget);
    });

    testWidgets('selected state shows bold text', (tester) async {
      await tester.pumpWidget(buildSubject(selected: true));

      final textWidget = tester.widget<Text>(find.text('Nearby'));
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('selected state uses primaryContainer background',
        (tester) async {
      await tester.pumpWidget(buildSubject(selected: true));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNot(Colors.transparent));
    });

    testWidgets('unselected state uses transparent background',
        (tester) async {
      await tester.pumpWidget(buildSubject(selected: false));
      await tester.pump(const Duration(milliseconds: 250));

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
    });

    testWidgets('unselected state uses normal font weight', (tester) async {
      await tester.pumpWidget(buildSubject(selected: false));

      final textWidget = tester.widget<Text>(find.text('Nearby'));
      expect(textWidget.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildSubject(
        selected: false,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.text('Nearby'));
      expect(tapped, isTrue);
    });
  });
}
