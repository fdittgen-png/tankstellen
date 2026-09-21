// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4366 — the driving-pattern comparison surface.
///
/// Purely presentational: it is handed a finished
/// [DrivingPatternComparison] and the display names of the selected
/// vehicles. It never selects a vehicle, never reads the active one and
/// never touches a trip repository — #4365 owns the selection and period
/// flow, and the aggregation happens behind an await before this widget
/// is ever built.
///
/// What it insists on rendering:
///
///  * every figure **with its exposure** — the same rate over 100 km and
///    over 1 000 km reads alike until the caption underneath says how
///    much driving each rests on;
///  * a dimension one vehicle's recordings cannot support, as a stated
///    REASON rather than a missing row or a zero;
///  * the caveats, the excluded records and the refusal to rank
///    condition-adjusted;
///  * a note, on the dimensions where it applies, that more of the thing
///    is not automatically worse driving.
library;

import 'package:flutter/material.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/driving_pattern_comparison.dart';
import 'driving_pattern_labels.dart';

/// Compares how the driver behaved at the wheel of each selected vehicle.
class DrivingPatternComparisonCard extends StatelessWidget {
  const DrivingPatternComparisonCard({
    super.key,
    required this.comparison,
    required this.vehicleNames,
  });

  /// The finished read model (#4366).
  final DrivingPatternComparison comparison;

  /// Display name per vehicle id, supplied by #4365's selection flow.
  /// A missing entry falls back to the id — an identifier, not prose.
  final Map<String, String> vehicleNames;

  String _name(String vehicleId) => vehicleNames[vehicleId] ?? vehicleId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      title: l.drivingPatternComparisonTitle,
      subtitle: l.drivingPatternComparisonSubtitle,
      leadingIcon: Icons.speed_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._matchingLines(l, theme),
          const SizedBox(height: 12),
          if (!comparison.hasEvidence)
            Text(l.drivingPatternInsufficient, style: theme.textTheme.bodyMedium)
          else
            ..._dimensions(l, theme),
          ..._differences(l, theme),
          const SizedBox(height: 12),
          _caveat(theme, l.drivingPatternNoAdjustedRanking),
          if (comparison.unassignedTripCount > 0)
            _caveat(
                theme,
                l.drivingPatternUnassignedExcluded(
                    comparison.unassignedTripCount)),
          _caveat(theme, l.drivingPatternNotFuelNote),
        ],
      ),
    );
  }

  List<Widget> _matchingLines(AppLocalizations l, ThemeData theme) {
    final m = comparison.matching;
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (!m.isMatched) {
      return [Text(l.drivingPatternUnmatchedNotice, style: style)];
    }
    return [
      Text(
        l.drivingPatternMatchedOn(
            [for (final c in m.cohorts) cohortLabel(l, c)].join(' · ')),
        style: style,
      ),
      Text(
        l.drivingPatternMatchCounts(m.matchedTripCount, m.unmatchedTripCount),
        style: style,
      ),
    ];
  }

  /// One block per dimension at least one vehicle supports. A dimension
  /// nobody can speak to is not rendered; a dimension only SOME vehicles
  /// support is, with the others' reason in place of a figure.
  List<Widget> _dimensions(AppLocalizations l, ThemeData theme) {
    final out = <Widget>[];
    for (final spec in kDrivingMeasures) {
      final anySupported = comparison.subjects
          .any((s) => s.measure(spec.id)?.isSupported ?? false);
      if (!anySupported) continue;
      out
        ..add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            measureLabel(l, spec.id),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ))
        ..addAll([
          for (final subject in comparison.subjects)
            _measureRow(l, theme, subject, spec.id),
        ]);
      if (spec.contextDependent) {
        out.add(_caveat(theme, l.drivingPatternContextNote));
      }
    }
    return out;
  }

  Widget _measureRow(AppLocalizations l, ThemeData theme,
      VehicleDrivingPattern subject, DrivingMeasureId id) {
    final measure = subject.measure(id);
    final name = _name(subject.vehicleId);
    final label = measureLabel(l, id);
    final captionStyle = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (measure == null || !measure.isSupported) {
      final reason = unavailableLabel(l, measure?.metric.reason);
      return Semantics(
        container: true,
        excludeSemantics: true,
        label: l.drivingPatternUnavailableSemantics(label, name, reason),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
              Expanded(flex: 2, child: Text(reason, style: captionStyle)),
            ],
          ),
        ),
      );
    }
    final value =
        measureValueLabel(l, measure.spec.unit, measure.metric.valueOrNull!);
    final evidence = evidenceCaption(l, measure);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l.drivingPatternMeasureSemantics(label, name, value, evidence),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: theme.textTheme.bodyMedium),
                  Text(evidence, style: captionStyle, textAlign: TextAlign.end),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _differences(AppLocalizations l, ThemeData theme) {
    if (comparison.differences.isEmpty) return const [];
    final style = theme.textTheme.bodySmall;
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(
          l.drivingPatternDifferencesTitle,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      for (final d in comparison.differences)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.drivingPatternDifferenceLine(
                  measureLabel(l, d.id),
                  _sideValue(l, d.id, d.higher),
                  _name(d.higherVehicleId),
                  _sideValue(l, d.id, d.lower),
                  _name(d.lowerVehicleId),
                ),
                style: style,
              ),
              _qualificationChips(theme, l, d.qualifications),
            ],
          ),
        ),
    ];
  }

  String _sideValue(AppLocalizations l, DrivingMeasureId id, double value) =>
      measureValueLabel(l, measureSpec(id).unit, value);

  Widget _qualificationChips(
      ThemeData theme, AppLocalizations l, Set<ComparisonQualification> qs) {
    final labels = qualificationLabels(l, qs);
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final text in labels)
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.sm,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(text, style: theme.textTheme.labelSmall),
              ),
            ),
        ],
      ),
    );
  }

  Widget _caveat(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          text,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
}
