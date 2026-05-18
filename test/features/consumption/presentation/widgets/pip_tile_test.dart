import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pip_tile.dart';

/// Widget coverage for [PipTile] — the compact Picture-in-Picture tile
/// (#1884). The PiP *mechanism* is device-verified; this locks in the
/// glanceable tile's content + eco-coach colour mapping.
void main() {
  Future<void> pump(WidgetTester tester, Widget tile) =>
      tester.pumpWidget(MaterialApp(home: tile));

  Color tileBackground(WidgetTester tester) => tester
      .widget<Material>(
        find.descendant(
          of: find.byType(PipTile),
          matching: find.byType(Material),
        ),
      )
      .color!;

  group('PipTile', () {
    testWidgets('renders the live consumption value and the unit',
        (tester) async {
      await pump(
        tester,
        const PipTile(avgText: '5.4', band: ConsumptionBand.normal),
      );

      expect(find.text('5.4'), findsOneWidget);
      expect(find.text('L/100 km'), findsOneWidget);
    });

    testWidgets('renders an em-dash placeholder when no average is known',
        (tester) async {
      await pump(
        tester,
        const PipTile(avgText: '—', band: ConsumptionBand.normal),
      );

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('eco and very-heavy bands paint distinct backgrounds',
        (tester) async {
      await pump(
        tester,
        const PipTile(avgText: '3.9', band: ConsumptionBand.eco),
      );
      final ecoBackground = tileBackground(tester);

      await pump(
        tester,
        const PipTile(avgText: '11.2', band: ConsumptionBand.veryHeavy),
      );
      final heavyBackground = tileBackground(tester);

      expect(ecoBackground, isNot(equals(heavyBackground)),
          reason: 'the eco-coach colour must tell good and wasteful '
              'driving apart at a glance');
    });

    testWidgets('paused overrides the band with a neutral treatment',
        (tester) async {
      await pump(
        tester,
        const PipTile(avgText: '4.1', band: ConsumptionBand.eco),
      );
      final liveEco = tileBackground(tester);

      await pump(
        tester,
        const PipTile(
          avgText: '4.1',
          band: ConsumptionBand.eco,
          paused: true,
        ),
      );
      final paused = tileBackground(tester);

      expect(paused, isNot(equals(liveEco)),
          reason: 'a paused trip must not look like live eco driving');
    });
  });
}
