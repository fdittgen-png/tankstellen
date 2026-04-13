import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../providers/price_history_provider.dart';
import '../widgets/price_chart.dart';
import '../widgets/price_stats_card.dart';

/// Full-screen price history view for a station.
///
/// Shows a chart and stats for each available fuel type.
class PriceHistoryScreen extends ConsumerWidget {
  final String stationId;

  const PriceHistoryScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(priceHistoryProvider(stationId));

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.priceHistory ?? 'Price History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: history.isEmpty
          ? Center(child: Text(l10n?.noPriceHistory ?? 'No price history yet'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final fuelType in _availableFuelTypes)
                  _FuelTypeSection(
                    stationId: stationId,
                    fuelType: fuelType,
                    records: history,
                  ),
              ],
            ),
    );
  }

  /// Fuel types to display (excludes 'all' and 'hydrogen').
  static const _availableFuelTypes = [
    FuelType.e5,
    FuelType.e10,
    FuelType.diesel,
    FuelType.e98,
    FuelType.e85,
    FuelType.lpg,
    FuelType.cng,
  ];
}

class _FuelTypeSection extends ConsumerWidget {
  final String stationId;
  final FuelType fuelType;
  final List records;

  const _FuelTypeSection({
    required this.stationId,
    required this.fuelType,
    required this.records,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(priceStatsProvider(stationId, fuelType));

    // Skip fuel types with no data
    if (stats.current == null && stats.min == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fuelType.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            PriceChart(records: List.from(records), fuelType: fuelType),
            const SizedBox(height: 8),
            PriceStatsCard(stats: stats),
          ],
        ),
      ),
    );
  }
}
