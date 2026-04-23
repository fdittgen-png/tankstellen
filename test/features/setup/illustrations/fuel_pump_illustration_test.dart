import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/illustrations/fuel_pump_illustration.dart';

import '../../../helpers/pump_app.dart';

/// #593 — Onboarding illustration placeholder for the Preferences step.
/// Verifies the hero fuel-pump icon is present and theme-tinted.
void main() {
  testWidgets('renders with Icons.local_gas_station tinted primary',
      (tester) async {
    await pumpApp(tester, const FuelPumpIllustration());

    final pump = find.byIcon(Icons.local_gas_station);
    expect(pump, findsOneWidget);

    final widget = tester.widget<Icon>(pump);
    expect(widget.color, isNotNull);
  });

  testWidgets('matches ColorScheme.primary', (tester) async {
    await pumpApp(tester, const FuelPumpIllustration());
    final ctx = tester.element(find.byType(FuelPumpIllustration));
    final primary = Theme.of(ctx).colorScheme.primary;
    final pump = tester.widget<Icon>(find.byIcon(Icons.local_gas_station));
    expect(pump.color, primary);
  });

  testWidgets('honors size override', (tester) async {
    await pumpApp(tester, const FuelPumpIllustration(size: 160));
    final box = tester.getSize(find.byType(FuelPumpIllustration));
    expect(box.width, 160);
    expect(box.height, 160);
  });
}
