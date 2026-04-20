import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/pay_with_app_button.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PayWithAppButton', () {
    testWidgets('renders nothing for unknown brand', (tester) async {
      await pumpApp(
        tester,
        const PayWithAppButton(brand: 'Local Independent'),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('renders nothing for empty brand', (tester) async {
      await pumpApp(tester, const PayWithAppButton(brand: ''));
      expect(find.byType(FilledButton), findsNothing);
    });

    // #736 — the hardcoded brand catalog was emptied because every
    // bundled Android package id 404ed on the Play Store. Until a
    // brand is re-added with a verified id, the button never
    // renders for any brand. These tests enforce that empty state.
    testWidgets(
        '(#736) renders nothing for previously-supported brands until '
        'verified IDs land', (tester) async {
      for (final brand in const [
        'Shell',
        'BP',
        'Aral',
        'Total',
        'TotalEnergies',
        'Esso',
        'OMV',
        'Eni',
        'Repsol',
      ]) {
        await pumpApp(tester, PayWithAppButton(brand: brand));
        expect(find.byIcon(Icons.open_in_new), findsNothing,
            reason: '$brand chip must not render — catalog empty (#736)');
      }
    });
  });
}
