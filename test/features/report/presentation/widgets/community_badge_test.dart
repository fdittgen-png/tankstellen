import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/report/presentation/widgets/community_badge.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('CommunityBadge', () {
    testWidgets('renders nothing when reportCount is 0', (tester) async {
      await pumpApp(tester, const CommunityBadge(reportCount: 0));

      expect(find.byIcon(Icons.people), findsNothing);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('renders people icon + count for any positive number',
        (tester) async {
      await pumpApp(tester, const CommunityBadge(reportCount: 3));

      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('tooltip describes the 2-hour window', (tester) async {
      await pumpApp(tester, const CommunityBadge(reportCount: 5));

      final tip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tip.message, contains('5'));
      expect(tip.message, contains('2 hours'));
    });

    testWidgets('uses compact 12-px icon + 10-px text so it fits in a card',
        (tester) async {
      await pumpApp(tester, const CommunityBadge(reportCount: 1));

      final icon = tester.widget<Icon>(find.byIcon(Icons.people));
      expect(icon.size, 12);
      final text = tester.widget<Text>(find.text('1'));
      expect(text.style?.fontSize, 10);
      expect(text.style?.fontWeight, FontWeight.bold);
    });
  });
}
