// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// One vehicle's card in the #4365 comparison.
///
/// Renders only what the read model already computed — no aggregation
/// happens in `build`. Three display rules the widget enforces:
///
///  1. an unavailable metric shows "not comparable" AND its reason,
///     never a dash that could read as a zero;
///  2. a qualified metric always renders its caveats beneath it;
///  3. every figure's screen-reader label repeats the vehicle name, so
///     a column is never mistaken for its neighbour at large text
///     sizes, where the cards stack instead of sitting side by side.
library;

import 'package:flutter/material.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/localized_fuel_name.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/vehicle_history_comparison.dart';
import 'vehicle_comparison_labels.dart';

/// One comparison column.
class VehicleComparisonColumnCard extends StatelessWidget {
  const VehicleComparisonColumnCard({
    super.key,
    required this.column,
    required this.vehicleName,
    required this.index,
    required this.total,
    required this.isReference,
    required this.isMissing,
    required this.onShowSources,
    required this.onUseAsReference,
    required this.onRemove,
  });

  final VehicleHistoryColumn column;
  final String vehicleName;
  final int index;
  final int total;
  final bool isReference;

  /// True when the vehicle profile has been deleted. The column stays,
  /// so the selection can be recovered rather than silently reset.
  final bool isMissing;

  final void Function(ComparisonFigure figure) onShowSources;
  final VoidCallback onUseAsReference;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: l.vehCompareSemanticsColumn(vehicleName, index + 1, total),
      child: SectionCard(
        title: vehicleName,
        subtitle: isReference ? l.vehCompareReferenceLabel(vehicleName) : null,
        leadingIcon: Icons.directions_car_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMissing) _missingBanner(context, l, theme),
            _section(theme, l.vehCompareEvidenceTitle),
            _plain(theme, l.vehCompareWindowCount(column.matchedWindowCount)),
            _plain(theme, l.vehCompareTripCount(column.coverage.tripCount)),
            _row(context, l, l.vehCompareMatchedDistance,
                UnitFormatter.formatDistance(column.matchedDistanceKm)),
            _row(context, l, l.vehCompareRecordedDistance,
                UnitFormatter.formatDistance(column.recordedDistanceKm)),
            ..._boundaryNotes(context, l, theme),
            _section(theme, l.vehCompareConsumptionTitle),
            _metric(context, l, l.vehCompareConsumptionTitle,
                column.consumptionPer100Km, _consumption,
                figure: ComparisonFigure.consumption),
            ..._fuelShares(context, l, theme),
            _metric(context, l, l.vehCompareRangeLabel,
                column.estimatedRangeKm, UnitFormatter.formatDistance),
            _section(theme, l.vehCompareCostTitle),
            _metric(context, l, l.vehCompareCostPerKmLabel, column.costPerKm,
                _perKm,
                figure: ComparisonFigure.costPerKm),
            _metric(context, l, l.vehCompareConsumedFuelLabel,
                column.consumedFuelCostPerKm, _perKm,
                figure: ComparisonFigure.consumedFuelCost),
            _moneyMetric(context, l),
            _metric(context, l, l.vehComparePricePerUnitLabel,
                column.pricePerUnit, _perKm),
            _section(theme, l.vehCompareRefuellingTitle),
            ..._refuelling(context, l),
            ..._stations(context, l, theme),
            if (!isReference && !isMissing)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: Key('veh_compare_reference_${column.vehicleId}'),
                  onPressed: onUseAsReference,
                  child: Text(l.vehCompareSetReference),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _missingBanner(
          BuildContext context, AppLocalizations l, ThemeData theme) =>
      Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: Container(
          padding: Spacing.chipPadding,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: AppRadius.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.vehCompareMissingVehicle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onErrorContainer)),
              TextButton(
                key: const Key('veh_compare_remove_missing'),
                onPressed: onRemove,
                child: Text(l.vehCompareRemoveFromSelection),
              ),
            ],
          ),
        ),
      );

  List<Widget> _boundaryNotes(
      BuildContext context, AppLocalizations l, ThemeData theme) {
    final opening = column.opening;
    return [
      if (column.boundaryWindowsIncluded > 0)
        _note(theme,
            l.vehCompareBoundaryIncluded(column.boundaryWindowsIncluded)),
      if (column.boundaryWindowsExcluded > 0)
        _note(theme,
            l.vehCompareBoundaryExcluded(column.boundaryWindowsExcluded)),
      if (opening != null && opening.precedesPeriodStart)
        _note(
            theme,
            l.vehCompareOpeningCarried(UnitFormatter.formatMediumDate(
                opening.openedAt,
                locale: Localizations.localeOf(context).toString()))),
    ];
  }

  List<Widget> _fuelShares(
          BuildContext context, AppLocalizations l, ThemeData theme) =>
      [
        for (final e in column.fuelShares.entries)
          _note(
              theme,
              l.vehCompareFuelShare(localizedFuelName(l, e.key),
                  '${UnitFormatter.formatDecimal(e.value * 100, fractionDigits: 0)} %')),
      ];

  List<Widget> _refuelling(BuildContext context, AppLocalizations l) {
    final p = column.refuelling;
    final days = p.medianTimeBetweenFills?.inDays;
    return [
      _row(context, l, l.vehCompareFillCountLabel, '${p.fillCount}'),
      _row(context, l, l.vehCompareTotalQuantityLabel,
          UnitFormatter.formatDecimal(p.totalQuantity)),
      _row(context, l, l.vehCompareTypicalQuantityLabel,
          UnitFormatter.formatDecimal(p.typicalQuantity)),
      _row(context, l, l.vehCompareFullPartialLabel,
          l.vehCompareFullPartialValue(p.fullFillCount, p.partialFillCount)),
      _row(
          context,
          l,
          l.vehCompareBetweenFillsLabel,
          p.medianDistanceBetweenFillsKm == null
              ? l.vehCompareUnavailableShort
              : UnitFormatter.formatDistance(p.medianDistanceBetweenFillsKm!)),
      if (days != null)
        _row(context, l, l.vehCompareBetweenFillsLabel,
            l.vehCompareBetweenFillsDays(days)),
      if (p.correctionCount > 0)
        _row(context, l, l.vehCompareCorrectionsLabel, '${p.correctionCount}'),
    ];
  }

  List<Widget> _stations(
      BuildContext context, AppLocalizations l, ThemeData theme) {
    if (column.stationFillCounts.isEmpty &&
        column.unnamedStationFillCount == 0) {
      return const [];
    }
    return [
      _section(theme, l.vehCompareStationsTitle),
      for (final e in column.stationFillCounts.entries)
        _plain(theme, l.vehCompareStationVisits(e.key, e.value)),
      if (column.unnamedStationFillCount > 0)
        _note(theme,
            l.vehCompareStationUnnamed(column.unnamedStationFillCount)),
    ];
  }

  Widget _moneyMetric(BuildContext context, AppLocalizations l) {
    final metric = column.recordedSpend;
    final money = metric.valueOrNull;
    return _renderMetric(
      context,
      l,
      l.vehCompareRecordedSpendLabel,
      metric,
      money == null
          ? null
          : PriceFormatter.formatTotal(money.amount,
              currencyOverride: money.currencyCode),
      ComparisonFigure.recordedSpend,
    );
  }

  Widget _metric(
    BuildContext context,
    AppLocalizations l,
    String label,
    ComparableMetric<double> metric,
    String Function(double) format, {
    ComparisonFigure? figure,
  }) {
    final value = metric.valueOrNull;
    return _renderMetric(context, l, label, metric,
        value == null ? null : format(value), figure);
  }

  Widget _renderMetric(
    BuildContext context,
    AppLocalizations l,
    String label,
    ComparableMetric<Object> metric,
    String? formatted,
    ComparisonFigure? figure,
  ) {
    final theme = Theme.of(context);
    final unavailable = metric.eligibility == MetricEligibility.unavailable;
    // An absent metric is not a zero: it says so, and says why.
    final shown = formatted ?? l.vehCompareUnavailableShort;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: l.vehCompareSemanticsMetric(label, shown, vehicleName),
            child: ExcludeSemantics(
              // Both halves flex: at 2x text on a 320 dp screen a fixed
              // value column overflows the row instead of wrapping.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(label, style: theme.textTheme.bodySmall)),
                  const SizedBox(width: Spacing.md),
                  Flexible(
                    child: Text(
                      shown,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: unavailable
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (metric.qualifications
              .contains(ComparisonQualification.estimatedBasis))
            _estimateBadge(theme, l),
          if (unavailable && metric.reason != null)
            _note(theme, comparisonReasonLabel(l, metric.reason!)),
          for (final caveat in comparisonQualificationLabels(l, metric))
            _note(theme, caveat),
          if (figure != null && !column.sourcesFor(figure).isEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: Key('veh_compare_sources_${column.vehicleId}_'
                    '${figure.name}'),
                onPressed: () => onShowSources(figure),
                child: Text(l.vehCompareSourcesAction),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations l, String label,
      String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Semantics(
        container: true,
        label: l.vehCompareSemanticsMetric(label, value, vehicleName),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
              const SizedBox(width: Spacing.md),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A compact marker on a modelled figure, beside the sentence that
  /// says the same thing at length — a glance must not mistake a model
  /// for a measurement.
  Widget _estimateBadge(ThemeData theme, AppLocalizations l) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.xs),
        child: Container(
          padding: Spacing.pillPadding,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: AppRadius.sm,
          ),
          child: Text(l.vehCompareEstimateBadge,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
        ),
      );

  Widget _section(ThemeData theme, String title) => Padding(
        padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.sm),
        child: Text(title,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary)),
      );

  Widget _plain(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Text(text, style: theme.textTheme.bodyMedium),
      );

  Widget _note(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.xs),
        child: Text(text,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );

  static String _consumption(double value) =>
      UnitFormatter.formatConsumption(value, isEv: false);

  static String _perKm(double value) => PriceFormatter.formatPerKm(value);
}
