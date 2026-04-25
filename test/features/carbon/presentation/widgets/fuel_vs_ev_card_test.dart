import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/unit_formatter.dart';
import 'package:tankstellen/features/carbon/domain/milestone.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/fuel_vs_ev_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('FuelVsEvCard', () {
    testWidgets('renders title, subtitle and the two row labels',
        (tester) async {
      await pumpApp(
        tester,
        const FuelVsEvCard(fuelCo2Kg: 50, distanceKm: 200),
      );

      expect(find.text('Fuel vs EV'), findsOneWidget);
      expect(
        find.text('CO2 comparison for the same distance driven'),
        findsOneWidget,
      );
      expect(find.text('Your fuel'), findsOneWidget);
      expect(find.text('Equivalent EV'), findsOneWidget);
    });

    testWidgets('renders one progress bar per data series (fuel + ev)',
        (tester) async {
      await pumpApp(
        tester,
        const FuelVsEvCard(fuelCo2Kg: 30, distanceKm: 100),
      );

      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
    });

    testWidgets('renders fuel value with one-decimal kg formatting',
        (tester) async {
      await pumpApp(
        tester,
        const FuelVsEvCard(fuelCo2Kg: 12.345, distanceKm: 100),
      );

      // Fuel row formats valueKg as 'X.X kg'.
      expect(find.text('12.3 kg'), findsOneWidget);
    });

    testWidgets(
      'renders EV value matching MilestoneEngine.evEquivalentCo2',
      (tester) async {
        const distance = 200.0;
        final expectedEv = MilestoneEngine.evEquivalentCo2(distance);
        // Sanity-check the engine math against the documented constant
        // (0.05 kg CO2/km) so the widget contract is anchored.
        expect(expectedEv, closeTo(10.0, 0.0001));

        await pumpApp(
          tester,
          const FuelVsEvCard(fuelCo2Kg: 30, distanceKm: distance),
        );

        expect(
          find.text('${expectedEv.toStringAsFixed(1)} kg'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'progress bars reflect the relative fractions of fuel vs ev',
      (tester) async {
        // fuel = 30, ev = 200 * 0.05 = 10, max = 30.
        // fuelFrac = 30/30 = 1.0, evFrac = 10/30 ≈ 0.333.
        await pumpApp(
          tester,
          const FuelVsEvCard(fuelCo2Kg: 30, distanceKm: 200),
        );

        final bars = tester
            .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .toList();
        expect(bars, hasLength(2));
        // First row is the fuel row, second is the EV row.
        expect(bars[0].value, closeTo(1.0, 0.0001));
        expect(bars[1].value, closeTo(10 / 30, 0.0001));
      },
    );

    testWidgets(
      'renders distance via UnitFormatter (locale-aware)',
      (tester) async {
        await pumpApp(
          tester,
          const FuelVsEvCard(fuelCo2Kg: 5, distanceKm: 12.5),
        );

        // The widget concatenates label + UnitFormatter output, so we
        // assert on whatever UnitFormatter actually produces (locale-
        // aware: '12.5 km' in en_US, '12,5 km' in metric locales).
        final formatted = UnitFormatter.formatDistance(12.5);
        expect(
          find.textContaining(formatted),
          findsOneWidget,
          reason: 'expected the rendered distance line to contain '
              '"$formatted"',
        );
        expect(find.textContaining('Distance'), findsOneWidget);
      },
    );

    testWidgets(
      'renders the positive difference when fuel exceeds EV equivalent',
      (tester) async {
        // fuel = 30, ev = 10, diff = 20.0 kg CO2.
        await pumpApp(
          tester,
          const FuelVsEvCard(fuelCo2Kg: 30, distanceKm: 200),
        );

        expect(find.textContaining('+20.0 kg CO2'), findsOneWidget);
      },
    );

    testWidgets(
      'hides the difference line when fuel does not exceed EV equivalent',
      (tester) async {
        // fuel = 5, ev = 200 * 0.05 = 10, diff = -5 (not rendered).
        await pumpApp(
          tester,
          const FuelVsEvCard(fuelCo2Kg: 5, distanceKm: 200),
        );

        expect(find.textContaining('Difference'), findsNothing);
      },
    );

    testWidgets(
      'distanceKm == 0 does not divide by zero and clamps both bars to 0',
      (tester) async {
        await pumpApp(
          tester,
          const FuelVsEvCard(fuelCo2Kg: 0, distanceKm: 0),
        );

        // No exceptions thrown, both bars render with value 0.0.
        final bars = tester
            .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .toList();
        expect(bars, hasLength(2));
        expect(bars[0].value, 0.0);
        expect(bars[1].value, 0.0);

        // EV equivalent for zero distance is zero.
        expect(find.text('0.0 kg'), findsNWidgets(2));
      },
    );

    testWidgets(
      'share button copies privacy-respecting message to clipboard '
      'and shows the SnackBar confirmation',
      (tester) async {
        // Capture the platform-channel call that backs Clipboard.setData.
        Map<String, dynamic>? captured;
        TestDefaultBinaryMessengerBinding
            .instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform,
                (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            captured = Map<String, dynamic>.from(call.arguments as Map);
          }
          return null;
        });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding
              .instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null);
        });

        await pumpApp(
          tester,
          const FuelVsEvCard(fuelCo2Kg: 42, distanceKm: 100),
        );

        await tester.tap(find.byKey(const Key('carbon_share_button')));
        await tester.pump(); // start snackbar animation
        await tester.pump(const Duration(milliseconds: 100));

        expect(captured, isNotNull);
        // Localized template "I tracked {kg} kg CO2 with Tankstellen."
        // → fuelCo2Kg.toStringAsFixed(0) == '42'.
        expect(
          captured!['text'],
          'I tracked 42 kg CO2 with Tankstellen.',
        );

        // SnackBar confirmation appears.
        expect(find.text('Copied to clipboard'), findsOneWidget);
      },
    );

    testWidgets(
      'share button is reachable via its public Key',
      (tester) async {
        await pumpApp(
          tester,
          const FuelVsEvCard(fuelCo2Kg: 1, distanceKm: 1),
        );

        expect(find.byKey(const Key('carbon_share_button')), findsOneWidget);
        expect(find.byIcon(Icons.share), findsOneWidget);
      },
    );

    testWidgets(
      'renders English fallback strings when AppLocalizations is absent',
      (tester) async {
        // Pump without AppLocalizations delegates so .of(context) is null.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FuelVsEvCard(fuelCo2Kg: 10, distanceKm: 100),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Fuel vs EV'), findsOneWidget);
        expect(
          find.text('CO2 comparison for the same distance driven'),
          findsOneWidget,
        );
        expect(find.text('Your fuel'), findsOneWidget);
        expect(find.text('Equivalent EV'), findsOneWidget);
        expect(find.textContaining('Distance'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
      },
    );
  });
}
