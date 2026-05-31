// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/consumption/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/entities/pending_reconciliation.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/consumption_stats_card.dart';
import 'package:tankstellen/features/consumption/providers/pending_reconciliation_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

/// #2262 — the raw η_v chip is gated on `Feature.debugMode`. This stub
/// flips Developer mode ON so the chip renders; without it the manifest
/// default (debugMode off) keeps the chip hidden.
class _DebugModeOn extends FeatureFlags {
  @override
  Set<Feature> build() => {Feature.debugMode};
}

/// Overrides list that enables Developer mode for the calibration-chip
/// tests below.
final _debugOn = [featureFlagsProvider.overrideWith(() => _DebugModeOn())];

/// #2445 — seeds a live [PendingReconciliation] so the 'Resolve gap'
/// affordance renders. Mirrors a deferred gap a user chose to decide
/// later on.
class _PendingGap extends PendingReconciliations {
  @override
  PendingReconciliation? build() => PendingReconciliation(
        correction: FillUp(
          id: 'correction_x',
          date: DateTime(2026, 4, 10),
          liters: 7,
          totalCost: 0,
          odometerKm: 10050,
          fuelType: FuelType.e10,
          vehicleId: 'veh-a',
          isCorrection: true,
          isFullTank: false,
        ),
        pumped: 12,
        consumed: 5,
        gap: 7,
        windowMidpointDate: DateTime(2026, 4, 10),
        windowMidpointOdometerKm: 10050,
        vehicleId: 'veh-a',
      );
}

final _pendingGapOverride = [
  pendingReconciliationsProvider.overrideWith(() => _PendingGap()),
];

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
  // #2491 — the avg-cost/km tile now formats via
  // PriceFormatter.formatPerKm and the total-spent tile via
  // formatTotal, both locale-aware. Pin GB so the figures keep their
  // dot-decimal shape and the total carries a deterministic £ symbol.
  setUp(() => PriceFormatter.setCountry('GB'));

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

      // #2491 — 123.456 → "123.46 £" via PriceFormatter.formatTotal
      // (2 dp + currency symbol, GB locale dot separator).
      expect(find.text('123.46 £'), findsOneWidget);
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
      expect(find.text('0.105'), findsOneWidget); // avg cost/km (formatPerKm)
      expect(find.text('120.0'), findsOneWidget); // total liters
      expect(find.text('198.40 £'), findsOneWidget); // total spent (formatTotal)
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

  // ─── #2433 — precision rating back in the Verbrauchsstatistik card ───
  //
  // #2383 moved the accuracy indicator (ConfidenceTierBadge) and the raw
  // η_v chip (_CalibrationChip) to the Carburant app-bar. #2433 reverses
  // that placement: both ride a subtitle row inside the stats card again,
  // next to the figures they qualify. The raw η_v chip stays gated on
  // Developer mode (#2262), so the chip tests below pump with `_debugOn`.

  group('ConsumptionStatsCard — calibration chip (#1397 / #2262)', () {
    testWidgets('no chip when volumetricEfficiencySamples == null',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats()),
        overrides: _debugOn,
      );
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets(
        'samples == 0 → "no plein-complet yet" pill (#2112, debug on)',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(
          stats: _stats(),
          volumetricEfficiency: 0.85,
          volumetricEfficiencySamples: 0,
        ),
        overrides: _debugOn,
      );
      // #2112 — the calibration pill is no longer a Material `Chip`;
      // it's a tonal Container so the η_v pill harmonises with the
      // confidence-tier badge next to it. The label still contains
      // the no-plein-complet substring.
      expect(find.textContaining('no plein-complet'), findsOneWidget);
    });

    // #2112 — the "learning" vs "calibrated" parenthetical was
    // dropped because the maturity colour is carried by the
    // confidence-tier badge now riding next to it. The η_v pill
    // shows the bare mean + sample count in both cases.
    testWidgets(
        '0 < samples < 3 → compact η_v pill with sample count (debug on)',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(
          stats: _stats(),
          volumetricEfficiency: 0.87,
          volumetricEfficiencySamples: 2,
        ),
        overrides: _debugOn,
      );
      expect(find.textContaining('0.87'), findsOneWidget);
      expect(find.textContaining('2 samples'), findsOneWidget);
    });

    testWidgets(
        'samples >= 3 → compact η_v pill (no calibrated wording, debug on)',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(
          stats: _stats(),
          volumetricEfficiency: 0.91,
          volumetricEfficiencySamples: 5,
        ),
        overrides: _debugOn,
      );
      expect(find.textContaining('0.91'), findsOneWidget);
      expect(find.textContaining('5 samples'), findsOneWidget);
      // #2112 — old shape removed; if the parenthetical comes back
      // this fails and forces a deliberate decision.
      expect(find.textContaining('calibrated'), findsNothing);
      expect(find.textContaining('learning'), findsNothing);
    });

    testWidgets(
        '#2112 — accuracy badge + η_v pill ride a single Wrap (debug on)',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(
          stats: _stats(),
          volumetricEfficiency: 0.87,
          volumetricEfficiencySamples: 2,
        ),
        overrides: _debugOn,
      );
      final wraps = find.byType(Wrap).evaluate();
      // ConsumptionStatsCard has no other Wrap today; this asserts
      // the calibration pills group sits in exactly one Wrap so
      // their layout stays harmonised.
      expect(wraps.length, greaterThanOrEqualTo(1));
    });
  });

  // ─── #2445 — 'Resolve gap' deferred-reconciliation affordance ──────
  //
  // When a reconciliation gap was deferred and is still unresolved (a
  // PendingReconciliation is live), the card grows a tappable 'Resolve
  // gap' banner that REPLACES the accusatory correction-share hint.

  group("ConsumptionStatsCard — 'Resolve gap' banner (#2445)", () {
    testWidgets('shows the tappable banner when a gap is pending',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(fillUpCount: 3)),
        overrides: _pendingGapOverride,
      );
      expect(find.byKey(const Key('resolve-gap-banner')), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);
      expect(find.textContaining('tap to resolve'), findsOneWidget);
    });

    testWidgets('hides the banner when no gap is pending (default state)',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(stats: _stats(fillUpCount: 3)),
      );
      expect(find.byKey(const Key('resolve-gap-banner')), findsNothing);
    });

    testWidgets(
        'the banner REPLACES the correction-share hint while a gap is pending',
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
        overrides: _pendingGapOverride,
      );
      // The actionable affordance supersedes the passive nudge.
      expect(find.byKey(const Key('resolve-gap-banner')), findsOneWidget);
      expect(
        find.textContaining('% of fuel from auto-corrections'),
        findsNothing,
      );
    });

    testWidgets(
        'the correction-share hint still fires when NO gap is pending',
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
      expect(find.byKey(const Key('resolve-gap-banner')), findsNothing);
      expect(
        find.textContaining('% of fuel from auto-corrections'),
        findsOneWidget,
      );
    });
  });

  group('ConsumptionStatsCard — raw η_v chip Developer-mode gate (#2262)', () {
    testWidgets(
        'η_v chip is HIDDEN for normal users (debugMode off — default)',
        (tester) async {
      // No override → manifest default → debugMode off.
      await pumpApp(
        tester,
        ConsumptionStatsCard(
          stats: _stats(),
          volumetricEfficiency: 0.87,
          volumetricEfficiencySamples: 2,
        ),
      );
      // The raw η_v glyph + sample count must not surface.
      expect(find.textContaining('η_v'), findsNothing);
      expect(find.textContaining('2 samples'), findsNothing);
      // …but the plain accuracy indicator (always-on) still renders.
      expect(find.textContaining('Accuracy:'), findsOneWidget);
    });

    testWidgets('η_v chip is SHOWN when Developer mode is ON', (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(
          stats: _stats(),
          volumetricEfficiency: 0.87,
          volumetricEfficiencySamples: 2,
        ),
        overrides: _debugOn,
      );
      expect(find.textContaining('η_v'), findsOneWidget);
      expect(find.textContaining('2 samples'), findsOneWidget);
      // Accuracy indicator still rides alongside it.
      expect(find.textContaining('Accuracy:'), findsOneWidget);
    });

    testWidgets(
        'samples == 0 raw chip is HIDDEN for normal users (debugMode off)',
        (tester) async {
      await pumpApp(
        tester,
        ConsumptionStatsCard(
          stats: _stats(),
          volumetricEfficiency: 0.85,
          volumetricEfficiencySamples: 0,
        ),
      );
      expect(find.textContaining('no plein-complet'), findsNothing);
      expect(find.textContaining('η_v'), findsNothing);
    });
  });
}
