import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/illustrations/shield_illustration.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('ShieldIllustration rendering', () {
    testWidgets('renders the shield icon as the hero glyph', (tester) async {
      await pumpApp(tester, const ShieldIllustration());

      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });

    testWidgets('renders the fuel-drop icon nested inside the shield',
        (tester) async {
      await pumpApp(tester, const ShieldIllustration());

      // The water_drop icon is reused to represent a fuel drop inside
      // the shield — matching the adaptive app icon's brand motif.
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('size parameter controls the SizedBox dimensions',
        (tester) async {
      await pumpApp(tester, const ShieldIllustration(size: 160));

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(ShieldIllustration),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 160);
      expect(sizedBox.height, 160);
    });

    testWidgets('defaults to 200dp square when no size is provided',
        (tester) async {
      await pumpApp(tester, const ShieldIllustration());

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(ShieldIllustration),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 200);
    });

    testWidgets('exposes a descriptive image Semantics label',
        (tester) async {
      await pumpApp(tester, const ShieldIllustration());

      expect(
        find.bySemanticsLabel('Privacy shield with fuel drop'),
        findsOneWidget,
      );
    });

    testWidgets('includes a radial-gradient backdrop behind the shield',
        (tester) async {
      await pumpApp(tester, const ShieldIllustration());

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(ShieldIllustration),
          matching: find.byType(Container),
        ),
      );

      final hasRadialBackdrop = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.shape == BoxShape.circle &&
            decoration.gradient is RadialGradient;
      });

      expect(hasRadialBackdrop, isTrue,
          reason: 'Shield illustration needs the radial-gradient backdrop');
    });

    testWidgets('renders without error at a small size', (tester) async {
      await pumpApp(tester, const ShieldIllustration(size: 60));

      expect(find.byType(ShieldIllustration), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fuel-drop icon uses the onPrimary color (contrast against shield)',
        (tester) async {
      await pumpApp(tester, const ShieldIllustration());

      // The drop has to read against the primary-tinted shield — if
      // someone swaps it back to scheme.primary the two icons blend.
      final icons = tester.widgetList<Icon>(
        find.descendant(
          of: find.byType(ShieldIllustration),
          matching: find.byType(Icon),
        ),
      );
      final drop = icons.firstWhere((i) => i.icon == Icons.water_drop);
      final shield = icons.firstWhere((i) => i.icon == Icons.verified_user);

      // Drop + shield colors must differ so the drop stays visible.
      expect(drop.color, isNotNull);
      expect(shield.color, isNotNull);
      expect(drop.color, isNot(shield.color));
    });
  });
}
