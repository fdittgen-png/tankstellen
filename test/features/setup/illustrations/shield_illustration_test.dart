import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/illustrations/shield_illustration.dart';

import '../../../helpers/pump_app.dart';

/// #593 — Onboarding illustration placeholder for the Completion /
/// privacy step. The drop-in-shield motif matches the adaptive app icon
/// and the splash so the brand identity reads as a single gesture.
void main() {
  testWidgets('renders shield + fuel drop with theme colors',
      (tester) async {
    await pumpApp(tester, const ShieldIllustration());

    expect(find.byIcon(Icons.verified_user), findsOneWidget);
    expect(find.byIcon(Icons.water_drop), findsOneWidget);
  });

  testWidgets('shield uses primary, drop uses onPrimary', (tester) async {
    await pumpApp(tester, const ShieldIllustration());
    final ctx = tester.element(find.byType(ShieldIllustration));
    final scheme = Theme.of(ctx).colorScheme;

    final shield = tester.widget<Icon>(find.byIcon(Icons.verified_user));
    final drop = tester.widget<Icon>(find.byIcon(Icons.water_drop));

    expect(shield.color, scheme.primary);
    expect(drop.color, scheme.onPrimary);
  });

  testWidgets('honors size override', (tester) async {
    await pumpApp(tester, const ShieldIllustration(size: 120));
    final box = tester.getSize(find.byType(ShieldIllustration));
    expect(box.width, 120);
    expect(box.height, 120);
  });
}
