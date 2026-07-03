// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/lessons/lesson_format.dart';
import '../../domain/fuel_event_attribution.dart';

/// "Where your fuel went" breakdown card on the Trip detail screen
/// (#3432, epic #3416 task 7).
///
/// Renders the per-class litres from the pure [FuelAttribution]
/// detector as compact rows: the three waste classes (idling, hard
/// accelerations, high-RPM cruising), the positive fuel-cut-coasting
/// saving, and — when the trip has a total fuel figure — the
/// "normal driving" remainder so the rows read as a whole-trip story.
///
/// Self-hides ([SizedBox.shrink]) when the attribution found nothing
/// above the lesson noise floor: legacy trips, EV trips (the parent
/// gates those anyway), GPS-only trips without engine signals — the
/// layout is unchanged for all of them.
class FuelBreakdownCard extends StatelessWidget {
  /// Per-event attribution for the trip (pure, computed by the parent
  /// once and memoised across rebuilds).
  final FuelAttribution attribution;

  /// The trip's total consumed litres (`TripSummary.fuelLitersConsumed`)
  /// — null when no fuel figure exists; the remainder row is skipped.
  final double? totalTripLiters;

  const FuelBreakdownCard({
    super.key,
    required this.attribution,
    required this.totalTripLiters,
  });

  /// Litres below which a row is indistinguishable from noise —
  /// canonical with the lessons' noise floor.
  static const double _noiseFloorLiters = 0.05;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final idle = attribution.idleLiters;
    final harsh = attribution.harshAccelLiters;
    final cruise = attribution.highRpmCruiseLiters;
    final saved = attribution.coastingSavedLiters;

    final rows = <_BreakdownRow>[
      if (idle >= _noiseFloorLiters)
        _BreakdownRow(
          icon: Icons.hourglass_empty,
          label: l.fuelBreakdownIdle,
          liters: idle,
          color: scheme.error,
          keySuffix: 'idle',
        ),
      if (harsh >= _noiseFloorLiters)
        _BreakdownRow(
          icon: Icons.flash_on,
          label: l.fuelBreakdownHarshAccel,
          liters: harsh,
          color: scheme.error,
          keySuffix: 'harshAccel',
        ),
      if (cruise >= _noiseFloorLiters)
        _BreakdownRow(
          icon: Icons.speed,
          label: l.fuelBreakdownHighRpmCruise,
          liters: cruise,
          color: scheme.error,
          keySuffix: 'highRpmCruise',
        ),
    ];

    // "Normal driving" remainder — only meaningful when the trip has a
    // measured total AND at least one waste row exists to subtract.
    final total = totalTripLiters;
    if (rows.isNotEmpty && total != null && total > 0) {
      final wasted = idle + harsh + cruise;
      final remainder = total - wasted;
      if (remainder > 0) {
        rows.add(_BreakdownRow(
          icon: Icons.directions_car,
          label: l.fuelBreakdownEfficient,
          liters: remainder,
          color: scheme.onSurfaceVariant,
          keySuffix: 'efficient',
          isNeutral: true,
        ));
      }
    }

    final hasSaving = saved >= _noiseFloorLiters;
    if (rows.isEmpty && !hasSaving) return const SizedBox.shrink();

    return Card(
      key: const Key('fuel_breakdown_card'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.fuelBreakdownTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final row in rows) row,
            if (hasSaving)
              _BreakdownRow(
                icon: Icons.eco,
                label: l.fuelBreakdownCoastingSaved,
                liters: saved,
                color: scheme.primary,
                keySuffix: 'coastingSaved',
                isSaving: true,
              ),
          ],
        ),
      ),
    );
  }
}

/// One breakdown line: icon, class label, and the litres badge
/// (`+X.X L` waste, `−X.X L` saving, plain `X.X L` for the neutral
/// remainder).
class _BreakdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double liters;
  final Color color;
  final String keySuffix;
  final bool isSaving;
  final bool isNeutral;

  const _BreakdownRow({
    required this.icon,
    required this.label,
    required this.liters,
    required this.color,
    required this.keySuffix,
    this.isSaving = false,
    this.isNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final litersText = formatLessonLiters(liters);
    final badge = isSaving
        ? l.insightTrailingLitersSaved(litersText)
        : isNeutral
            ? l.fuelBreakdownLiters(litersText)
            : l.insightTrailingLitersWasted(litersText);
    return Padding(
      key: ValueKey('fuel_breakdown_row_$keySuffix'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            badge,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
