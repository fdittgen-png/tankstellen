import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/illustrations/globe_illustration.dart';

import '../../../helpers/pump_app.dart';

/// #593 — Onboarding illustration placeholder for the Country/Language
/// step. Verifies:
///   * The widget renders without throwing.
///   * It contains the expected `Icons.public` hero glyph.
///   * The hero glyph is tinted with the theme's primary color (so the
///     illustration reacts to a theme change and stays on-brand).
void main() {
  testWidgets('renders with Icons.public tinted primary', (tester) async {
    await pumpApp(tester, const GlobeIllustration());

    final globe = find.byIcon(Icons.public);
    expect(globe, findsOneWidget);

    final widget = tester.widget<Icon>(globe);
    // The icon color must come from the theme — never hardcoded.
    expect(widget.color, isNotNull);

    // Markers arranged around the globe — three fuel-pump markers.
    expect(find.byIcon(Icons.local_gas_station), findsNWidgets(3));
  });

  testWidgets('matches ColorScheme.primary', (tester) async {
    await pumpApp(tester, const GlobeIllustration());
    final ctx = tester.element(find.byType(GlobeIllustration));
    final primary = Theme.of(ctx).colorScheme.primary;
    final globe = tester.widget<Icon>(find.byIcon(Icons.public));
    expect(globe.color, primary);
  });

  testWidgets('honors size override', (tester) async {
    await pumpApp(tester, const GlobeIllustration(size: 140));
    final box = tester.getSize(find.byType(GlobeIllustration));
    expect(box.width, 140);
    expect(box.height, 140);
  });
}
