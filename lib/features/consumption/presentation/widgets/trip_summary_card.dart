import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../data/trip_history_repository.dart';
import 'trip_detail_charts.dart';

/// Headline summary card on the trip detail screen (#890).
///
/// Shows date, vehicle, distance, duration, average + max speed and —
/// for fuel vehicles — average consumption (L/100 km) and total fuel
/// used. EV trips swap the consumption unit to kWh/100 km.
///
/// Per-sample fields (avg/max speed) come from [samples]; the rest is
/// read straight off [TripSummary]. Missing values fall back to the
/// localised "unknown" placeholder so the layout stays stable.
class TripSummaryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = entry.summary;
    final unknown = l?.trajetDetailFieldValueUnknown ?? '—';
    final avgUnit = isEv ? 'kWh/100 km' : 'L/100 km';

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
