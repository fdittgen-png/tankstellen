import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/data/models/price_alert.dart';
import '../../../alerts/presentation/widgets/create_alert_dialog.dart';
import '../../../alerts/providers/alert_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../search/providers/station_rating_provider.dart';
import '../../../../core/widgets/star_rating.dart';
import '../../../price_history/data/models/price_record.dart';
import '../../../price_history/presentation/widgets/price_chart.dart';
import '../../../price_history/presentation/widgets/price_stats_card.dart';
import '../../../price_history/providers/price_history_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import '../../providers/station_detail_provider.dart';

class StationDetailScreen extends ConsumerWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(stationDetailProvider(stationId));
    final isFav = ref.watch(isFavoriteProvider(stationId));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.search ?? 'Station'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showCreateAlertDialog(context, ref),
            tooltip: l10n?.createAlert ?? 'Create price alert',
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => context.push('/report/$stationId'),
            tooltip: l10n?.reportPrice ?? 'Report price',
          ),
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : null,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggle(stationId);
            },
          ),
        ],
      ),
      body: detailAsync.when(
        data: (result) => Column(
          children: [
            ServiceStatusBanner(result: result),
            Expanded(child: _buildContent(context, ref, result.data)),
          ],
        ),
        loading: () => const ShimmerStationDetail(),
        error: (error, _) => ServiceChainErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(stationDetailProvider(stationId)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, StationDetail detail) {
    final station = detail.station;
    final theme = Theme.of(context);

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: station.isOpen ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                station.isOpen
                    ? (AppLocalizations.of(context)?.open ?? 'Open')
                    : (AppLocalizations.of(context)?.closed ?? 'Closed'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: station.isOpen ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name & Brand
          Text(
            station.brand.isNotEmpty && station.brand != 'Station'
                ? station.brand
                : station.street,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (station.brand.isNotEmpty &&
              station.brand != 'Station' &&
              station.brand != station.street)
            Text(station.street, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),

          // Prices
          Text(AppLocalizations.of(context)?.prices ?? 'Prices', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _PriceTile(label: 'Super E5', price: station.e5, fuelType: FuelType.e5),
          _PriceTile(label: 'Super E10', price: station.e10, fuelType: FuelType.e10),
          _PriceTile(label: 'Diesel', price: station.diesel, fuelType: FuelType.diesel),
          if (station.e98 != null)
            _PriceTile(label: 'Super 98', price: station.e98, fuelType: FuelType.e98),
          if (station.e85 != null)
            _PriceTile(label: 'E85', price: station.e85, fuelType: FuelType.e85),
          if (station.lpg != null)
            _PriceTile(label: 'LPG', price: station.lpg, fuelType: FuelType.lpg),
          if (station.cng != null)
            _PriceTile(label: 'CNG', price: station.cng, fuelType: FuelType.cng),
          const SizedBox(height: 24),

          // Address
          Text(AppLocalizations.of(context)?.address ?? 'Address', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(
              '${station.street}${station.houseNumber != null ? ' ${station.houseNumber}' : ''}',
            ),
            subtitle: Text('${station.postCode} ${station.place}'),
            trailing: IconButton(
              icon: const Icon(Icons.directions),
              onPressed: () => _openNavigation(station),
              tooltip: AppLocalizations.of(context)?.navigate ?? 'Navigate',
            ),
          ),
          const SizedBox(height: 24),

          // Opening times — from Station model or StationDetail
          Text(AppLocalizations.of(context)?.openingHours ?? 'Opening hours', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (station.is24h)
            const ListTile(
              leading: Icon(Icons.schedule, color: Colors.green),
              title: Text('24h/24 — Automate'),
            )
          else if (station.openingHoursText != null && station.openingHoursText!.isNotEmpty)
            ...station.openingHoursText!.split('\n').map((line) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.schedule),
                  title: Text(line.trim()),
                ))
          else if (detail.openingTimes.isNotEmpty)
            ...detail.openingTimes.map((ot) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.schedule),
                  title: Text(ot.text),
                  trailing: Text('${ot.start.substring(0, 5)} – ${ot.end.substring(0, 5)}'),
                ))
          else
            const ListTile(
              dense: true,
              leading: Icon(Icons.schedule),
              title: Text('—'),
            ),
          const SizedBox(height: 24),

          // Available fuels
          if (station.availableFuels.isNotEmpty) ...[
            Text(AppLocalizations.of(context)?.fuels ?? 'Fuels', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...station.availableFuels.map((f) => Chip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.green.shade50,
                      side: BorderSide(color: Colors.green.shade200),
                    )),
                ...station.unavailableFuels.map((f) => Chip(
                      label: Text(f, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.grey.shade100,
                    )),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Services
          if (station.services.isNotEmpty) ...[
            Text(AppLocalizations.of(context)?.services ?? 'Services', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: station.services.map((s) => Chip(
                    avatar: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(s, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Location info
          if (station.department != null || station.region != null) ...[
            Text(AppLocalizations.of(context)?.zone ?? 'Zone', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.map),
              title: Text([station.department, station.region]
                  .whereType<String>()
                  .join(', ')),
              subtitle: station.stationType == 'A'
                  ? Text(AppLocalizations.of(context)?.highway ?? 'Highway')
                  : Text(AppLocalizations.of(context)?.localStation ?? 'Local station'),
            ),
          ],

          // Last update
          if (station.updatedAt != null) ...[
            const SizedBox(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.update),
              title: Text('Dernière mise à jour: ${station.updatedAt}'),
            ),
          ],

          // Rating
          const SizedBox(height: 16),
          Text('Your rating', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Consumer(builder: (context, ref, _) {
            final rating = ref.watch(stationRatingProvider(stationId));
            return Row(
              children: [
                StarRating(
                  rating: rating,
                  onRatingChanged: (stars) {
                    ref.read(stationRatingsProvider.notifier).rate(stationId, stars);
                  },
                ),
                if (rating != null) ...[
                  const SizedBox(width: 12),
                  Text('$rating/5', style: theme.textTheme.bodyMedium),
                ],
              ],
            );
          }),

          // Price History Graph — always visible below rating.
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)?.priceHistory ?? 'Price History',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _PriceHistorySection(stationId: stationId, station: station),
        ],
      ),
    );
  }

  Future<void> _showCreateAlertDialog(BuildContext context, WidgetRef ref) async {
    final detailAsync = ref.read(stationDetailProvider(stationId));
    final station = detailAsync.value?.data.station;
    final stationName = station != null
        ? (station.brand.isNotEmpty && station.brand != 'Station'
            ? station.brand
            : station.street)
        : stationId;
    final currentPrice = station?.diesel ?? station?.e10 ?? station?.e5;

    final alert = await showDialog<PriceAlert>(
      context: context,
      builder: (context) => CreateAlertDialog(
        stationId: stationId,
        stationName: stationName,
        currentPrice: currentPrice,
      ),
    );

    if (alert != null && context.mounted) {
      await ref.read(alertProvider.notifier).addAlert(alert);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.alertCreated ?? 'Price alert created')),
        );
      }
    }
  }

  Future<void> _openNavigation(Station station) async {
    await NavigationUtils.openInMaps(
      station.lat, station.lng,
      label: station.displayName,
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String label;
  final double? price;
  final FuelType fuelType;

  const _PriceTile({
    required this.label,
    required this.price,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context) {
    final color = price != null ? FuelColors.forType(fuelType) : Colors.grey;
    return ListTile(
      dense: true,
      leading: Icon(Icons.local_gas_station, color: color),
      title: Text(label),
      trailing: Text(
        PriceFormatter.formatPrice(price),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
      ),
    );
  }
}

/// Price history graph widget that records the current price on init
/// and always shows the chart (even with a single data point).
class _PriceHistorySection extends ConsumerStatefulWidget {
  final String stationId;
  final Station station;

  const _PriceHistorySection({required this.stationId, required this.station});

  @override
  ConsumerState<_PriceHistorySection> createState() => _PriceHistorySectionState();
}

class _PriceHistorySectionState extends ConsumerState<_PriceHistorySection> {
  bool _recorded = false;
  bool _fetchedFromDb = false;

  @override
  void initState() {
    super.initState();
    // Record the current price immediately so the chart always has data.
    // The repository deduplicates within 60 minutes.
    _recordAndLoad();
  }

  Future<void> _recordAndLoad() async {
    final repo = ref.read(priceHistoryRepositoryProvider);
    final station = widget.station;

    // Record current price as a data point
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

    // Invalidate so the provider re-reads with the new record
    ref.invalidate(priceHistoryProvider(widget.stationId));

    if (mounted) setState(() => _recorded = true);

    // Also try loading from DB if local is still sparse
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
    // Only fetch from DB if we have very few local records (< 3)
    if (history.length >= 3) {
      if (mounted) setState(() => _fetchedFromDb = true);
      return;
    }

    try {
      final rows = await SyncService.fetchPriceHistory(widget.stationId);
      if (rows.isNotEmpty && mounted) {
        final storage = ref.read(hiveStorageProvider);
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
        await storage.savePriceRecords(widget.stationId, records);
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

    // Determine best fuel type to display: use the first one with data
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

  /// Pick the best fuel type to show: prefer diesel, then e10, then e5, then first available.
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
