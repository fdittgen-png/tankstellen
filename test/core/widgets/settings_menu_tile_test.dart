import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/settings_menu_tile.dart';

void main() {
  group('SettingsMenuTile', () {
    Future<void> pumpTile(
      WidgetTester tester, {
      String title = 'My vehicles',
      String subtitle = 'Battery, connectors, charging',
      IconData icon = Icons.directions_car,
      VoidCallback? onTap,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsMenuTile(
              icon: icon,
              title: title,
              subtitle: subtitle,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders the supplied title and subtitle', (tester) async {
      await pumpTile(tester);
      expect(find.text('My vehicles'), findsOneWidget);
      expect(find.text('Battery, connectors, charging'), findsOneWidget);
    });

    testWidgets('renders the supplied leading icon', (tester) async {
      await pumpTile(tester, icon: Icons.privacy_tip);
      expect(find.byIcon(Icons.privacy_tip), findsOneWidget);
    });

    testWidgets('renders the trailing chevron_right', (tester) async {
      await pumpTile(tester);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('forwards taps on the tile to onTap', (tester) async {
      var tapped = false;
      await pumpTile(tester, onTap: () => tapped = true);
      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('renders the title in a bold titleSmall style',
        (tester) async {
      await pumpTile(tester);
      final text = tester.widget<Text>(find.text('My vehicles'));
      expect(text.style?.fontWeight, FontWeight.bold);
    });
  });
}
