import 'package:flutter/material.dart';

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
/// When [FillUp.isCorrection] is true (#1361 phase 2b), the card uses
/// the orange-amber correction theme: a 4 px left border, an
/// `auto_fix_high` leading icon on an orange background, and an inline
/// "Auto-correction — tap to edit" subtitle. Tapping a correction card
/// is expected to open the [EditCorrectionFillUpSheet] — the tap
/// handler is wired by the parent (the Fuel tab list builder).
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

    final dateStr =
        '${fillUp.date.year}-${_pad(fillUp.date.month)}-${_pad(fillUp.date.day)}';
    // Until the FillUp model carries an origin-country code (tracked in
    // #626 follow-up), fall back to the active country's units. Old
    // records logged before this change will re-format on the fly when
    // the user changes country — acceptable as a transitional step.
    final distance = UnitFormatter.formatDistance(fillUp.odometerKm);
    final volume = UnitFormatter.formatVolume(fillUp.liters);
    final costStr =
        '${fillUp.totalCost.toStringAsFixed(2)} ${PriceFormatter.currency}';
    final ppl = UnitFormatter.formatPricePerUnit(fillUp.pricePerLiter);

    final isCorrection = fillUp.isCorrection;
    // Material amber/orange that reads cleanly against both M3 light
    // and dark backgrounds. Picked shade 700 for the border + circle
    // background so the contrast vs. white text on the avatar stays
    // readable at smaller sizes.
    final correctionColor = Colors.orange.shade700;
    // #1401 phase 7b — only render the verified-by-adapter chip when
    // both fuel-level captures are present. Either missing → no chip.
    final isVerifiedByAdapter = FillUpVariance.hasAdapterCapture(fillUp);

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // The outline gives a 4 px left border via shape; we paint the
      // rest of the card normally. Using `Card.shape` keeps the
      // material elevation/ink ripple intact (vs. wrapping in a
      // Container, which would clip the ListTile splash).
      shape: isCorrection
          ? RoundedRectangleBorder(
              side: BorderSide(color: correctionColor, width: 4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            )
          : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isCorrection
              ? correctionColor
              : theme.colorScheme.primaryContainer,
          child: Icon(
            isCorrection ? Icons.auto_fix_high : Icons.local_gas_station,
            color: isCorrection
                ? Colors.white
                : theme.colorScheme.onPrimaryContainer,
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
            if (isCorrection) ...[
              const SizedBox(height: 4),
              Text(
                l?.fillUpCorrectionLabel ??
                    'Auto-correction — tap to edit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: correctionColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

    return card;
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
