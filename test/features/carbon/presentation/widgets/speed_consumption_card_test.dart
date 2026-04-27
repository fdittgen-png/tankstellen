import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/speed_consumption_card.dart';
import 'package:tankstellen/features/consumption/domain/services/speed_consumption_histogram.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget-level coverage for [SpeedConsumptionCard] (#1192).
///
/// The aggregator's bin / floor / idle-jam logic is exercised in its
/// own unit-test file. Here we cover the rendering contract:
///   * one bar per band when bins carry enough total telemetry
///   * the insufficient-data placeholder when totals are below the
///     30-min floor (or zero samples)
///   * the reference line renders only when overall avg is non-null
///   * the title + localised band labels resolve through the bundle
void main() {
  group('SpeedConsumptionCard — happy path', () {
    testWidgets('renders one bar per band when telemetry is sufficient',
        (tester) async {
      // Build a histogram with 1800+ s of total telemetry so the card
      // renders the bars instead of the empty-state placeholder.
      final bins = _binsWithTotalSeconds(2000);

      await _pumpCard(
        tester,
        bins: bins,
        overallAvgLPer100Km: 7.5,
      );

      // Title must resolve from the localisations bundle.
      expect(find.text('Consumption by speed'), findsOneWidget);

      // One bar per band — assert each band's key-prefixed widget is
      // present. (Keys are namespaced so the test doesn't depend on
      // the bar's internal structure.)
      for (final band in SpeedBand.values) {
        expect(find.byKey(Key('speed_bar_${band.name}')), findsOneWidget);
      }

      // Localised band labels render somewhere in the tree.
      expect(find.text('Idle / jam'), findsOneWidget);
      expect(find.text('Urban (10–50)'), findsOneWidget);
      expect(find.text('Suburban (50–80)'), findsOneWidget);
      expect(find.text('Rural (80–100)'), findsOneWidget);
      expect(find.text('Eco-cruise (100–115)'), findsOneWidget);
      expect(find.text('Motorway (115–130)'), findsOneWidget);
      expect(find.text('Motorway fast (130+)'), findsOneWidget);
    });

    testWidgets(
      'renders the reference line when overallAvgLPer100Km is non-null',
      (tester) async {
        final bins = _binsWithTotalSeconds(2000);

        await _pumpCard(
          tester,
          bins: bins,
          overallAvgLPer100Km: 7.5,
        );

        // The reference line is keyed once per bar that has an avg.
        // At least one bar in our fixture has an avg → at least one
        // reference line widget exists.
        expect(
          find.byKey(const ValueKey('speed_consumption_reference_line')),
          findsWidgets,
        );
      },
    );
  });

  group('SpeedConsumptionCard — insufficient data', () {
    testWidgets(
      'shows the placeholder when total time-share is under 30 minutes',
      (tester) async {
        // 1500 s = 25 min — under the 1800-s floor.
        final bins = _binsWithTotalSeconds(1500);

        await _pumpCard(
          tester,
          bins: bins,
          overallAvgLPer100Km: 7.5,
        );

        // Empty-state copy is visible.
        expect(
          find.text(
            'Record 30+ minutes of trips with the OBD2 adapter to '
            'unlock the speed/consumption analysis.',
          ),
          findsOneWidget,
        );
        // No per-band bar widgets render in the empty-state.
        expect(
          find.byKey(const Key('speed_bar_${'urban'}')),
          findsNothing,
        );
        // The empty-state widget itself is keyed for stable assertion.
        expect(
          find.byKey(const ValueKey('speed_consumption_insufficient_data')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows the placeholder when there are zero OBD2 samples',
      (tester) async {
        // Every band empty (0 samples) → 0 s total → placeholder.
        final bins = <SpeedConsumptionBin>[
          for (final band in SpeedBand.values)
            SpeedConsumptionBin(
              band: band,
              sampleCount: 0,
              timeShareSeconds: 0,
              avgLPer100Km: null,
            ),
        ];

        await _pumpCard(
          tester,
          bins: bins,
          overallAvgLPer100Km: null,
        );

        expect(
          find.byKey(const ValueKey('speed_consumption_insufficient_data')),
          findsOneWidget,
        );
        // Reference line is suppressed in the empty state — there's no
        // bar to anchor it against.
        expect(
          find.byKey(const ValueKey('speed_consumption_reference_line')),
          findsNothing,
        );
      },
    );
  });

  group('SpeedConsumptionCard — reference line suppression', () {
    testWidgets(
      'no reference line renders when overallAvgLPer100Km is null',
      (tester) async {
        final bins = _binsWithTotalSeconds(2000);

        await _pumpCard(
          tester,
          bins: bins,
          overallAvgLPer100Km: null,
        );

        expect(
          find.byKey(const ValueKey('speed_consumption_reference_line')),
          findsNothing,
        );
      },
    );
  });
}

/// Build a histogram whose total time-share equals [totalSeconds]. The
/// samples are spread across rural + motorway bins so both have
/// non-null avgLPer100Km — that's all the widget needs to exercise its
/// bar-rendering branch.
List<SpeedConsumptionBin> _binsWithTotalSeconds(int totalSeconds) {
  // Split the time roughly evenly across rural + motorway. The exact
  // split doesn't matter for the rendering assertions — only the total
  // crosses the 1800-s threshold or not.
  final ruralSeconds = (totalSeconds / 2).floor();
  final motorwaySeconds = totalSeconds - ruralSeconds;

  return <SpeedConsumptionBin>[
    for (final band in SpeedBand.values)
      switch (band) {
        SpeedBand.rural => SpeedConsumptionBin(
            band: band,
            sampleCount: ruralSeconds,
            timeShareSeconds: ruralSeconds.toDouble(),
            avgLPer100Km: 7.0,
          ),
        SpeedBand.motorway => SpeedConsumptionBin(
            band: band,
            sampleCount: motorwaySeconds,
            timeShareSeconds: motorwaySeconds.toDouble(),
            avgLPer100Km: 8.5,
          ),
        _ => SpeedConsumptionBin(
            band: band,
            sampleCount: 0,
            timeShareSeconds: 0,
            avgLPer100Km: null,
          ),
      },
  ];
}

/// Pumps [SpeedConsumptionCard] inside a [MaterialApp] that wires
/// [AppLocalizations] so the localised strings resolve. Mirrors the
/// helper in `trip_length_breakdown_card_test.dart` for consistency.
Future<void> _pumpCard(
  WidgetTester tester, {
  required List<SpeedConsumptionBin> bins,
  required double? overallAvgLPer100Km,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        // Wider viewport than the default test surface — the card has
        // a 96-wide leading column and a fixed-width trailing column.
        // On the default 800x600 surface the bar track has plenty of
        // room, but a constrained Center on smaller surfaces would
        // squeeze the LayoutBuilder into a near-zero width.
        body: SizedBox(
          width: 600,
          child: Builder(
            builder: (context) {
              final l = AppLocalizations.of(context);
              final theme = Theme.of(context);
              if (l == null) return const SizedBox.shrink();
              return SpeedConsumptionCard(
                bins: bins,
                overallAvgLPer100Km: overallAvgLPer100Km,
                l: l,
                theme: theme,
              );
            },
          ),
        ),
      ),
    ),
  );
  // Two pumps so the AppLocalizations delegate finishes loading.
  // pumpAndSettle is avoided per the project's Hive-fire-and-forget
  // guideline — Windows test runs occasionally hang on it.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
