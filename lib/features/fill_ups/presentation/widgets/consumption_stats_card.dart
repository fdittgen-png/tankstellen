// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/api.dart';
import '../../domain/entities/consumption_stats.dart';
import '../../providers/pending_reconciliation_provider.dart';
import 'confidence_tier_badge.dart';
import 'pump_gain_chip.dart';
import 'resolve_gap_banner.dart';
import '../../../../core/utils/unit_formatter.dart';

part 'consumption_stats_card_parts.dart';

/// Panel summarising aggregated consumption statistics — the Carburant
/// tab's **secondary** surface since #3950 (Epic #3947): a [PanelCard] of
/// stat tiles whose focal numbers are the largest text on the card, each
/// tile's icon + label riding above its figure in the label role.
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
/// #2433 / #3950 — the consumption-confidence indicator
/// ([ConfidenceTierBadge]) is ONE small label-sized chip under the card
/// title; the debug-only pump-gain chip joins it in Developer mode.
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
  /// null the card renders without the link so the existing
  /// summary-card tests keep passing.
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

    // #2698 — when tappable, the title gains a trailing chevron so the
    // affordance reads as a link into the detail page.
    final titleRow = Row(
      children: [
        Expanded(
          child: Text(l.consumptionStatsTitle, style: AppText.title(context)),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      ],
    );

    final body = Padding(
      padding: Spacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showOpenWindowBanner) ...[
            _OpenWindowBanner(
              text: l.consumptionStatsOpenWindowBanner(
                stats.openWindowFillCount,
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          if (showResolveGapBanner) ...[
            ResolveGapBanner(pending: pendingGap),
            const SizedBox(height: Spacing.md),
          ],
          if (showCorrectionHint) ...[
            _CorrectionShareHint(
              text: l.consumptionStatsCorrectionShareHint(
                (stats.correctionShare * 100).round(),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          titleRow,
          // #2433 / #3950 — the precision rating is ONE small label chip
          // under the title (the confidence tier, #2027); the raw
          // pump-gain chip (#3901, Epic #3886) joins it ONLY in Developer
          // mode (#2262), wrapping onto a second line if it must.
          if (volumetricEfficiencySamples != null) ...[
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.sm,
              children: [
                ConfidenceTierBadge(
                  samples: volumetricEfficiencySamples!,
                  hasGpsPlusObd2Trip: hasGpsPlusObd2Trip,
                ),
                if (showRawCalibration) const PumpGainChip(),
              ],
            ),
          ],
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.speed,
                  label: l.statAvgConsumption,
                  value: avgConsumption != null
                      ? UnitFormatter.formatDecimal(avgConsumption, fractionDigits: 2)
                      : '—',
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _StatTile(
                  icon: Icons.euro,
                  label: l.statAvgCostPerKm,
                  // #2491 — locale-aware 3 dp via formatPerKm.
                  value: avgCostKm != null
                      ? PriceFormatter.formatPerKm(avgCostKm)
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_gas_station,
                  label: l.statTotalLiters,
                  value: UnitFormatter.formatDecimal(stats.totalLiters),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _StatTile(
                  icon: Icons.payments_outlined,
                  label: l.statTotalSpent,
                  // #2491 — locale-aware 2 dp + currency symbol.
                  value: PriceFormatter.formatTotal(stats.totalSpent),
                ),
              ),
            ],
          ),
          // #3903 — the fill-up count is a fifth tile in the same grid
          // style (icon + label + value), not a bare text line.
          if (stats.fillUpCount > 0) ...[
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.format_list_numbered,
                    label: l.statFillUpCount,
                    value: '${stats.fillUpCount}',
                  ),
                ),
                const SizedBox(width: Spacing.md),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
          // #2446 — corrections are surfaced transparently on their
          // own line, never folded into the headline Total L. Shown
          // only when at least one correction landed in a closed
          // window so the line stays out of the way otherwise.
          // #2491 — neutral onSurfaceVariant, not warning (#2487).
          if (stats.correctionLitersTotal > 0) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              l.statCorrectionLiters(
                UnitFormatter.formatDecimal(stats.correctionLitersTotal),
              ),
              style: AppText.label(context),
            ),
          ],
        ],
      ),
    );

    // #3950 — a PanelCard (secondary surface: tonal fill, no outline, no
    // shadow) so the tank card above it reads as the figure and this as
    // the ground. The panel owns no padding here: the body carries it so
    // the #2698 link InkWell ripples edge to edge inside the corners.
    return PanelCard(
      padding: EdgeInsets.zero,
      child: onTap == null
          ? body
          : InkWell(
              key: const Key('consumption-stats-card-link'),
              onTap: onTap,
              borderRadius: AppRadius.lg,
              child: body,
            ),
    );
  }
}

// The three private decoration widgets (_OpenWindowBanner,
// _CorrectionShareHint, _StatTile) live in the
// `part`'d consumption_stats_card_parts.dart so this file stays under
// the 400-line cap (#2698 / file_length_test).
