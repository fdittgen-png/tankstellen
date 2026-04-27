import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/trip_length_breakdown_card.dart';
import 'package:tankstellen/features/consumption/domain/services/trip_length_aggregator.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget-level coverage for [TripLengthBreakdownCard] (#1191).
///
/// The card is purely presentational — it renders the aggregate
/// produced by `aggregateByTripLength`. The aggregator's bucketing +
/// filter logic is locked down in its own unit-test file; here we
/// cover the rendering contract:
///   * three tiles render with localised labels when at least one
///     bucket has trips
///   * the card hides entirely when every bucket has zero trips
///   * a bucket with 1-4 trips shows the "Need more data" placeholder
///   * arrows render only when the overall avg is provided AND the
///     bucket has >=5 trips AND the bucket avg differs from overall
void main() {
  group('TripLengthBreakdownCard — labels + tile presence', () {
    testWidgets('renders the localised title + three bucket labels',
        (tester) async {
      await _pumpCard(
        tester,
        breakdown: const TripLengthBreakdown(
          short: TripLengthBucketStats(
            tripCount: 5,
            totalDistanceKm: 15.0,
            totalLitres: 1.5,
            avgLPer100Km: 10.0,
          ),
          medium: TripLengthBucketStats.empty,
          long: TripLengthBucketStats(
            tripCount: 7,
            totalDistanceKm: 350.0,
            totalLitres: 21.0,
            avgLPer100Km: 6.0,
          ),
        ),
        overallAvgLPer100Km: 7.5,
      );

      expect(find.text('Consumption by trip length'), findsOneWidget);
      expect(find.text('Short (<5 km)'), findsOneWidget);
      expect(find.text('Medium (5–25 km)'), findsOneWidget);
      expect(find.text('Long (>25 km)'), findsOneWidget);

      // All three tile keys must be present — the card always renders
      // the 3-tile row when ANY bucket has trips, even if individual
      // tiles are in their "empty" state.
      expect(find.byKey(const Key('trip_length_tile_short')), findsOneWidget);
      expect(find.byKey(const Key('trip_length_tile_medium')), findsOneWidget);
      expect(find.byKey(const Key('trip_length_tile_long')), findsOneWidget);
    });

    testWidgets('renders the average L/100 km on tiles with >=5 trips',
        (tester) async {
      await _pumpCard(
        tester,
        breakdown: const TripLengthBreakdown(
          short: TripLengthBucketStats(
            tripCount: 5,
            totalDistanceKm: 15.0,
            totalLitres: 1.5,
            avgLPer100Km: 10.0,
          ),
          medium: TripLengthBucketStats.empty,
          long: TripLengthBucketStats(
            tripCount: 7,
            totalDistanceKm: 350.0,
            totalLitres: 21.0,
            avgLPer100Km: 6.0,
          ),
        ),
        overallAvgLPer100Km: 7.5,
      );

      // Short avg 10.0 → "10.0 L/100"; long avg 6.0 → "6.0 L/100".
      expect(find.text('10.0 L/100'), findsOneWidget);
      expect(find.text('6.0 L/100'), findsOneWidget);
    });
  });

  group('TripLengthBreakdownCard — empty + "need more data"', () {
    testWidgets(
      'renders SizedBox.shrink (no card) when all buckets are zero',
      (tester) async {
        await _pumpCard(
          tester,
          breakdown: TripLengthBreakdown.empty,
          overallAvgLPer100Km: null,
        );

        // The title must NOT render when the card is hidden.
        expect(find.text('Consumption by trip length'), findsNothing);
        // The internal Card root key must not be in the tree either.
        expect(
          find.byKey(const ValueKey('trip_length_breakdown_card')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'shows "Need more data" on the medium tile when count is between 1 and 4',
      (tester) async {
        await _pumpCard(
          tester,
          breakdown: const TripLengthBreakdown(
            short: TripLengthBucketStats(
              tripCount: 5,
              totalDistanceKm: 15.0,
              totalLitres: 1.5,
              avgLPer100Km: 10.0,
            ),
            medium: TripLengthBucketStats(
              tripCount: 3,
              totalDistanceKm: 30.0,
              totalLitres: 1.8,
              avgLPer100Km: 6.0,
            ),
            long: TripLengthBucketStats.empty,
          ),
          overallAvgLPer100Km: 8.0,
        );

        // The placeholder copy renders inside the medium tile.
        expect(find.text('Need more data'), findsOneWidget);
        // Belt-and-braces: the actual avg must NOT be rendered for the
        // medium bucket when below the floor — averaging 3 trips is
        // exactly the "swing-on-one-outlier" case the placeholder
        // exists to suppress.
        expect(find.text('6.0 L/100'), findsNothing);
      },
    );
  });

  group('TripLengthBreakdownCard — above/below arrows', () {
    testWidgets(
      'renders red up arrow when bucket avg is above overall avg',
      (tester) async {
        await _pumpCard(
          tester,
          breakdown: const TripLengthBreakdown(
            short: TripLengthBucketStats(
              tripCount: 6,
              totalDistanceKm: 18.0,
              totalLitres: 2.0,
              avgLPer100Km: 11.1, // above overall (7.5)
            ),
            medium: TripLengthBucketStats.empty,
            long: TripLengthBucketStats.empty,
          ),
          overallAvgLPer100Km: 7.5,
        );

        // Up arrow for the worse-than-overall short bucket.
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward), findsNothing);
      },
    );

    testWidgets(
      'renders green down arrow when bucket avg is below overall avg',
      (tester) async {
        await _pumpCard(
          tester,
          breakdown: const TripLengthBreakdown(
            short: TripLengthBucketStats.empty,
            medium: TripLengthBucketStats.empty,
            long: TripLengthBucketStats(
              tripCount: 8,
              totalDistanceKm: 400.0,
              totalLitres: 24.0,
              avgLPer100Km: 6.0, // below overall (7.5)
            ),
          ),
          overallAvgLPer100Km: 7.5,
        );

        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward), findsNothing);
      },
    );

    testWidgets(
      'no arrows render when overallAvgLPer100Km is null',
      (tester) async {
        await _pumpCard(
          tester,
          breakdown: const TripLengthBreakdown(
            short: TripLengthBucketStats.empty,
            medium: TripLengthBucketStats(
              tripCount: 6,
              totalDistanceKm: 60.0,
              totalLitres: 4.0,
              avgLPer100Km: 6.667,
            ),
            long: TripLengthBucketStats.empty,
          ),
          overallAvgLPer100Km: null,
        );

        expect(find.byIcon(Icons.arrow_upward), findsNothing);
        expect(find.byIcon(Icons.arrow_downward), findsNothing);
      },
    );
  });
}

/// Pumps [TripLengthBreakdownCard] inside a [MaterialApp] that wires
/// [AppLocalizations] so the localised strings resolve, and threads the
/// inherited [ThemeData] / [AppLocalizations] into the widget's
/// required `l` / `theme` parameters via a [Builder].
///
/// The widget intentionally does NOT call [AppLocalizations.of] itself
/// — it takes the bundle as a parameter so the dashboard can compute
/// it once and the widget renders deterministically. The Builder here
/// mirrors the production wire-up in `carbon_dashboard_screen.dart`.
Future<void> _pumpCard(
  WidgetTester tester, {
  required TripLengthBreakdown breakdown,
  required double? overallAvgLPer100Km,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final l = AppLocalizations.of(context);
            final theme = Theme.of(context);
            // pumpApp would have loaded the delegate by the next pump,
            // so AppLocalizations.of must resolve before we hand it in.
            if (l == null) return const SizedBox.shrink();
            return TripLengthBreakdownCard(
              breakdown: breakdown,
              overallAvgLPer100Km: overallAvgLPer100Km,
              l: l,
              theme: theme,
            );
          },
        ),
      ),
    ),
  );
  // Two pumps so the AppLocalizations delegate finishes loading. We
  // avoid pumpAndSettle on Windows widget tests per the project's
  // Hive-fire-and-forget guideline.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
