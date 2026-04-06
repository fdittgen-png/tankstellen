import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/widgets/star_rating.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../data/services/ev_charging_service.dart';
import '../../domain/entities/charging_station.dart';
import '../../domain/entities/fuel_type.dart';
import '../../providers/station_rating_provider.dart';
import '../widgets/ev_station_header_card.dart';
import '../widgets/ev_station_info_cards.dart';

/// Detail screen for an EV charging station.
class EVStationDetailScreen extends ConsumerStatefulWidget {
  final ChargingStation station;

  const EVStationDetailScreen({super.key, required this.station});

  @override
  ConsumerState<EVStationDetailScreen> createState() => _EVStationDetailScreenState();
}

class _EVStationDetailScreenState extends ConsumerState<EVStationDetailScreen> {
  late ChargingStation _station;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _station = widget.station;
  }

  Future<void> _refreshStation() async {
    setState(() => _isRefreshing = true);
    try {
      final apiKeys = ref.read(apiKeyStorageProvider);
      final apiKey = apiKeys.getEvApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          setState(() => _isRefreshing = false);
        }
        return;
      }
      final service = EVChargingService(apiKey: apiKey);
      final result = await service.searchStations(
        lat: _station.lat,
        lng: _station.lng,
        radiusKm: 0.5,
        maxResults: 10,
      );
      final ocmId = _station.id.replaceFirst('ocm-', '');
      final refreshed = result.data.where((s) => s.id == _station.id || s.id == 'ocm-$ocmId').firstOrNull;
      if (refreshed != null && mounted) {
        setState(() => _station = refreshed);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.evStatusUpdated ?? 'Status updated'), duration: const Duration(seconds: 2)),
        );
      } else if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.evStationNotFound ?? 'Could not refresh — station not found nearby')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.refreshFailed ?? 'Refresh failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _navigateToStation() {
    NavigationUtils.openInMaps(_station.lat, _station.lng,
        label: _station.name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final evColor = FuelColors.forType(FuelType.electric);
    final station = _station;

    return Scaffold(
      appBar: AppBar(
        title: Text(station.operator.isNotEmpty ? station.operator : station.name),
        actions: [
          Consumer(builder: (context, ref, _) {
            final isFav = ref.watch(isFavoriteProvider(station.id));
            return IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_outline,
                color: isFav ? Colors.amber : Colors.white70,
                size: 26,
              ),
              tooltip: isFav ? (l10n?.removeFavorite ?? 'Remove from favorites') : (l10n?.addFavorite ?? 'Add to favorites'),
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggle(station.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFav ? (l10n?.removedFromFavorites ?? 'Removed from favorites') : (l10n?.addedToFavorites ?? 'Added to favorites')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          }),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                : const Icon(Icons.refresh),
            tooltip: l10n?.evRefreshStatus ?? 'Refresh status',
            onPressed: _isRefreshing ? null : _refreshStation,
          ),
          IconButton(
            icon: const Icon(Icons.navigation),
            tooltip: l10n?.navigate ?? 'Navigate',
            onPressed: _navigateToStation,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom + 24),
        children: [
          EVStationHeaderCard(station: station, evColor: evColor),
          const SizedBox(height: 8),
          EVAddressCard(station: station),
          const SizedBox(height: 8),
          EVConnectorsCard(station: station, evColor: evColor),
          const SizedBox(height: 8),
          EVPricingCard(station: station, evColor: evColor),
          const SizedBox(height: 8),
          EVLastUpdatedCard(station: station),
          const SizedBox(height: 8),

          // Rating
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your rating', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Consumer(builder: (context, ref, _) {
                    final rating = ref.watch(stationRatingProvider(station.id));
                    return Row(
                      children: [
                        StarRating(
                          rating: rating,
                          onRatingChanged: (stars) {
                            ref.read(stationRatingsProvider.notifier).rate(station.id, stars);
                          },
                        ),
                        if (rating != null) ...[
                          const SizedBox(width: 12),
                          Text('$rating/5', style: theme.textTheme.bodyMedium),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Navigate button
          FilledButton.icon(
            onPressed: _navigateToStation,
            icon: const Icon(Icons.navigation),
            label: Text(l10n?.evNavigateToStation ?? 'Navigate to station'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: evColor,
            ),
          ),
        ],
      ),
    );
  }
}
