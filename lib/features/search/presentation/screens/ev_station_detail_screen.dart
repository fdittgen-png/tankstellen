import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/widgets/star_rating.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consumption/presentation/screens/add_charging_log_screen.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../domain/entities/charging_station.dart';
import '../../domain/entities/fuel_type.dart';
import '../../providers/ev_charging_service_provider.dart';
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
      final service = ref.read(evChargingServiceProvider);
      if (service == null) {
        if (mounted) {
          setState(() => _isRefreshing = false);
        }
        return;
      }
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
        SnackBarHelper.showSuccess(context, l10n?.evStatusUpdated ?? 'Status updated');
      } else if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarHelper.showError(context, l10n?.evStationNotFound ?? 'Could not refresh — station not found nearby');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, AppLocalizations.of(context)?.refreshFailed ?? 'Refresh failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _navigateToStation() {
    NavigationUtils.openInMaps(_station.lat, _station.lng,
        label: _station.name);
  }

  /// Open the add-charging-log form pre-filled with this station
  /// (#582 phase 3). The form itself auto-selects the active vehicle;
  /// we supply the station id + display name so the log attributes
  /// back to the charger the user is standing at.
  Future<void> _logCharging() async {
    final displayName = _station.name.trim().isNotEmpty
        ? _station.name
        : _station.operator;
    await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (_) => AddChargingLogScreen(
          chargingStationId: _station.id,
          stationName: displayName,
        ),
      ),
    );
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
              onPressed: () async {
                // Await the toggle so the snackbar fires AFTER persistence
                // and the isFavoriteProvider has flipped. Otherwise a quick
                // back-navigation can cancel the in-flight Hive write and
                // leave the favorite half-persisted (#566).
                await ref.read(favoritesProvider.notifier).toggle(
                      station.id,
                      rawJson: station.toJson(),
                    );
                if (!context.mounted) return;
                // Temporary diagnostic: surface live storage counts in the
                // snackbar so a user on an APK without logcat can verify
                // the favorite actually persisted.
                final storage = ref.read(storageRepositoryProvider);
                final evIds = storage.getEvFavoriteIds();
                final savedCount = evIds
                    .where((id) => storage.getEvFavoriteStationData(id) != null)
                    .length;
                final base = isFav
                    ? (l10n?.removedFromFavorites ?? 'Removed from favorites')
                    : (l10n?.addedToFavorites ?? 'Added to favorites');
                SnackBarHelper.show(
                  context,
                  '$base (EV: ${evIds.length} ids / $savedCount saved)',
                  duration: const Duration(seconds: 3),
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
                  Text(l10n?.yourRating ?? 'Your rating',
                      style: theme.textTheme.titleMedium),
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

          // Log-charging button — primary wheel-lens action (#582 phase 3).
          FilledButton.icon(
            key: const Key('ev_log_charging_button'),
            onPressed: _logCharging,
            icon: const Icon(Icons.ev_station),
            label: Text(l10n?.chargingLogButtonLabel ?? 'Log charging'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: evColor,
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
              backgroundColor: evColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
