import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../price_history/domain/entities/price_record.dart';
import '../../../price_history/presentation/widgets/price_chart.dart';
import '../../../price_history/presentation/widgets/price_stats_card.dart';
import '../../../price_history/providers/price_history_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';

/// Price history graph widget that records the current price on init
/// and always shows the chart (even with a single data point).
class PriceHistorySection extends ConsumerStatefulWidget {
  final String stationId;
  final Station station;

  const PriceHistorySection({super.key, required this.stationId, required this.station});

  @override
  ConsumerState<PriceHistorySection> createState() => _PriceHistorySectionState();
}

class _PriceHistorySectionState extends ConsumerState<PriceHistorySection> {
  bool _recorded = false;
  bool _fetchedFromDb = false;

  @override
  void initState() {
    super.initState();
    _recordAndLoad();
  }

  Future<void> _recordAndLoad() async {
    final repo = ref.read(priceHistoryRepositoryProvider);
    final station = widget.station;

    await repo.recordPrice(PriceRecord(
      stationId: widget.stationId,
      recordedAt: DateTime.now(),
      e5: station.e5,
      e10: station.e10,
      e98: station.e98,
      diesel: station.diesel,
      e85: station.e85,
      lpg: station.lpg,
      cng: station.cng,
    ));

    ref.invalidate(priceHistoryProvider(widget.stationId));
    if (mounted) setState(() => _recorded = true);
    await _fetchFromDatabaseIfNeeded();
  }

  Future<void> _fetchFromDatabaseIfNeeded() async {
    if (_fetchedFromDb) return;
    final syncState = ref.read(syncStateProvider);
    if (!syncState.enabled) {
      if (mounted) setState(() => _fetchedFromDb = true);
      return;
    }

    final history = ref.read(priceHistoryProvider(widget.stationId));
    if (history.length >= 3) {
      if (mounted) setState(() => _fetchedFromDb = true);
      return;
    }

    try {
      final rows = await SyncService.fetchPriceHistory(widget.stationId);
      if (rows.isNotEmpty && mounted) {
        final storageMgmt = ref.read(storageManagementProvider);
        final records = rows.map((r) => {
          'stationId': r['station_id'],
          'recordedAt': r['recorded_at'],
          'e5': r['e5'],
          'e10': r['e10'],
          'diesel': r['diesel'],
          'e98': r['e98'],
          'e85': r['e85'],
          'lpg': r['lpg'],
          'cng': r['cng'],
        }).toList();
        await storageMgmt.savePriceRecords(widget.stationId, records);
        ref.invalidate(priceHistoryProvider(widget.stationId));
      }
    } catch (e) {
      debugPrint('PriceHistory DB fetch failed: $e');
    }
    if (mounted) setState(() => _fetchedFromDb = true);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(priceHistoryProvider(widget.stationId));

    if (!_recorded && history.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final defaultFuel = _pickFuelType(history);
    final stats = ref.watch(priceStatsProvider(widget.stationId, defaultFuel));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceChart(records: history, fuelType: defaultFuel),
        const SizedBox(height: 8),
        if (stats.current != null) PriceStatsCard(stats: stats),
        if (stats.current != null) const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => GoRouter.of(context).push('/station/${widget.stationId}/history'),
            child: const Text('Show all fuel types'),
          ),
        ),
      ],
    );
  }

  FuelType _pickFuelType(List<PriceRecord> history) {
    if (history.isEmpty) return FuelType.diesel;
    final first = history.first;
    if (first.diesel != null) return FuelType.diesel;
    if (first.e10 != null) return FuelType.e10;
    if (first.e5 != null) return FuelType.e5;
    if (first.e98 != null) return FuelType.e98;
    if (first.e85 != null) return FuelType.e85;
    if (first.lpg != null) return FuelType.lpg;
    if (first.cng != null) return FuelType.cng;
    return FuelType.diesel;
  }
}
