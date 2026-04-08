import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/service_result.dart';
import '../../../../core/services/widgets/freshness_badge.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/data/models/price_alert.dart';
import '../../../alerts/presentation/widgets/create_alert_dialog.dart';
import '../../../alerts/providers/alert_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/station.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../providers/station_detail_provider.dart';
import '../widgets/price_history_section.dart';
import '../widgets/price_tile.dart';
import '../widgets/station_info_section.dart';
import '../widgets/station_rating_section.dart';

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
        title: Semantics(
          header: true,
          child: Text(AppLocalizations.of(context)?.search ?? 'Station'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: () {
              final station = detailAsync.value?.data.station;
              if (station != null) {
                NavigationUtils.openInMaps(station.lat, station.lng,
                    label: station.brand.isNotEmpty ? station.brand : station.street);
              }
            },
            tooltip: l10n?.navigate ?? 'Navigate',
          ),
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
              final station = detailAsync.value?.data.station;
              ref.read(favoritesProvider.notifier).toggle(stationId, stationData: station);
            },
            tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: detailAsync.when(
        data: (result) => Column(
          children: [
            ServiceStatusBanner(result: result),
            Expanded(child: _buildContent(context, ref, result.data, result)),
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

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    StationDetail detail,
    ServiceResult<StationDetail> serviceResult,
  ) {
    final station = detail.station;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Open/closed status + freshness badge
          Semantics(
            label: 'Station is ${station.isOpen ? 'open' : 'closed'}',
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: station.isOpen
                          ? DarkModeColors.success(context)
                          : DarkModeColors.error(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: Text(
                    station.isOpen
                        ? (l10n?.open ?? 'Open')
                        : (l10n?.closed ?? 'Closed'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: station.isOpen
                          ? DarkModeColors.success(context)
                          : DarkModeColors.error(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                FreshnessBadge(result: serviceResult),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Brand logo + Name
          Semantics(
            label: '${station.brand.isNotEmpty && station.brand != 'Station' ? station.brand : station.street}'
                '${station.brand.isNotEmpty && station.brand != 'Station' && station.brand != station.street ? ', ${station.street}' : ''}',
            header: true,
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BrandLogo(brand: station.brand, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Prices
          Semantics(
            header: true,
            child: Text(l10n?.prices ?? 'Prices', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          PriceTile(label: 'Super E5', price: station.e5, fuelType: FuelType.e5),
          PriceTile(label: 'Super E10', price: station.e10, fuelType: FuelType.e10),
          PriceTile(label: 'Diesel', price: station.diesel, fuelType: FuelType.diesel),
          if (station.e98 != null) PriceTile(label: 'Super 98', price: station.e98, fuelType: FuelType.e98),
          if (station.e85 != null) PriceTile(label: 'E85', price: station.e85, fuelType: FuelType.e85),
          if (station.lpg != null) PriceTile(label: 'LPG', price: station.lpg, fuelType: FuelType.lpg),
          if (station.cng != null) PriceTile(label: 'CNG', price: station.cng, fuelType: FuelType.cng),
          const SizedBox(height: 24),

          // Address, opening hours, fuels, services, location
          StationInfoSection(station: station, detail: detail),

          // Rating
          const SizedBox(height: 16),
          StationRatingSection(stationId: stationId),

          // Price History
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(l10n?.priceHistory ?? 'Price History', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          PriceHistorySection(stationId: stationId, station: station),
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
        SnackBarHelper.showSuccess(context, l10n?.alertCreated ?? 'Price alert created');
      }
    }
  }
}
