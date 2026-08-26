// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'fuel_type_efficiency_card.dart';

/// The analytical half of the fuel comparison (#3828).
///
/// The card used to present two rows of numbers and leave every decision to
/// the reader. The questions a driver choosing between E85 and E5 actually
/// has — how much is this costing me, and at what pump price does the answer
/// flip — were all derivable and none were stated.
///
/// This block states them:
///   * which fuel is cheapest to drive on, and by how much per 1000 km;
///   * the break-even pump price at which the verdict would flip;
///   * a caption whenever litres and cost point in OPPOSITE directions,
///     which is exactly what the field screenshot showed (E85 burning fewer
///     litres per 100 km while costing more per km) and which reads as a
///     contradiction until the pump price is on screen.
///
/// Everything is derived from measured intervals. When a figure cannot be
/// computed it is omitted rather than guessed, and rows resting on a single
/// full tank stay visibly provisional.
class _EfficiencyAnalysis extends StatelessWidget {
  const _EfficiencyAnalysis({required this.stats});

  /// Buckets with a measured €/km, cheapest first.
  final List<FuelTypeEfficiencyStats> stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final ranked = [...stats.where((s) => s.avgCostPerKm != null)]
      ..sort((a, b) => a.avgCostPerKm!.compareTo(b.avgCostPerKm!));
    if (ranked.length < 2) return const SizedBox.shrink();

    final best = ranked.first;
    final rest = ranked.skip(1).toList(growable: false);

    final lines = <Widget>[];

    lines.add(Text(
      l.fuelCompareSectionTitle,
      key: const ValueKey('fuel_compare_section_title'),
      style: theme.textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    ));

    // Verdict — the sentence the screen previously made the reader derive.
    lines.add(Text(
      l.fuelCompareVerdictCheaper(best.label),
      key: const ValueKey('fuel_compare_verdict'),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
    ));

    for (final other in rest) {
      // Gap per 1000 km: a per-km delta rounds away to nothing.
      final gap = (other.costPer1000km ?? 0) - (best.costPer1000km ?? 0);
      if (gap > 0) {
        lines.add(_AnalysisLine(
          key: ValueKey('fuel_compare_delta_${other.bucket.key}'),
          icon: Icons.trending_up,
          text: l.fuelCompareVerdictDelta(
            other.label,
            PriceFormatter.formatTotal(gap),
          ),
        ));
      }

      // Break-even: the price at which `other` would match `best`. The most
      // actionable number here — below it, the other fuel wins.
      final breakEven = other.breakEvenPricePerLitreVersus(best);
      if (breakEven != null && breakEven > 0) {
        lines.add(_AnalysisLine(
          key: ValueKey('fuel_compare_breakeven_${other.bucket.key}'),
          icon: Icons.swap_vert,
          text: l.fuelCompareBreakEven(
            other.label,
            best.label,
            PriceFormatter.formatTotal(breakEven),
          ),
        ));
      }
    }

    // Litres and cost disagreeing is not an error, but side by side with no
    // explanation it reads as one.
    final litresContradicts = rest.any((o) {
      final ol = o.avgL100km;
      final bl = best.avgL100km;
      return ol != null && bl != null && ol < bl;
    });
    if (litresContradicts) {
      lines.add(_AnalysisCaption(
        key: const ValueKey('fuel_compare_litres_note'),
        text: l.fuelCompareLitresVsCostNote,
      ));
    }

    lines.add(_AnalysisCaption(
      key: const ValueKey('fuel_compare_breakeven_explain'),
      text: l.fuelCompareBreakEvenExplain,
    ));

    return Container(
      key: const ValueKey('fuel_compare_analysis'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in lines) ...[w, const SizedBox(height: 6)],
        ],
      ),
    );
  }
}

/// One icon + sentence in the analysis block.
class _AnalysisLine extends StatelessWidget {
  const _AnalysisLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

/// A muted explanatory caption — the "why these numbers disagree" text.
class _AnalysisCaption extends StatelessWidget {
  const _AnalysisCaption({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
