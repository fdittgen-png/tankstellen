import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/services/tank_level_estimator.dart';
import '../../providers/tank_level_provider.dart';
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
  final AppLocalizations? l;

  const _EmptyTankLevelCard({required this.l});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.tankLevelTitle ?? 'Tank level',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l?.tankLevelEmptyNoFillUp ??
                  'Log a fill-up to see your tank level',
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
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: InkWell(
        onTap: () => _openDetailSheet(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l?.tankLevelTitle ?? 'Tank level',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l?.tankLevelLitersFormat(litresText) ?? '$litresText L',
                key: const Key('tank_level_big_number'),
                style: theme.textTheme.displayMedium?.copyWith(
                  color: lowFuel ? theme.colorScheme.error : null,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (rangeKm != null) ...[
                const SizedBox(height: 4),
                Text(
                  l?.tankLevelRangeFormat(rangeKm.round().toString()) ??
                      '≈ ${rangeKm.round()} km of range',
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
            ],
          ),
        ),
      ),
    );
  }

  String _captionFor(AppLocalizations? l, TankLevelEstimate estimate) {
    final dateText = _formatDate(estimate.lastFillUpDate);
    final countText = estimate.tripsSince.toString();
    final lastFillUpLine = l?.tankLevelLastFillUpFormat(dateText, countText) ??
        'Last fill-up: $dateText · $countText trip(s) since';
    final methodLabel = _methodLabel(l, estimate.method);
    return '$lastFillUpLine · $methodLabel';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _methodLabel(AppLocalizations? l, TankLevelEstimationMethod method) {
    switch (method) {
      case TankLevelEstimationMethod.obd2:
        return l?.tankLevelMethodObd2 ?? 'OBD2 measured';
      case TankLevelEstimationMethod.distanceFallback:
        return l?.tankLevelMethodDistanceFallback ??
            'distance-based estimate';
      case TankLevelEstimationMethod.mixed:
        return l?.tankLevelMethodMixed ?? 'mixed measurement';
    }
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
                  l?.tankLevelDetailSheetTitle ??
                      'Trips since last fill-up',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (relevant.isEmpty)
                  Text(
                    l?.tankLevelLastFillUpFormat(
                          _formatDate(lastFillUpDate),
                          '0',
                        ) ??
                        'No trips yet',
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
                        final distance =
                            trip.summary.distanceKm.toStringAsFixed(1);
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
