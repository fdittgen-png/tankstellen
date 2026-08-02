// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../../../core/error/guarded.dart';
import '../../domain/services/tank_level_estimator.dart';
import '../../providers/tank_level_provider.dart';
import '../../providers/tank_mix_provider.dart';
import '../../providers/trip_history_provider.dart';

/// Tank-level card on the Fuel tab (#1195).
///
/// Reads [tankLevelProvider] for the active vehicle and renders:
/// * a big "{litres} L" number
/// * an "≈ {km} km of range" sub-text (when range is computable)
/// * a `LinearProgressIndicator` that flips to the theme's `error`
///   colour at < 15 % capacity
/// * a caption with the last-fill-up date, the number of trips folded
///   in, and the estimation method
///
/// Empty states:
/// * No active vehicle — renders nothing (the parent FuelTab handles
///   the no-vehicle empty state).
/// * Active vehicle has no fill-ups — renders the
///   `tankLevelEmptyNoFillUp` empty-state message inside a Card so the
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
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.tankLevelTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l.tankLevelEmptyNoFillUp,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
    final capacityL = estimate.capacityL;
    // Progress fraction is null when capacity is unknown — the bar is
    // hidden in that case so we don't fake a percentage.
    final fraction = (capacityL != null && capacityL > 0)
        ? (estimate.levelL / capacityL).clamp(0.0, 1.0)
        : null;
    final lowFuel = fraction != null && fraction < 0.15;
    final barColor = lowFuel ? theme.colorScheme.error : null;

    final litresText = estimate.levelL.toStringAsFixed(1);
    final rangeKm = estimate.rangeKm;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: InkWell(
        onTap: () => _openDetailSheet(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.tankLevelTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                l.tankLevelLitersFormat(litresText),
                key: const Key('tank_level_big_number'),
                // #1914 — was `displayMedium` (~45 sp), which dominated
                // the card; `titleLarge` (~22 sp) roughly halves it
                // while the w600 weight keeps it the card's focal point.
                style: theme.textTheme.titleLarge?.copyWith(
                  color: lowFuel ? theme.colorScheme.error : null,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (rangeKm != null) ...[
                const SizedBox(height: 4),
                Text(
                  l.tankLevelRangeFormat(rangeKm.round().toString()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (fraction != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  key: const Key('tank_level_progress'),
                  value: fraction,
                  color: barColor,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                _captionFor(l, estimate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // #3652 — the current tank's fuel mix for multi-fuel
              // vehicles (E10 topped onto E85 → a blend of both; the
              // consumption depends on it). The provider returns null
              // for single-fuel vehicles; a pure tank stays silent via
              // isBlend. Shell-safe (#2163) like the report card.
              if (_mixLine(ref, l) case final mixText?) ...[
                const SizedBox(height: 4),
                Text(
                  mixText,
                  key: const Key('tank_mix_line'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
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
  String _captionFor(AppLocalizations l, TankLevelEstimate estimate) {
    switch (estimate.source) {
      case TankLevelSource.fillUp:
        return l.tankLevelSourceFillUp(_formatDate(estimate.lastFillUpDate));
      case TankLevelSource.obd2Sensor:
        return l.tankLevelSourceObd2(_formatDate(estimate.sensorReadAt));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
  }

  Future<void> _openDetailSheet(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
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
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.tankLevelDetailSheetTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (relevant.isEmpty)
                  Text(
                    l.tankLevelLastFillUpFormat(
                      _formatDate(lastFillUpDate),
                      '0',
                    ),
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: relevant.length,
                      itemBuilder: (context, index) {
                        final trip = relevant[index];
                        final startedAt = trip.summary.startedAt;
                        final dateText = _formatDate(startedAt);
                        final distance = trip.summary.distanceKm
                            .toStringAsFixed(1);
                        final litres = trip.summary.fuelLitersConsumed;
                        final litresText = litres == null
                            ? ''
                            : ' · ${litres.toStringAsFixed(1)} L';
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.route_outlined),
                          title: Text('$dateText · $distance km$litresText'),
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
  }
}
