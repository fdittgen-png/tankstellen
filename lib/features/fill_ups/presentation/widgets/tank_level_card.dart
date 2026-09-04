// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/primary_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../../../core/error/guarded.dart';
import '../../domain/services/tank_level_estimator.dart';
import '../../providers/tank_level_provider.dart';
import '../../providers/tank_mix_provider.dart';
import '../../../trips/api.dart';

/// Tank-level card on the Fuel tab (#1195) — the Carburant tab's
/// **primary card** since #3950 (Epic #3947).
///
/// Reads [tankLevelProvider] for the active vehicle and renders, in the
/// visual grammar's roles (`AppText`):
/// * the litres as the card's ONE display-role number, top-left, with
///   the `L` unit on the same alphabetic baseline
/// * the range as ONE body line (the last-tank projection when a closed
///   interval exists, the long-run figure otherwise)
/// * a `LinearProgressIndicator` that flips to the theme's `error`
///   colour at < 15 % capacity — no end labels: the bar and the display
///   number already say "how full"
/// * label-role captions: the long-run range context, the level's
///   source (fill-up anchor date or OBD2 sensor read) and the tank mix
///
/// Empty states:
/// * No active vehicle — renders nothing (the parent FuelTab handles
///   the no-vehicle empty state).
/// * Active vehicle has no fill-ups — renders the
///   `tankLevelEmptyNoFillUp` empty-state message inside the card so the
///   user gets the affordance to "Log a fill-up".
///
/// Tap → opens a bottom sheet listing the trips folded into the
/// calculation. The sheet today is read-only; the "Reset tank" action
/// from the issue body is deferred to a follow-up PR (TODO below).
class TankLevelCard extends ConsumerWidget {
  const TankLevelCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    if (activeVehicle == null) {
      // Parent FuelTab owns the no-vehicle empty state; bail out so
      // the card doesn't double-render the message.
      return const SizedBox.shrink();
    }
    final estimate = ref.watch(tankLevelProvider(activeVehicle.id));
    final l = AppLocalizations.of(context);

    if (!estimate.hasFillUp) {
      return _EmptyTankLevelCard(l: l);
    }

    return _PopulatedTankLevelCard(
      estimate: estimate,
      vehicleId: activeVehicle.id,
    );
  }
}

class _EmptyTankLevelCard extends StatelessWidget {
  final AppLocalizations l;

  const _EmptyTankLevelCard({required this.l});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PrimaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.tankLevelTitle, style: AppText.title(context)),
          const SizedBox(height: Spacing.md),
          Text(
            l.tankLevelEmptyNoFillUp,
            style: AppText.body(context).copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopulatedTankLevelCard extends ConsumerWidget {
  final TankLevelEstimate estimate;
  final String vehicleId;

  const _PopulatedTankLevelCard({
    required this.estimate,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final capacityL = estimate.capacityL;
    // Progress fraction is null when capacity is unknown — the bar is
    // hidden in that case so we don't fake a percentage.
    final fraction = (capacityL != null && capacityL > 0)
        ? (estimate.levelL / capacityL).clamp(0.0, 1.0)
        : null;
    final lowFuel = fraction != null && fraction < 0.15;
    final barColor = lowFuel ? theme.colorScheme.error : null;

    final litresText = UnitFormatter.formatDecimal(estimate.levelL);
    // #3764 — lead with the last-closed-interval projection ("km this
    // reservoir conducts at the last per-100 km consumption"); the
    // long-run average becomes secondary context. With no closed
    // interval yet, primaryRangeKm IS the long-run figure and the card
    // renders exactly as before #3764.
    final rangeKm = estimate.primaryRangeKm;
    final lastIntervalRangeKm = estimate.rangeKmLastInterval;
    final longRunRangeKm = estimate.rangeKm;
    // Secondary line only when it adds information: a last-interval
    // primary exists AND the long-run rounds to a different figure.
    final showLongRunContext = lastIntervalRangeKm != null &&
        longRunRangeKm != null &&
        longRunRangeKm.round() != lastIntervalRangeKm.round();
    final labelStyle = AppText.label(context);

    return PrimaryCard(
      onTap: () => _openDetailSheet(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // #3950 — the card title is a muted caption; the display
          // number right under it is what the eye lands on first.
          Text(l.tankLevelTitle, style: labelStyle),
          const SizedBox(height: Spacing.sm),
          // The number and its unit never wrap or overflow: as a last
          // resort (a 320 dp phone at a large font setting) the pair
          // scales down together, keeping the one baseline.
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    litresText,
                    key: const Key('tank_level_big_number'),
                    style: AppText.display(context).copyWith(
                      color: lowFuel ? theme.colorScheme.error : null,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  // The SI litre symbol is language-neutral; it is not a
                  // translatable string.
                  Text(
                    'L',
                    key: const Key('tank_level_unit'),
                    style: AppText.unit(context),
                  ),
                ],
              ),
            ),
          ),
          // #3903 / #3950 — ONE range sentence in the body role; the
          // long-run figure is a label-role caption beneath it.
          if (rangeKm != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              lastIntervalRangeKm != null
                  ? l.tankLevelRangeLastIntervalFormat(
                      lastIntervalRangeKm.round().toString(),
                    )
                  : l.tankLevelRangeFormat(rangeKm.round().toString()),
              key: const Key('tank_level_range_primary'),
              style: AppText.body(context),
            ),
          ],
          if (showLongRunContext) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              l.tankLevelRangeLongRunFormat(
                longRunRangeKm.round().toString(),
              ),
              key: const Key('tank_level_range_long_run'),
              style: labelStyle,
            ),
          ],
          if (fraction != null) ...[
            const SizedBox(height: Spacing.lg),
            // #3950 — no "0 L … 50 L" end labels: the bar is the
            // fraction and the display number is the litres.
            LinearProgressIndicator(
              key: const Key('tank_level_progress'),
              value: fraction,
              color: barColor,
            ),
          ],
          const SizedBox(height: Spacing.lg),
          Text(_captionFor(l, estimate, locale), style: labelStyle),
          // #3652 — the current tank's fuel mix for multi-fuel
          // vehicles (E10 topped onto E85 → a blend of both; the
          // consumption depends on it). The provider returns null
          // for single-fuel vehicles; a pure tank stays silent via
          // isBlend. Shell-safe (#2163) like the report card.
          if (_mixLine(ref, l) case final mixText?) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              mixText,
              key: const Key('tank_mix_line'),
              style: labelStyle,
            ),
          ],
        ],
      ),
    );
  }

  /// #3652 — "Tank mix: Super E10 57 % · E85 / Bioéthanol 43 %", or
  /// null when there is nothing to say (single-fuel vehicle, pure tank,
  /// unwired provider graph in an isolated test harness). Grade names
  /// come from [FuelType.displayName] — the same product-name labels
  /// the fuel pickers render (#713).
  String? _mixLine(WidgetRef ref, AppLocalizations l) {
    final mix = guard(
      () => ref.watch(tankMixProvider(vehicleId)),
      where: 'TankLevelCard: tank mix watch failed',
      fallback: null,
    );
    if (mix == null || !mix.isBlend()) return null;
    final parts = [
      for (final s in mix.shares)
        if (s.share >= 0.01)
          '${s.fuel.displayName} ${(s.share * 100).round()} %',
    ].join(' · ');
    return l.tankMixCaption(parts);
  }

  /// #3647 tank level v2 — the caption names the level's SOURCE: the
  /// fill-up anchor, or an OBD2 sensor reading newer than that fill.
  /// Trip counts/methods are gone from this card by directive — the
  /// recordings-vs-pump comparison lives on the Trajets tab (#3648).
  String _captionFor(
    AppLocalizations l,
    TankLevelEstimate estimate,
    String locale,
  ) {
    switch (estimate.source) {
      case TankLevelSource.fillUp:
        return l.tankLevelSourceFillUp(
          _formatDate(estimate.lastFillUpDate, locale),
        );
      case TankLevelSource.obd2Sensor:
        return l.tankLevelSourceObd2(
          _formatDate(estimate.sensorReadAt, locale),
        );
    }
  }

  /// #3903 — the UI locale's medium date, not a raw `YYYY-MM-DD`.
  String _formatDate(DateTime? date, String locale) {
    if (date == null) return '';
    return UnitFormatter.formatMediumDate(date, locale: locale);
  }

  Future<void> _openDetailSheet(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final allTrips = ref.read(tripHistoryListProvider);
    final lastFillUpDate = estimate.lastFillUpDate;
    final relevant = allTrips.where((t) {
      if (t.vehicleId != vehicleId) return false;
      final startedAt = t.summary.startedAt;
      if (startedAt == null || lastFillUpDate == null) return false;
      return !startedAt.isBefore(lastFillUpDate);
    }).toList();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.tankLevelDetailSheetTitle,
                  style: AppText.title(sheetContext),
                ),
                const SizedBox(height: Spacing.lg),
                if (relevant.isEmpty)
                  Text(
                    l.tankLevelLastFillUpFormat(
                      _formatDate(lastFillUpDate, locale),
                      '0',
                    ),
                    style: AppText.body(sheetContext),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: relevant.length,
                      itemBuilder: (context, index) {
                        final trip = relevant[index];
                        final startedAt = trip.summary.startedAt;
                        final dateText = _formatDate(startedAt, locale);
                        final distance = UnitFormatter.formatDistance(
                          trip.summary.distanceKm,
                        );
                        final litres = trip.summary.fuelLitersConsumed;
                        // #3950 — the litres go through the same ARB mask
                        // the big number used to ("{litres} L").
                        final litresText = litres == null
                            ? ''
                            : ' · ${l.tankLevelLitersFormat(UnitFormatter.formatDecimal(litres))}';
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.route_outlined),
                          title: Text('$dateText · $distance$litresText'),
                        );
                      },
                    ),
                  ),
                // Reset action deferred to follow-up issue.
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted) return;
  }
}
