import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/price_legend.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PriceLegend', () {
    testWidgets('renders cheap and expensive labels', (tester) async {
      await pumpApp(tester, const PriceLegend());

      expect(find.text('cheap'), findsOneWidget);
      expect(find.text('expensive'), findsOneWidget);
    });

    testWidgets('renders green circle for cheap end', (tester) async {
      await pumpApp(tester, const PriceLegend());

      // Find decorated containers with green circle
      final containers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == Colors.green &&
              decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(containers, findsOneWidget);
    });

    testWidgets('renders red circle for expensive end', (tester) async {
      await pumpApp(tester, const PriceLegend());

      final containers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.color == Colors.red &&
              decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(containers, findsOneWidget);
    });

    testWidgets('renders gradient bar between labels', (tester) async {
      await pumpApp(tester, const PriceLegend());

      // Find the gradient container
      final gradientContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.gradient is LinearGradient;
        }
        return false;
      });
      expect(gradientContainer, findsOneWidget);
    });

    testWidgets('gradient goes from green through orange to red',
        (tester) async {
      await pumpApp(tester, const PriceLegend());

      final gradientContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          if (decoration.gradient is LinearGradient) {
            final gradient = decoration.gradient as LinearGradient;
            return gradient.colors.length == 3 &&
                gradient.colors[0] == Colors.green &&
                gradient.colors[1] == Colors.orange &&
                gradient.colors[2] == Colors.red;
          }
        }
        return false;
      });
      expect(gradientContainer, findsOneWidget);
    });
  });

  group('ZoomButton', () {
    testWidgets('renders with correct icon', (tester) async {
      await pumpApp(
        tester,
        ZoomButton(icon: Icons.add, onPressed: () {}),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await pumpApp(
        tester,
        ZoomButton(icon: Icons.add, onPressed: () => pressed = true),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('renders with correct dimensions', (tester) async {
      await pumpApp(
        tester,
        ZoomButton(icon: Icons.remove, onPressed: () {}),
      );

      final container = tester.widget<Container>(
        find.byWidgetPredicate((widget) {
          if (widget is Container && widget.constraints != null) {
            return widget.constraints!.maxWidth == 40 &&
                widget.constraints!.maxHeight == 40;
          }
          return false;
        }),
      );
      expect(container, isNotNull);
    });
  });
}
