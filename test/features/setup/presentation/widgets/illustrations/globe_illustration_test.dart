import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/illustrations/globe_illustration.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('GlobeIllustration rendering', () {
    testWidgets('renders the globe icon as the central glyph',
        (tester) async {
      await pumpApp(tester, const GlobeIllustration());

      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets(
        'renders three fuel-pump markers arranged around the globe',
        (tester) async {
      await pumpApp(tester, const GlobeIllustration());

      // Three markers at 10 / 2 / 6 o'clock hint at multi-country
      // coverage — if a refactor drops one of them, the illustration
      // silently loses its semantic weight.
      expect(find.byIcon(Icons.local_gas_station), findsNWidgets(3));
    });

    testWidgets('size parameter controls the SizedBox dimensions',
        (tester) async {
      await pumpApp(tester, const GlobeIllustration(size: 120));

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(GlobeIllustration),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 120);
      expect(sizedBox.height, 120);
    });

    testWidgets('defaults to 200dp square when no size is provided',
        (tester) async {
      await pumpApp(tester, const GlobeIllustration());

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(GlobeIllustration),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 200);
    });

    testWidgets('exposes a descriptive image Semantics label',
        (tester) async {
      await pumpApp(tester, const GlobeIllustration());

      expect(
        find.bySemanticsLabel('Globe with fuel station markers'),
        findsOneWidget,
      );
    });

    testWidgets('includes a radial-gradient backdrop behind the globe',
        (tester) async {
      await pumpApp(tester, const GlobeIllustration());

      // Locate the backdrop Container by its BoxDecoration shape. The
      // radial gradient is what stops the globe from reading as a
      // floating icon on dark backgrounds.
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(GlobeIllustration),
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
          reason: 'Globe illustration needs the radial-gradient backdrop');
    });

    testWidgets('renders without error at a small size', (tester) async {
      await pumpApp(tester, const GlobeIllustration(size: 60));

      expect(find.byType(GlobeIllustration), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
