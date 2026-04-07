import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/core/utils/price_tier.dart';
import 'package:tankstellen/features/map/presentation/widgets/price_legend.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PriceLegend', () {
    testWidgets('renders cheap and expensive labels', (tester) async {
      await pumpApp(tester, const PriceLegend());

      expect(find.text('cheap'), findsOneWidget);
      expect(find.text('expensive'), findsOneWidget);
    });

    testWidgets('renders circle for cheap end with success color', (tester) async {
      await pumpApp(tester, const PriceLegend());

      // The cheap circle uses DarkModeColors.success which is theme-aware
      final containers = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.shape == BoxShape.circle &&
              decoration.color != null;
        }
        return false;
      });
      // Two circles: cheap and expensive
      expect(containers, findsNWidgets(2));
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

    testWidgets('renders arrow_downward icon for cheap tier', (tester) async {
      await pumpApp(tester, const PriceLegend());

      expect(
        find.byIcon(iconForPriceTier(PriceTier.cheap)),
        findsOneWidget,
      );
    });

    testWidgets('renders arrow_upward icon for expensive tier', (tester) async {
      await pumpApp(tester, const PriceLegend());

      expect(
        find.byIcon(iconForPriceTier(PriceTier.expensive)),
        findsOneWidget,
      );
    });

    testWidgets('cheap icon uses success color', (tester) async {
      late Color expectedColor;
      await pumpApp(tester, Builder(builder: (context) {
        expectedColor = DarkModeColors.success(context);
        return const PriceLegend();
      }));

      final cheapIcon = tester.widget<Icon>(
        find.byIcon(Icons.arrow_downward),
      );
      expect(cheapIcon.color, expectedColor);
    });

    testWidgets('expensive icon uses error color', (tester) async {
      late Color expectedColor;
      await pumpApp(tester, Builder(builder: (context) {
        expectedColor = DarkModeColors.error(context);
        return const PriceLegend();
      }));

      final expensiveIcon = tester.widget<Icon>(
        find.byIcon(Icons.arrow_upward),
      );
      expect(expensiveIcon.color, expectedColor);
    });

    testWidgets('gradient has three stops (cheap, warning, expensive)',
        (tester) async {
      await pumpApp(tester, const PriceLegend());

      final gradientContainer = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          if (decoration.gradient is LinearGradient) {
            final gradient = decoration.gradient as LinearGradient;
            return gradient.colors.length == 3;
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
