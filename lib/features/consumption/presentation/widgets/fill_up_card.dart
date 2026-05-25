// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/eco_score.dart';
import '../../domain/entities/fill_up.dart';
import '../../domain/fill_up_variance.dart';
import 'eco_score_badge.dart';

/// Compact card showing a single [FillUp] entry.
///
/// When an [ecoScore] is supplied (computed against the user's recent
/// fill-up history), an eco-score badge appears under the cost line —
/// turning the card from a passive record into a driving-behaviour
/// nudge. See issue #676 ("Smarter pump. Smarter drive. Save twice.").
///
/// When [FillUp.isCorrection] is true (#1361 phase 2b / #1902), the
/// card collapses to a single slim amber row — a system-generated
/// adjustment is not a real fill-up and must not compete with one for
/// vertical space. Tapping it opens the [EditCorrectionFillUpSheet];
/// the tap handler is wired by the parent (the Fuel tab list builder).
///
/// When both [FillUp.fuelLevelBeforeL] and [FillUp.fuelLevelAfterL] are
/// non-null (#1401 phase 7b), a small "Verified by adapter" chip is
/// rendered under the volume / cost line. The chip uses the theme's
/// primary colour (matching how other "trusted-source" badges in the
/// app are rendered) plus a check icon. Either fuel-level field
/// missing — no chip; the badge is a positive signal, never an error.
class FillUpCard extends StatelessWidget {
  final FillUp fillUp;
  final EcoScore? ecoScore;
  final VoidCallback? onTap;

  const FillUpCard({
    super.key,
    required this.fillUp,
    this.ecoScore,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final volume = UnitFormatter.formatVolume(fillUp.liters);

    // #1902 — a correction is a system adjustment, not a fill-up:
    // render it as a single slim row so real fill-ups dominate.
    if (fillUp.isCorrection) {
      return _CorrectionRow(volume: volume, onTap: onTap);
    }

    final dateStr =
        '${fillUp.date.year}-${_pad(fillUp.date.month)}-${_pad(fillUp.date.day)}';
    // Until the FillUp model carries an origin-country code (tracked in
    // #626 follow-up), fall back to the active country's units. Old
    // records logged before this change will re-format on the fly when
    // the user changes country — acceptable as a transitional step.
    final distance = UnitFormatter.formatDistance(fillUp.odometerKm);
    final costStr =
        '${fillUp.totalCost.toStringAsFixed(2)} ${PriceFormatter.currency}';
    final ppl = UnitFormatter.formatPricePerUnit(fillUp.pricePerLiter);
    // #1401 phase 7b — only render the verified-by-adapter chip when
    // both fuel-level captures are present. Either missing → no chip.
    final isVerifiedByAdapter = FillUpVariance.hasAdapterCapture(fillUp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.local_gas_station,
            size: 24,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          fillUp.stationName ?? fillUp.fuelType.apiValue.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$dateStr · $distance'),
            Text(
              '$volume · $costStr · $ppl',
              style: theme.textTheme.bodySmall,
            ),
            if (isVerifiedByAdapter) ...[
              const SizedBox(height: 4),
              // #1401 phase 7b — small "Verified by adapter" chip. Uses
              // the theme primary colour for the chip background tint
              // and a check icon so the affordance reads at a glance
              // without relying on colour alone.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l?.fillUpReconciliationVerifiedBadgeLabel ??
                            'Verified by adapter',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (ecoScore != null) ...[
              const SizedBox(height: 4),
              EcoScoreBadge(score: ecoScore!),
            ],
          ],
        ),
        trailing: Text(
          fillUp.fuelType.apiValue.toUpperCase(),
          style: theme.textTheme.labelSmall,
          semanticsLabel: l?.fuelType ?? 'Fuel type',
        ),
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

/// #1902 — the slim amber row a correction [FillUp] collapses to. It
/// carries only the auto-correction label and the adjusted volume on a
/// single line: the date, cost, fuel type and odometer of a system
/// adjustment are noise next to the real fill-ups it sits between.
class _CorrectionRow extends StatelessWidget {
  final String volume;
  final VoidCallback? onTap;

  const _CorrectionRow({required this.volume, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final correctionColor = DarkModeColors.warning(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      // A slim 2 px left rule (down from the old full 4 px border) —
      // enough to read as "correction", not enough to shout.
      shape: RoundedRectangleBorder(
        side: BorderSide(color: correctionColor, width: 2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.auto_fix_high, size: 16, color: correctionColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l?.fillUpCorrectionLabel ??
                      'Auto-correction — tap to edit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: correctionColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                volume,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: correctionColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
