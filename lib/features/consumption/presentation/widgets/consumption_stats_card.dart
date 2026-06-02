// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../domain/entities/consumption_stats.dart';
import '../../providers/pending_reconciliation_provider.dart';
import 'confidence_tier_badge.dart';
import 'resolve_gap_banner.dart';

part 'consumption_stats_card_parts.dart';

/// Card summarising aggregated consumption statistics.
///
/// Since #1362 the card grows two optional decorations on top of the stat
/// tiles: a grey **open-window banner** when partial fills sit after the
/// most recent plein-complet (excluded from the average), and an orange
/// **correction-share hint** when more than 5 % of the totalled fuel came
/// from auto-corrections. When neither fires the card renders as before so
/// the all-plein, no-corrections case keeps its calm UX.
///
/// #2445 — when a reconciliation gap was deferred and is still unresolved
/// the card grows a tappable [ResolveGapBanner] that re-opens the guided
/// workflow; it REPLACES the accusatory correction-share hint while a gap
/// is pending (the actionable affordance supersedes the passive nudge).
///
/// #2433 — the consumption-confidence indicator (ConfidenceTierBadge) and
/// the debug-only raw η_v chip ride a subtitle row under the card title
/// (moved out to the app-bar in #2383, brought back here in #2433) so the
/// precision rating sits next to the figures it qualifies.
class ConsumptionStatsCard extends ConsumerWidget {
  final ConsumptionStats stats;

  /// Active vehicle's auto-learned η_v (#1397). When null the
  /// convergence chip is skipped — useful for tests / no-vehicle
  /// states / EV vehicles where the speed-density estimator never
  /// runs.
  final double? volumetricEfficiency;

  /// Number of plein-complet samples the learner has folded into
  /// [volumetricEfficiency] (#1397). 0 surfaces the "no plein-complet
  /// yet" state, 1-2 the bootstrap state, 3+ the calibrated state.
  final int? volumetricEfficiencySamples;

  /// Whether the user has at least one trip whose `kind` is
  /// `gpsPlusObd2` (#2027). Combined with [volumetricEfficiencySamples]
  /// this drives the A/B/C confidence-tier badge. Defaults to `true`
  /// because every legacy trip was recorded with OBD2 — so a user with
  /// no migration data still sees the historical default.
  final bool hasGpsPlusObd2Trip;

  /// #2698 — when non-null the card body becomes an [InkWell]
  /// (mirroring [ResolveGapBanner]) and a trailing chevron joins the
  /// title row, opening the consumption-statistics detail page. When
  /// null the card renders byte-identical to its pre-#2698 shape so the
  /// existing summary-card tests keep passing.
  final VoidCallback? onTap;

  const ConsumptionStatsCard({
    super.key,
    required this.stats,
    this.volumetricEfficiency,
    this.volumetricEfficiencySamples,
    this.hasGpsPlusObd2Trip = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    // #2262 — the raw η_v learner chip is engineering jargon
    // (volumetric efficiency + sample count). Normal users get the
    // plain accuracy indicator from [ConfidenceTierBadge]; the raw
    // chip is gated behind Developer mode (`Feature.debugMode`,
    // shipped #2248) so only power users see it.
    final showRawCalibration = ref
        .watch(enabledFeaturesProvider)
        .contains(Feature.debugMode);

    final avgConsumption = stats.avgConsumptionL100km;
    final avgCostKm = stats.avgCostPerKm;

    // #2445 — a deferred-but-unresolved gap takes precedence over the
    // passive correction-share hint: surface the actionable 'Resolve gap'
    // banner instead so the user can return to the decision they put off.
    final pendingGap = ref.watch(pendingReconciliationsProvider);
    final showResolveGapBanner = pendingGap != null;
    final showOpenWindowBanner = stats.openWindowFillCount > 0;
    final showCorrectionHint =
        !showResolveGapBanner && stats.correctionShare > 0.05;

    final titleText = Text(
      l?.consumptionStatsTitle ?? 'Consumption stats',
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
    // #2698 — when tappable, the title gains a trailing chevron so the
    // affordance reads as a link into the detail page; otherwise it is
    // the bare Text the summary-card tests assert against.
    final Widget titleRow = onTap == null
        ? titleText
        : Row(
            children: [
              Expanded(child: titleText),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          );

    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showOpenWindowBanner) ...[
            _OpenWindowBanner(
              text:
                  l?.consumptionStatsOpenWindowBanner(
                    stats.openWindowFillCount,
                  ) ??
                  '${stats.openWindowFillCount} partial fill(s) pending '
                      'plein complet — not in average',
            ),
            const SizedBox(height: 8),
          ],
          if (showResolveGapBanner) ...[
            ResolveGapBanner(pending: pendingGap),
            const SizedBox(height: 8),
          ],
          if (showCorrectionHint) ...[
            _CorrectionShareHint(
              text:
                  l?.consumptionStatsCorrectionShareHint(
                    (stats.correctionShare * 100).round(),
                  ) ??
                  '${(stats.correctionShare * 100).round()}% of fuel from '
                      'auto-corrections — review entries',
            ),
            const SizedBox(height: 8),
          ],
          titleRow,
          // #2433 — the precision rating rides a subtitle row directly
          // under the card title: the confidence tier (A/B/C — #2027)
          // and η_v (#1397 / #815) sit side-by-side on a phone in a
          // single Wrap so they read as one calibration-state group and
          // stack only when the row genuinely overflows. The confidence
          // tier leads (user-facing accuracy band); η_v trails
          // (engineer-detail anchor) and is shown ONLY in Developer mode
          // (#2262) — for normal users the accuracy indicator alone
          // conveys trust.
          if (volumetricEfficiencySamples != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ConfidenceTierBadge(
                  samples: volumetricEfficiencySamples!,
                  hasGpsPlusObd2Trip: hasGpsPlusObd2Trip,
                ),
                if (showRawCalibration)
                  _CalibrationChip(
                    volumetricEfficiency: volumetricEfficiency ?? 0.85,
                    samples: volumetricEfficiencySamples!,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.speed,
                  label: l?.statAvgConsumption ?? 'Avg L/100km',
                  value: avgConsumption != null
                      ? avgConsumption.toStringAsFixed(2)
                      : '—',
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.euro,
                  label: l?.statAvgCostPerKm ?? 'Avg /km',
                  // #2491 — locale-aware 3 dp via formatPerKm.
                  value: avgCostKm != null
                      ? PriceFormatter.formatPerKm(avgCostKm)
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_gas_station,
                  label: l?.statTotalLiters ?? 'Total L',
                  value: stats.totalLiters.toStringAsFixed(1),
                ),
              ),
              Expanded(
                child: _StatTile(
                  icon: Icons.payments_outlined,
                  label: l?.statTotalSpent ?? 'Total spent',
                  // #2491 — locale-aware 2 dp + currency symbol.
                  value: PriceFormatter.formatTotal(stats.totalSpent),
                ),
              ),
            ],
          ),
          if (stats.fillUpCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${l?.statFillUpCount ?? 'Fill-ups'}: ${stats.fillUpCount}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          // #2446 — corrections are surfaced transparently on their
          // own line, never folded into the headline Total L. Shown
          // only when at least one correction landed in a closed
          // window so the line stays out of the way otherwise.
          // #2491 — neutral onSurfaceVariant, not warning (#2487).
          if (stats.correctionLitersTotal > 0) ...[
            const SizedBox(height: 4),
            Text(
              l?.statCorrectionLiters(
                    stats.correctionLitersTotal.toStringAsFixed(1),
                  ) ??
                  'Corrections: +${stats.correctionLitersTotal.toStringAsFixed(1)} L',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      // #2698 — when null the card stays a plain Padding-in-Card so its
      // render is byte-identical to the pre-#2698 summary card; when
      // set the body becomes a tappable InkWell that opens the
      // consumption-statistics detail page (mirrors [ResolveGapBanner]).
      child: onTap == null
          ? body
          : InkWell(
              key: const Key('consumption-stats-card-link'),
              onTap: onTap,
              child: body,
            ),
    );
  }
}

// The four private decoration widgets (_OpenWindowBanner,
// _CorrectionShareHint, _CalibrationChip, _StatTile) live in the
// `part`'d consumption_stats_card_parts.dart so this file stays under
// the 400-line cap (#2698 / file_length_test).
