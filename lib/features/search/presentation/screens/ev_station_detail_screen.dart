import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../providers/station_rating_provider.dart';
import '../../../../core/widgets/star_rating.dart';
import '../../data/services/ev_charging_service.dart';
import '../../domain/entities/charging_station.dart';
import '../../domain/entities/fuel_type.dart';

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
      final apiKey = apiKeys.getEvApiKey() ?? AppConstants.openChargeMapApiKey;
      final service = EVChargingService(apiKey: apiKey);
      final result = await service.searchStations(
        lat: _station.lat,
        lng: _station.lng,
        radiusKm: 0.5,
        maxResults: 10,
      );
      // Find our station in the results by matching ID
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
          // Favorite toggle
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
          // Refresh status from OpenChargeMap
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                : const Icon(Icons.refresh),
            tooltip: l10n?.evRefreshStatus ?? 'Refresh status',
            onPressed: _isRefreshing ? null : _refreshStation,
          ),
          // Navigate to station
          IconButton(
            icon: const Icon(Icons.navigation),
            tooltip: l10n?.navigate ?? 'Navigate',
            onPressed: () {
              final url = 'https://www.google.com/maps/dir/?api=1'
                  '&destination=${station.lat},${station.lng}'
                  '&travelmode=driving';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom + 24),
        children: [
          // Status + operator header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: station.isOperational == true ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        station.isOperational == true ? (l10n?.evOperational ?? 'Operational') : (l10n?.evStatusUnknown ?? 'Status unknown'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: station.isOperational == true ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.ev_station, color: evColor, size: 28),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    station.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (station.operator.isNotEmpty && station.operator != station.name)
                    Text(station.operator, style: theme.textTheme.titleMedium?.copyWith(color: evColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Address + distance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(station.address, style: theme.textTheme.bodyLarge)),
                    ],
                  ),
                  if (station.postCode.isNotEmpty || station.place.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        '${station.postCode} ${station.place}'.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(PriceFormatter.formatDistance(station.dist), style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Connectors
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.electrical_services, color: evColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.evConnectors(station.totalPoints) ?? 'Connectors (${station.totalPoints} points)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...station.connectors.map((c) => _ConnectorTile(connector: c)),
                  if (station.connectors.isEmpty)
                    Text(l10n?.evNoConnectors ?? 'No connector details available',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Pricing
          if (station.usageCost != null && station.usageCost!.isNotEmpty)
            Card(
              child: ListTile(
                leading: Icon(Icons.payments, color: evColor),
                title: Text(l10n?.evUsageCost ?? 'Usage cost'),
                subtitle: Text(
                  station.usageCost!,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: evColor),
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: Icon(Icons.payments, color: Colors.grey.shade400),
                title: Text(l10n?.evUsageCost ?? 'Usage cost'),
                subtitle: Text(
                  l10n?.evPricingUnavailable ?? 'Pricing not available from provider',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Last updated with provider attribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.update, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n?.evLastUpdated ?? 'Last updated'),
                      const Spacer(),
                      Text(
                        station.updatedAt ?? (l10n?.evUnknown ?? 'Unknown'),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.evDataAttribution ?? 'Data from OpenChargeMap (community-sourced)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.evStatusDisclaimer ?? 'Status may not reflect real-time availability. '
                    'Tap refresh to get the latest data from OpenChargeMap.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
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
            onPressed: () {
              final url = 'https://www.google.com/maps/dir/?api=1'
                  '&destination=${station.lat},${station.lng}'
                  '&travelmode=driving';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
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

class _ConnectorTile extends StatelessWidget {
  final Connector connector;
  const _ConnectorTile({required this.connector});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _connectorColor(connector.type).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              connector.type,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _connectorColor(connector.type)),
            ),
          ),
          const SizedBox(width: 12),
          Text('${connector.powerKW.round()} kW', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (connector.currentType != null)
            Text(connector.currentType!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          if (connector.quantity > 0)
            Text('x${connector.quantity}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (connector.status != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(connector.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(connector.status), size: 12, color: _statusColor(connector.status)),
                  const SizedBox(width: 3),
                  Text(connector.status!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _statusColor(connector.status))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.contains('Available') || status == 'Operational') return Colors.green;
    if (status == 'In Use') return Colors.orange;
    if (status.contains('Unavailable') || status == 'Not Operational') return Colors.red;
    if (status == 'Partly Operational') return Colors.amber;
    return Colors.grey;
  }

  IconData _statusIcon(String? status) {
    if (status == null) return Icons.help_outline;
    if (status.contains('Available') || status == 'Operational') return Icons.check_circle;
    if (status == 'In Use') return Icons.access_time;
    if (status.contains('Unavailable') || status == 'Not Operational') return Icons.cancel;
    if (status == 'Partly Operational') return Icons.warning;
    return Icons.help_outline;
  }

  Color _connectorColor(String type) {
    if (type.contains('CCS')) return const Color(0xFF2196F3);
    if (type.contains('Type 2')) return const Color(0xFF4CAF50);
    if (type.contains('CHAdeMO')) return const Color(0xFFFF9800);
    if (type.contains('Tesla')) return const Color(0xFFE91E63);
    return const Color(0xFF757575);
  }
}
