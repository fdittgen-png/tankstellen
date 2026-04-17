import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/price_sanity.dart';
import 'package:tankstellen/core/widgets/price_warning_badge.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PriceWarningBadge', () {
    testWidgets('renders nothing when result is ok', (tester) async {
      await pumpApp(
        tester,
        const PriceWarningBadge(result: PriceSanityResult.ok),
      );
      // ok → SizedBox.shrink, no icon
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('shows orange warning + tooltip for suspiciousLow',
        (tester) async {
      await pumpApp(
        tester,
        const PriceWarningBadge(
          result: PriceSanityResult.suspiciousLow,
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.warning_amber));
      expect(icon.color, Colors.orange);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, contains('low'));
    });

    testWidgets('shows red warning + tooltip for suspiciousHigh',
        (tester) async {
      await pumpApp(
        tester,
        const PriceWarningBadge(
          result: PriceSanityResult.suspiciousHigh,
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.warning_amber));
      expect(icon.color, Colors.red);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, contains('high'));
    });

    testWidgets('shows trending_up + tooltip for aboveAverage',
        (tester) async {
      await pumpApp(
        tester,
        const PriceWarningBadge(
          result: PriceSanityResult.aboveAverage,
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.trending_up));
      expect(icon.color, Colors.orange);
      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, contains('average'));
    });

    testWidgets('uses a compact 14-px icon size', (tester) async {
      // Keeps the badge readable at the card density the station list
      // uses — the visual contract here is intentional and worth
      // pinning so a future theme refactor doesn't accidentally bloat
      // the row.
      await pumpApp(
        tester,
        const PriceWarningBadge(
          result: PriceSanityResult.suspiciousLow,
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.warning_amber));
      expect(icon.size, 14);
    });
  });
}
