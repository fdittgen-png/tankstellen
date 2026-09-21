// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// One vehicle's column in the #4367 same-trip comparison.
///
/// Renders only what the read model computed: no price, consumption,
/// route or currency arithmetic happens in `build` (#4363's rule, and
/// the reason the two surfaces cannot disagree).
///
/// Four display rules the widget enforces:
///
///  1. **cost to drive and cash required are never the same row.** Each
///     carries its own sentence, so "this car starts full" can never be
///     read as "this car is cheaper".
///  2. **an unavailable figure shows its REASON**, never a dash that
///     could pass for a zero.
///  3. **every planning input shows where it came from** — your
///     records, your own assumption, an estimate, or not known. A typed
///     consumption is allowed; an unlabelled one is not.
///  4. **every figure's screen-reader label repeats the vehicle name**,
///     because at large text sizes the columns stack and a number on
///     its own belongs to no car.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/comparison_eligibility.dart';
import '../../../../core/domain/money.dart';
import '../../../../core/domain/vehicle_trip_comparison.dart';
import '../../../../core/domain/vehicle_trip_providers.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/comparison_labels.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/utils/localized_fuel_name.dart';
import '../../../../core/utils/number_parsing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Where one planning input came from, in the driver's language.
String tripInputSourceLabel(AppLocalizations l, TripInputSource source) =>
    switch (source) {
      TripInputSource.measured => l.vehTripSourceMeasured,
      TripInputSource.manual => l.vehTripSourceManual,
      TripInputSource.estimated => l.vehTripSourceEstimated,
      TripInputSource.unknown => l.vehTripSourceUnknown,
    };

/// One vehicle's forecast for the shared journey.
class VehicleTripColumnCard extends StatelessWidget {
  const VehicleTripColumnCard({
    super.key,
    required this.column,
    required this.index,
    required this.total,
    required this.stationNames,
    required this.onApply,
  });

  final VehicleTripColumn column;
  final int index;
  final int total;

  /// Station id → display name, so the stops are an itinerary rather
  /// than a list of identifiers.
  final Map<String, String> stationNames;

  /// Hand THIS vehicle's plan to navigation. Always an explicit act.
  final VoidCallback? onApply;

  String get _name => column.basis.vehicleName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fuel = column.basis.fuel;
    return Semantics(
      container: true,
      label: l.vehTripSemanticsColumn(_name, index + 1, total),
      child: SectionCard(
        title: _name,
        subtitle: fuel == null ? null : localizedFuelName(l, fuel),
        leadingIcon: Icons.directions_car_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._assumptions(context, l, theme),
            _assumptionField(),
            ..._figures(context, l, theme),
            ..._itinerary(context, l, theme),
            ..._caveats(context, l, theme),
            if (onApply != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonal(
                  key: Key('veh_trip_apply_${column.vehicleId}'),
                  onPressed: onApply,
                  child: Text(l.vehTripApply),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// What this vehicle brought to the journey, each input labelled with
  /// where it came from.
  List<Widget> _assumptions(
      BuildContext context, AppLocalizations l, ThemeData theme) {
    final basis = column.basis;
    final consumption = basis.consumptionLPer100km;
    final start = basis.startLitres;
    return [
      _row(
        context,
        l,
        l.vehTripConsumptionLabel,
        consumption == null
            ? l.vehTripUnavailableShort
            : UnitFormatter.formatConsumption(consumption, isEv: false),
        note: tripInputSourceLabel(l, basis.consumptionSource),
        theme: theme,
      ),
      _row(
        context,
        l,
        l.vehTripStartTankLabel,
        start == null
            ? l.vehTripUnavailableShort
            : UnitFormatter.formatVolume(start),
        note: tripInputSourceLabel(l, basis.levelSource),
        theme: theme,
      ),
    ];
  }

  List<Widget> _figures(
          BuildContext context, AppLocalizations l, ThemeData theme) =>
      [
        _metric(context, l, theme, l.vehTripFuelUsedLabel,
            column.fuelUsedLitres, UnitFormatter.formatVolume),
        _money(context, l, theme, l.vehTripCostToDriveLabel,
            column.costToDrive,
            note: l.vehTripCostToDriveNote),
        _money(context, l, theme, l.vehTripCashRequiredLabel,
            column.cashRequired,
            note: l.vehTripCashRequiredNote),
        _metric(context, l, theme, l.vehTripStopsLabel, column.stopCount,
            (v) => UnitFormatter.formatDecimal(v, fractionDigits: 0)),
        _metric(context, l, theme, l.vehTripExtraKmLabel, column.extraKm,
            UnitFormatter.formatDistance),
        _metric(context, l, theme, l.vehTripTimeLabel, column.totalMinutes,
            (v) => formatTravelDuration(l, v)),
        _metric(context, l, theme, l.vehTripEndTankLabel, column.endLitres,
            UnitFormatter.formatVolume),
      ];

  /// The ordered stops, named. A plan whose stops are ids is not an
  /// itinerary anyone can drive (#4363).
  List<Widget> _itinerary(
      BuildContext context, AppLocalizations l, ThemeData theme) {
    final plan = column.plan;
    if (plan == null) return const [];
    if (plan.stops.isEmpty) return [_note(theme, l.vehTripNoStops)];
    final currency = plan.currencyCode;
    return [
      for (final stop in plan.stops)
        _note(
          theme,
          l.vehTripStopLine(
            stationNames[stop.candidate.stationId] ??
                stop.candidate.stationId,
            UnitFormatter.formatVolume(stop.litres),
            PriceFormatter.formatTotal(stop.cost,
                currencyOverride: currency),
          ),
        ),
    ];
  }

  List<Widget> _caveats(
      BuildContext context, AppLocalizations l, ThemeData theme) {
    final gap = column.gap;
    final unavailable = column.unavailable;
    return [
      if (gap != null)
        _warning(
          theme,
          l.vehTripGap(UnitFormatter.formatDistance(gap.fromKm),
              UnitFormatter.formatDistance(gap.toKm)),
        ),
      if (unavailable != null)
        _warning(theme, comparisonReasonLabel(l, unavailable)),
      if (column.searchWasBounded) _note(theme, l.vehTripBoundedSearch),
      if (column.excludedForCurrency)
        _note(theme, l.vehTripCurrencyWithheld),
      if (column.evidenceIncomplete)
        _note(theme, l.vehTripIncompleteEvidence),
    ];
  }

  Widget _metric(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
    String label,
    ComparableMetric<double> metric,
    String Function(double) format,
  ) {
    final value = metric.valueOrNull;
    return _row(
      context,
      l,
      label,
      value == null ? l.vehTripUnavailableShort : format(value),
      note: _caveatOf(l, metric),
      theme: theme,
    );
  }

  Widget _money(
    BuildContext context,
    AppLocalizations l,
    ThemeData theme,
    String label,
    ComparableMetric<Money> metric, {
    required String note,
  }) {
    final value = metric.valueOrNull;
    return _row(
      context,
      l,
      label,
      value == null
          ? l.vehTripUnavailableShort
          : PriceFormatter.formatTotal(value.amount,
              currencyOverride: value.currencyCode),
      // A withheld money figure owes its own reason, in this
      // surface's terms: the shared vocabulary speaks of counted fill
      // windows, which is not what is missing on a forecast.
      note: value == null
          ? _moneyRefusal(l, metric)
          : [note, _caveatOf(l, metric)].whereType<String>().join(' '),
      theme: theme,
    );
  }

  /// Why a money figure is withheld, said in journey terms.
  String _moneyRefusal(AppLocalizations l, ComparableMetric<Money> metric) =>
      metric.reason == ComparisonUnavailableReason.missingPrices
          ? l.vehTripNoPriceForFuel
          : _caveatOf(l, metric) ?? l.vehTripUnavailableShort;

  /// The sentence a metric owes the driver: its reason when it has no
  /// value, its qualifications when it has one.
  String? _caveatOf(AppLocalizations l, ComparableMetric<Object> metric) {
    final reason = metric.reason;
    if (reason != null) return comparisonReasonLabel(l, reason);
    if (metric.qualifications.isEmpty) return null;
    return [
      for (final q in metric.qualifications)
        comparisonQualificationLabel(l, q),
    ].join(' ');
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l,
    String label,
    String value, {
    required ThemeData theme,
    String? note,
  }) =>
      Semantics(
        label: l.vehTripSemanticsColumn(_name, index + 1, total),
        child: Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child:
                          Text(label, style: theme.textTheme.bodyMedium)),
                  const SizedBox(width: Spacing.md),
                  // Flexible, not a bare Text: at 200 % text scale a
                  // long figure and a long label must wrap rather than
                  // push each other off the card.
                  Flexible(
                    child: Text(value,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
              if (note != null && note.trim().isNotEmpty)
                Text(note,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );

  Widget _assumptionField() => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: VehicleTripAssumptionField(
          key: Key('veh_trip_assumption_${column.vehicleId}'),
          vehicleId: column.vehicleId,
        ),
      );

  Widget _note(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.sm),
        child: Text(text,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );

  Widget _warning(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: Spacing.md),
        child: Text(text,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error)),
      );
}

/// The driver's own consumption assumption for ONE vehicle.
///
/// It writes only this vehicle's entry in
/// `vehicleTripAssumptionsProvider`, so a typed figure recomputes this
/// column's plan and then the comparison — and leaves every other
/// column's inputs exactly as they were. Clearing it hands the vehicle
/// back to its measured evidence rather than to a default.
class VehicleTripAssumptionField extends ConsumerStatefulWidget {
  const VehicleTripAssumptionField({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<VehicleTripAssumptionField> createState() =>
      _VehicleTripAssumptionFieldState();
}

class _VehicleTripAssumptionFieldState
    extends ConsumerState<VehicleTripAssumptionField> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final assumption = ref.watch(vehicleTripAssumptionsProvider)[
            widget.vehicleId] ??
        VehicleTripAssumption.none;
    final notifier = ref.read(vehicleTripAssumptionsProvider.notifier);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.vehTripAssumptionLabel),
            onSubmitted: (text) => notifier.setConsumption(
                widget.vehicleId, parseUserDouble(text)),
          ),
        ),
        if (assumption.consumptionLPer100km != null)
          TextButton(
            onPressed: () {
              _controller.clear();
              notifier.setConsumption(widget.vehicleId, null);
            },
            child: Text(l.vehTripAssumptionClear),
          ),
      ],
    );
  }
}
