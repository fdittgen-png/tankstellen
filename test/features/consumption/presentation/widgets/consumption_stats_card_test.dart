import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/consumption_stats_card.dart';

import '../../../../helpers/pump_app.dart';

/// Builds a [ConsumptionStats] with sensible defaults so each test only
/// spells out the field it cares about. Mirrors the freezed factory at
/// `lib/features/consumption/domain/entities/consumption_stats.dart`.
ConsumptionStats _stats({
  int fillUpCount = 0,
  double totalLiters = 0,
  double totalSpent = 0,
  double totalDistanceKm = 0,
  double? avgConsumptionL100km,
  double? avgCostPerKm,
  double correctionLitersTotal = 0,
  double correctionShare = 0,
  int openWindowFillCount = 0,
  double openWindowLiters = 0,
}) {
  return ConsumptionStats(
    fillUpCount: fillUpCount,
    totalLiters: totalLiters,
    totalSpent: totalSpent,
    totalDistanceKm: totalDistanceKm,
    avgConsumptionL100km: avgConsumptionL100km,
    avgCostPerKm: avgCostPerKm,
    correctionLitersTotal: correctionLitersTotal,
    correctionShare: correctionShare,
    openWindowFillCount: openWindowFillCount,
    openWindowLiters: openWindowLiters,
  );
}

void main() {
  group('ConsumptionStatsCard — title', () {
    testWidgets('renders the localized "Consumption stats" title',
        (tester) async {
      await pumpApp(tester, ConsumptionStatsCard(stats: _stats()));

      expect(find.text('Consumption stats'), findsOneWidget);
    });
  });

  group('ConsumptionStatsCard — avg consumption tile', () {
    testWidgets('formats avgConsumptionL100km to two decimals when set',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(avgConsumptionL100km: 6.789)),
      );

      // 6.789 → "6.79" via toStringAsFixed(2)
      expect(find.text('6.79'), findsOneWidget);
    });

    testWidgets('renders an em-dash when avgConsumptionL100km is null',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(avgConsumptionL100km: null)),
      );

      // Both nullable stats fall back to "—" → at least two em-dashes.
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('renders the localized avg-consumption label', (tester) async {
      await pumpApp(tester, ConsumptionStatsCard(stats: _stats()));

      expect(find.text('Avg L/100km'), findsOneWidget);
    });
  });

  group('ConsumptionStatsCard — avg cost-per-km tile', () {
    testWidgets('formats avgCostPerKm to three decimals when set',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(avgCostPerKm: 0.12345)),
      );

      // 0.12345 → "0.123" via toStringAsFixed(3)
      expect(find.text('0.123'), findsOneWidget);
    });

    testWidgets('renders an em-dash when avgCostPerKm is null',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(avgCostPerKm: null)),
      );

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('renders the localized avg-cost label', (tester) async {
      await pumpApp(tester, ConsumptionStatsCard(stats: _stats()));

      expect(find.text('Avg cost/km'), findsOneWidget);
    });
  });

  group('ConsumptionStatsCard — total liters tile', () {
    testWidgets('formats totalLiters to one decimal', (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(totalLiters: 42.7)),
      );

      // 42.7 → "42.7" via toStringAsFixed(1)
      expect(find.text('42.7'), findsOneWidget);
    });

    testWidgets('renders the localized total-liters label', (tester) async {
      await pumpApp(tester, ConsumptionStatsCard(stats: _stats()));

      expect(find.text('Total liters'), findsOneWidget);
    });
  });

  group('ConsumptionStatsCard — total spent tile', () {
    testWidgets('formats totalSpent to two decimals', (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(totalSpent: 123.456)),
      );

      // 123.456 → "123.46" via toStringAsFixed(2)
      expect(find.text('123.46'), findsOneWidget);
    });

    testWidgets('renders the localized total-spent label', (tester) async {
      await pumpApp(tester, ConsumptionStatsCard(stats: _stats()));

      expect(find.text('Total spent'), findsOneWidget);
    });
  });

  group('ConsumptionStatsCard — fill-up count line', () {
    testWidgets('renders the count line when fillUpCount > 0', (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(fillUpCount: 5)),
      );

      // The widget renders "Fill-ups: 5" (localized prefix + number).
      expect(find.text('Fill-ups: 5'), findsOneWidget);
    });

    testWidgets('hides the count line when fillUpCount is zero',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(fillUpCount: 0)),
      );

      // The literal "Fill-ups: 0" string must not appear when the row
      // is hidden behind the `fillUpCount > 0` guard.
      expect(find.text('Fill-ups: 0'), findsNothing);
      expect(find.textContaining('Fill-ups:'), findsNothing);
    });
  });

  group('ConsumptionStatsCard — stat icons', () {
    testWidgets(
        'renders speed, euro, fuel-pump and payment icons for the four stat tiles',
        (tester) async {
      await pumpApp(tester, ConsumptionStatsCard(stats: _stats()));

      expect(find.byIcon(Icons.speed), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsOneWidget);
    });
  });

  group('ConsumptionStatsCard — structure', () {
    testWidgets('wraps its content in a Material Card', (tester) async {
      await pumpApp(tester, ConsumptionStatsCard(stats: _stats()));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders a fully-populated stats payload end-to-end',
        (tester) async {
      // Sanity check: every formatted value lands at the expected decimals
      // when all inputs are non-null at once.
      await pumpApp(
        tester,
        ConsumptionStatsCard(
          stats: _stats(
            fillUpCount: 3,
            totalLiters: 120.0,
            totalSpent: 198.40,
            avgConsumptionL100km: 6.4,
            avgCostPerKm: 0.105,
          ),
        ),
      );

      expect(find.text('6.40'), findsOneWidget); // avg L/100km
      expect(find.text('0.105'), findsOneWidget); // avg cost/km
      expect(find.text('120.0'), findsOneWidget); // total liters
      expect(find.text('198.40'), findsOneWidget); // total spent
      expect(find.text('Fill-ups: 3'), findsOneWidget);
      expect(find.text('—'), findsNothing); // no nullable fallbacks fired
    });
  });

  // ─── #1362 — open-window banner & correction-share hint ───────────
  //
  // The card grows two optional decorations on top of the stat tiles
  // when the underlying stats indicate partial fills are pending the
  // next plein-complet OR a meaningful share of fuel came from auto-
  // corrections. When neither condition holds the card must render
  // exactly as before.

  group('ConsumptionStatsCard — open-window banner', () {
    testWidgets(
      'shows the banner when openWindowFillCount > 0',
      (tester) async {
        await pumpApp(
          tester,
          ConsumptionStatsCard(
            stats: _stats(
              fillUpCount: 3,
              totalLiters: 90,
              openWindowFillCount: 2,
              openWindowLiters: 30,
            ),
          ),
        );
        expect(
          find.textContaining('partial fills pending plein complet'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides the banner when openWindowFillCount is zero',
      (tester) async {
        await pumpApp(
          tester,
          ConsumptionStatsCard(stats: _stats(fillUpCount: 2)),
        );
        expect(
          find.textContaining('partial fill'),
          findsNothing,
        );
        expect(
          find.textContaining('plein complet'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'pluralises to singular when exactly 1 partial fill is pending',
      (tester) async {
        await pumpApp(
          tester,
          ConsumptionStatsCard(
            stats: _stats(
              fillUpCount: 2,
              totalLiters: 60,
              openWindowFillCount: 1,
              openWindowLiters: 15,
            ),
          ),
        );
        // Singular "1 partial fill pending plein complet — not in average".
        expect(
          find.textContaining('1 partial fill pending plein complet'),
          findsOneWidget,
        );
      },
    );
  });

  group('ConsumptionStatsCard — correction-share hint', () {
    testWidgets(
      'shows the hint when correctionShare > 5 %',
      (tester) async {
        await pumpApp(
          tester,
          ConsumptionStatsCard(
            stats: _stats(
              fillUpCount: 3,
              totalLiters: 100,
              correctionLitersTotal: 12,
              correctionShare: 0.12,
            ),
          ),
        );
        // "12% of fuel from auto-corrections — review entries"
        expect(
          find.textContaining('% of fuel from auto-corrections'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hides the hint when correctionShare is at the 5 % threshold',
      (tester) async {
        await pumpApp(
          tester,
          ConsumptionStatsCard(
            stats: _stats(
              fillUpCount: 3,
              totalLiters: 100,
              correctionLitersTotal: 5,
              correctionShare: 0.05,
            ),
          ),
        );
        expect(
          find.textContaining('auto-corrections'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'hides the hint when correctionShare is zero',
      (tester) async {
        await pumpApp(
          tester,
          ConsumptionStatsCard(stats: _stats(fillUpCount: 3)),
        );
        expect(
          find.textContaining('auto-corrections'),
          findsNothing,
        );
      },
    );
  });

  group(
    'ConsumptionStatsCard — all-plein no-corrections render is unchanged',
    () {
      testWidgets(
        'no banner, no hint when openWindowFillCount==0 AND correctionShare==0',
        (tester) async {
          await pumpApp(
            tester,
            ConsumptionStatsCard(
              stats: _stats(
                fillUpCount: 5,
                totalLiters: 200,
                totalSpent: 300,
                avgConsumptionL100km: 6.4,
                avgCostPerKm: 0.10,
              ),
            ),
          );
          // Neither decoration must be present.
          expect(find.textContaining('partial fill'), findsNothing);
          expect(find.textContaining('plein complet'), findsNothing);
          expect(find.textContaining('auto-corrections'), findsNothing);
          // Existing chrome still renders.
          expect(find.text('Consumption stats'), findsOneWidget);
          expect(find.text('Fill-ups: 5'), findsOneWidget);
        },
      );
    },
  );
}
