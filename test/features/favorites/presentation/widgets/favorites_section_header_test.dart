import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorites_section_header.dart';

void main() {
  group('FavoritesSectionHeader', () {
    Future<void> pumpHeader(
      WidgetTester tester, {
      required IconData icon,
      required String label,
      EdgeInsets? padding,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoritesSectionHeader(
              icon: icon,
              label: label,
              padding: padding ??
                  const EdgeInsets.fromLTRB(16, 12, 16, 4),
            ),
          ),
        ),
      );
    }

    testWidgets('renders the supplied label and icon', (tester) async {
      await pumpHeader(
        tester,
        icon: Icons.ev_station,
        label: 'EV Charging',
      );
      expect(find.text('EV Charging'), findsOneWidget);
      expect(find.byIcon(Icons.ev_station), findsOneWidget);
    });

    testWidgets('uses the theme primary color for the icon', (tester) async {
      const primary = Color(0xFF112233);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: primary),
          ),
          home: const Scaffold(
            body: FavoritesSectionHeader(
              icon: Icons.local_gas_station,
              label: 'Fuel Stations',
            ),
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, primary);
    });

    testWidgets('honours a custom padding override', (tester) async {
      const padding = EdgeInsets.fromLTRB(20, 4, 8, 0);
      await pumpHeader(
        tester,
        icon: Icons.local_gas_station,
        label: 'Fuel Stations',
        padding: padding,
      );
      final paddingWidget = tester.widget<Padding>(find.byType(Padding).first);
      expect(paddingWidget.padding, padding);
    });

    testWidgets('default padding matches the original screen layout',
        (tester) async {
      await pumpHeader(
        tester,
        icon: Icons.local_gas_station,
        label: 'Fuel Stations',
      );
      final paddingWidget = tester.widget<Padding>(find.byType(Padding).first);
      expect(paddingWidget.padding,
          const EdgeInsets.fromLTRB(16, 12, 16, 4));
    });
  });
}
