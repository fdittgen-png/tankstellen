import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/trip_history_repository.dart';
import '../../providers/trip_fuel_cost_provider.dart';
import 'trip_detail_charts.dart';

/// Headline summary card on the trip detail screen (#890).
///
/// Shows date, vehicle, distance, duration, average + max speed and —
/// for fuel vehicles — average consumption (L/100 km), total fuel used
/// and the estimated fuel cost (#1209). EV trips swap the consumption
/// unit to kWh/100 km and skip the fuel-cost row.
///
/// Per-sample fields (avg/max speed) come from [samples]; the rest is
/// read straight off [TripSummary]. Missing values fall back to the
/// localised "unknown" placeholder so the layout stays stable.
///
/// The fuel-cost row is only rendered when [tripFuelCostProvider]
/// returns a non-null value — see the provider for the full edge-case
/// list (no fill-ups, missing price, EV with no equivalent etc.).
class TripSummaryCard extends ConsumerWidget {
  final TripHistoryEntry entry;
  final VehicleProfile? vehicle;
  final List<TripDetailSample> samples;
  final bool isEv;

  const TripSummaryCard({
    super.key,
    required this.entry,
    required this.vehicle,
    required this.samples,
    required this.isEv,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = entry.summary;
    final unknown = l?.trajetDetailFieldValueUnknown ?? '—';
    final avgUnit = isEv ? 'kWh/100 km' : 'L/100 km';

    // #1209 — estimated trip cost from the most recent fill-up's
    // price-per-litre. Hidden on EV trips (the helper still returns
    // null for fuel-EV mixed setups via the fuelLitersConsumed gate)
    // and whenever the provider has no usable fill-up data.
    final fuelCost = isEv ? null : ref.watch(tripFuelCostProvider(entry.id));

    final date = s.startedAt == null ? unknown : _fmtDate(s.startedAt!);
    final vehicleName = vehicle?.name ?? unknown;
    final distance = '${s.distanceKm.toStringAsFixed(1)} km';
    final duration = s.startedAt != null &&
            s.endedAt != null &&
            s.endedAt!.isAfter(s.startedAt!)
        ? _fmtDuration(s.endedAt!.difference(s.startedAt!))
        : unknown;
    final avgConsumption = s.avgLPer100Km == null
        ? unknown
        : '${s.avgLPer100Km!.toStringAsFixed(1)} $avgUnit';
    final fuelUsed = s.fuelLitersConsumed == null
        ? unknown
        : '${s.fuelLitersConsumed!.toStringAsFixed(2)} L';
    final avgSpeed = _avgSpeedLabel(samples, unknown);
    final maxSpeed = _maxSpeedLabel(samples, unknown);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.trajetDetailSummaryTitle ?? 'Summary',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: l?.trajetDetailFieldDate ?? 'Date',
              value: date,
            ),
            _SummaryRow(
              label: l?.trajetDetailFieldVehicle ?? 'Vehicle',
              value: vehicleName,
            ),
            _SummaryRow(
              label: l?.trajetDetailFieldDistance ?? 'Distance',
              value: distance,
            ),
            _SummaryRow(
              label: l?.trajetDetailFieldDuration ?? 'Duration',
              value: duration,
            ),
            _SummaryRow(
              label: l?.trajetDetailFieldAvgConsumption ?? 'Avg consumption',
              value: avgConsumption,
            ),
            _SummaryRow(
              label: l?.trajetDetailFieldFuelUsed ?? 'Fuel used',
              value: fuelUsed,
            ),
            // #1209 — estimated euro/£/$ cost of the fuel used,
            // derived from the most recent fill-up before this trip.
            // Hidden when the provider returns null (no fill-ups, no
            // valid price, or no fuelLitersConsumed) so the row never
            // shows a misleading "0,00 €" or "—" placeholder.
            if (fuelCost != null)
              _SummaryRow(
                label: l?.trajetDetailFieldFuelCost ?? 'Fuel cost',
                value: PriceFormatter.formatPrice(fuelCost),
              ),
            _SummaryRow(
              label: l?.trajetDetailFieldAvgSpeed ?? 'Avg speed',
              value: avgSpeed,
            ),
            _SummaryRow(
              label: l?.trajetDetailFieldMaxSpeed ?? 'Max speed',
              value: maxSpeed,
            ),
          ],
        ),
      ),
    );
  }

  static String _avgSpeedLabel(
    List<TripDetailSample> samples,
    String unknown,
  ) {
    if (samples.isEmpty) return unknown;
    var sum = 0.0;
    for (final s in samples) {
      sum += s.speedKmh;
    }
    final avg = sum / samples.length;
    return '${avg.toStringAsFixed(1)} km/h';
  }

  static String _maxSpeedLabel(
    List<TripDetailSample> samples,
    String unknown,
  ) {
    if (samples.isEmpty) return unknown;
    var maxV = samples.first.speedKmh;
    for (final s in samples) {
      if (s.speedKmh > maxV) maxV = s.speedKmh;
    }
    return '${maxV.toStringAsFixed(1)} km/h';
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h == 0 && m == 0) return '${s}s';
    if (h == 0) return '${m}m ${s}s';
    return '${h}h ${m}m';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
