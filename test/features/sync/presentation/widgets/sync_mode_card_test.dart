import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/sync_mode_card.dart';

import '../../../../helpers/pump_app.dart';

SyncModeCard _build({VoidCallback? onTap, Color color = Colors.blue}) =>
    SyncModeCard(
      icon: Icons.public,
      title: 'Community',
      subtitle: 'Shared with all users',
      privacyLabel: 'Lowest',
      privacyColor: color,
      onTap: onTap ?? () {},
    );

void main() {
  group('SyncModeCard', () {
    testWidgets('renders icon, title, subtitle, and privacy label',
        (tester) async {
      await pumpApp(tester, _build());

      expect(find.byIcon(Icons.public), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Shared with all users'), findsOneWidget);
      expect(find.text('Lowest'), findsOneWidget);
    });

    testWidgets('shows a chevron to hint at navigability', (tester) async {
      await pumpApp(tester, _build());
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('title uses a bold weight to anchor the card',
        (tester) async {
      await pumpApp(tester, _build());
      final title = tester.widget<Text>(find.text('Community'));
      expect(title.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('privacy label is 10-px semibold for a compact tag look',
        (tester) async {
      await pumpApp(tester, _build());
      final label = tester.widget<Text>(find.text('Lowest'));
      expect(label.style?.fontSize, 10);
      expect(label.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('tap anywhere on the card invokes onTap', (tester) async {
      var tapped = 0;
      await pumpApp(tester, _build(onTap: () => tapped++));
      await tester.tap(find.byType(InkWell));
      expect(tapped, 1);
    });

    testWidgets('privacy colour flows into the badge + icon wrapper',
        (tester) async {
      // The tint that tells the user this mode's privacy level comes
      // from `privacyColor` — pinned so the three sync modes stay
      // visually distinguishable at a glance.
      const marker = Color(0xFF00A0B4);
      await pumpApp(tester, _build(color: marker));

      final labelWidget = tester.widget<Text>(find.text('Lowest'));
      expect(labelWidget.style?.color, marker);
    });
  });
}
