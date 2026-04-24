import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/trip_history_repository.dart';
import '../../providers/trip_history_provider.dart';
import '../widgets/trip_detail_charts.dart';

/// Trip detail screen (#890).
///
/// Renders a recorded trip's headline summary card plus the full
/// recording profile (speed / fuel-rate / RPM over time) as scrollable
/// [CustomPaint] line charts — mirroring the chart pattern shipped by
/// #582's charging charts.
///
/// ## Data flow
/// * [TripHistoryEntry] is read from [tripHistoryListProvider] keyed
///   by the path id. A missing entry (stale deep link) falls back to
///   a friendly empty-state instead of crashing the route.
/// * The per-sample time series is supplied via [samples]. The Hive
///   schema today stores only the aggregated [TripSummary], so the
///   production route passes an empty list and the charts render the
///   shared empty-state caption. Future PRs will persist samples
///   alongside the summary — tests inject them directly today so the
///   detail screen's contract ships now.
///
/// ## AppBar actions
/// * **Share** copies a JSON summary + CSV sample block to the
///   clipboard so the user can paste it into a support ticket / diff
///   tool without needing any backend.
/// * **Delete** confirms and then calls
///   [TripHistoryList.delete] before popping back to the Trajets tab.
class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  /// Optional per-sample profile used to populate the charts (#890).
  ///
  /// Defaults to an empty list because the Hive schema doesn't yet
  /// persist samples — every chart then renders its empty-state
  /// caption, keeping the section layout honest. Tests and future
  /// persisted-samples PRs pass a non-empty list to drive the
  /// CustomPaint path.
  final List<TripDetailSample> samples;

  const TripDetailScreen({
    super.key,
    required this.tripId,
    this.samples = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final trips = ref.watch(tripHistoryListProvider);
    final entry = trips.where((t) => t.id == tripId).firstOrNull;
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final vehicles = ref.watch(vehicleProfileListProvider);

    // Resolve the per-trip vehicle so the summary card can show the
    // friendly name. Fall back to the active vehicle when the trip
    // pre-dates the vehicleId tagging from #889.
    final vehicle = entry?.vehicleId == null
        ? activeVehicle
        : vehicles
                .where((v) => v.id == entry!.vehicleId)
                .firstOrNull ??
            activeVehicle;
    final isEv = vehicle?.type == VehicleType.ev;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
        title: Text(l?.tripHistoryTitle ?? 'Trip history'),
        actions: entry == null
            ? null
            : [
                IconButton(
                  key: const Key('trip_detail_share_button'),
                  icon: const Icon(Icons.share),
                  tooltip: l?.trajetDetailShareAction ?? 'Share',
                  onPressed: () => _onShare(context, l, entry, vehicle),
                ),
                IconButton(
                  key: const Key('trip_detail_delete_button'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l?.trajetDetailDeleteAction ?? 'Delete',
                  onPressed: () => _onDelete(context, ref, l),
                ),
              ],
      ),
      body: entry == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l?.tripHistoryEmptyTitle ?? 'No trips yet',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _TripDetailBody(
              entry: entry,
              vehicle: vehicle,
              samples: samples,
              isEv: isEv,
            ),
    );
  }

  Future<void> _onShare(
    BuildContext context,
    AppLocalizations? l,
    TripHistoryEntry entry,
    VehicleProfile? vehicle,
  ) async {
    final payload = _buildSharePayload(entry, vehicle, samples);
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    final msg = l?.trajetDetailShareCopied ?? 'Copied to clipboard';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l?.trajetDetailDeleteConfirmTitle ?? 'Delete this trip?',
        ),
        content: Text(
          l?.trajetDetailDeleteConfirmBody ??
              'This trip will be permanently removed from your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l?.trajetDetailDeleteConfirmCancel ?? 'Cancel',
            ),
          ),
          TextButton(
            key: const Key('trip_detail_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l?.trajetDetailDeleteConfirmConfirm ?? 'Delete',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(tripHistoryListProvider.notifier).delete(tripId);
    if (!context.mounted) return;
    context.pop();
  }
}

/// Structured clipboard payload: JSON header summarising the trip,
/// followed by a CSV block of every sample. This keeps the share
/// action useful for both machines (paste into a diff tool) and
/// humans (skim in a text editor). Exposed so tests can assert on
/// the exact text written to [Clipboard].
@visibleForTesting
String buildTripDetailSharePayload({
  required TripHistoryEntry entry,
  required VehicleProfile? vehicle,
  required List<TripDetailSample> samples,
}) =>
    _buildSharePayload(entry, vehicle, samples);

String _buildSharePayload(
  TripHistoryEntry entry,
  VehicleProfile? vehicle,
  List<TripDetailSample> samples,
) {
  final s = entry.summary;
  final summary = <String, dynamic>{
    'id': entry.id,
    if (vehicle != null) 'vehicle': vehicle.name,
    if (entry.vehicleId != null) 'vehicleId': entry.vehicleId,
    if (s.startedAt != null) 'startedAt': s.startedAt!.toIso8601String(),
    if (s.endedAt != null) 'endedAt': s.endedAt!.toIso8601String(),
    'distanceKm': s.distanceKm,
    'distanceSource': s.distanceSource,
    if (s.avgLPer100Km != null) 'avgLPer100Km': s.avgLPer100Km,
    if (s.fuelLitersConsumed != null)
      'fuelLitersConsumed': s.fuelLitersConsumed,
    'maxRpm': s.maxRpm,
    'highRpmSeconds': s.highRpmSeconds,
    'idleSeconds': s.idleSeconds,
    'harshBrakes': s.harshBrakes,
    'harshAccelerations': s.harshAccelerations,
    'sampleCount': samples.length,
  };
  const encoder = JsonEncoder.withIndent('  ');
  final csvBuffer = StringBuffer()
    ..writeln('timestamp,speedKmh,rpm,fuelRateLPerHour');
  for (final sample in samples) {
    csvBuffer
      ..write(sample.timestamp.toIso8601String())
      ..write(',')
      ..write(sample.speedKmh.toStringAsFixed(2))
      ..write(',')
      ..write(sample.rpm?.toStringAsFixed(0) ?? '')
      ..write(',')
      ..writeln(sample.fuelRateLPerHour?.toStringAsFixed(3) ?? '');
  }
  return '${encoder.convert(summary)}\n\n${csvBuffer.toString()}';
}

class _TripDetailBody extends StatelessWidget {
  final TripHistoryEntry entry;
  final VehicleProfile? vehicle;
  final List<TripDetailSample> samples;
  final bool isEv;

  const _TripDetailBody({
    required this.entry,
    required this.vehicle,
    required this.samples,
    required this.isEv,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // RPM section is hidden when every sample reports null (the car's
    // PID cache flagged RPM as unsupported). The summary card still
    // shows max-RPM for the trip because that's part of the stored
    // summary regardless of per-sample availability.
    final hasRpmSamples = samples.any((s) => s.rpm != null);

    // Use SingleChildScrollView + Column (not ListView) so every
    // section stays in the widget tree — simplifies widget tests that
    // assert on the presence / absence of the RPM chart below the
    // fold, and keeps the screen compatible with `scrollUntilVisible`
    // when the profile is long enough to require actual scrolling.
    return SingleChildScrollView(
      key: const Key('trip_detail_scroll'),
      padding: EdgeInsets.only(
        top: 8,
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TripSummaryCard(
            entry: entry,
            vehicle: vehicle,
            samples: samples,
            isEv: isEv,
          ),
          const SizedBox(height: 8),
          _ChartSection(
            title: l?.trajetDetailChartSpeed ?? 'Speed (km/h)',
            chart: TripDetailSpeedChart(samples: samples),
          ),
          _ChartSection(
            title: l?.trajetDetailChartFuelRate ?? 'Fuel rate (L/h)',
            chart: TripDetailFuelRateChart(samples: samples),
          ),
          if (hasRpmSamples)
            _ChartSection(
              title: l?.trajetDetailChartRpm ?? 'RPM',
              chart: TripDetailRpmChart(samples: samples),
            ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final Widget chart;

  const _ChartSection({required this.title, required this.chart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          chart,
        ],
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  final TripHistoryEntry entry;
  final VehicleProfile? vehicle;
  final List<TripDetailSample> samples;
  final bool isEv;

  const _TripSummaryCard({
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
    final duration =
        s.startedAt != null && s.endedAt != null && s.endedAt!.isAfter(s.startedAt!)
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
