import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy_dashboard/privacy_data_row.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('PrivacyDataRow', () {
    testWidgets('renders icon, label and value', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDataRow(
          icon: Icons.lock,
          label: 'API key',
          value: 'Configured',
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('API key'), findsOneWidget);
      expect(find.text('Configured'), findsOneWidget);
    });

    testWidgets('value text is bolder than label', (tester) async {
      // The visual contract: the value ("Configured" / "12 items")
      // should draw the eye, so it's rendered with a heavier weight
      // than the label. Tests pin this so a theme-only refactor
      // can't silently level them out.
      await pumpApp(
        tester,
        const PrivacyDataRow(
          icon: Icons.lock,
          label: 'API key',
          value: 'Configured',
        ),
      );
      final valueText = tester.widget<Text>(find.text('Configured'));
      final labelText = tester.widget<Text>(find.text('API key'));
      final valueWeight = valueText.style?.fontWeight;
      final labelWeight = labelText.style?.fontWeight ?? FontWeight.w400;
      expect(valueWeight, FontWeight.w600);
      expect(valueWeight!.value, greaterThan(labelWeight.value));
    });

    testWidgets('icon uses the compact 18-px size', (tester) async {
      await pumpApp(
        tester,
        const PrivacyDataRow(
          icon: Icons.storage,
          label: 'Favorites',
          value: '12',
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.storage));
      expect(icon.size, 18);
    });
  });
}
