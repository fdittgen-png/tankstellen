import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../favorites/providers/ev_favorites_provider.dart';
import '../../../search/providers/station_rating_provider.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;
import '../../domain/entities/charging_station.dart';

/// Detail view for a single [ChargingStation] with favorite toggle.
///
/// Shows all connectors, status badges, operator/address metadata, and
/// the last-update timestamp.
class EvStationDetailScreen extends ConsumerWidget {
  final ChargingStation station;

  const EvStationDetailScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isFav = ref.watch(isEvFavoriteProvider(station.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : null,
            ),
            tooltip: isFav
                ? (l10n?.removeFavorite ?? 'Remove from favorites')
                : (l10n?.addFavorite ?? 'Add to favorites'),
            onPressed: () {
              ref
                  .read(evFavoritesProvider.notifier)
                  .toggle(station.id, stationData: station);
              final msg = isFav
                  ? (l10n?.removedFromFavorites ?? 'Removed from favorites')
                  : (l10n?.addedToFavorites ?? 'Added to favorites');
              SnackBarHelper.show(context, msg);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (station.operator != null)
            _row(
              icon: Icons.business,
              label: l10n?.evOperator ?? 'Operator',
              value: station.operator!,
            ),
          if (station.address != null)
            _row(
              icon: Icons.location_on_outlined,
              label: l10n?.address ?? 'Address',
              value: station.address!,
            ),
          _row(
            icon: Icons.bolt,
            label: l10n?.evMaxPower ?? 'Max power',
            value: '${station.maxPowerKw.round()} kW',
          ),
          if (station.lastUpdate != null)
            _row(
              icon: Icons.update,
              label: l10n?.evLastUpdate ?? 'Last update',
              value: station.lastUpdate!.toLocal().toString(),
            ),
          const SizedBox(height: 16),
          Text(
            l10n?.evConnectors(station.connectors.length) ?? 'Connectors',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (station.connectors.isEmpty)
            Text(l10n?.evNoConnectors ?? 'No connector details available'),
          ...station.connectors.map((c) => _ConnectorTile(connector: c)),
          const SizedBox(height: 16),
          // Rating stars
          _RatingRow(stationId: station.id),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectorTile extends StatelessWidget {
  final EvConnector connector;
  const _ConnectorTile({required this.connector});

  static String _labelForType(BuildContext context, ConnectorType type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case ConnectorType.type2:
        return l10n?.connectorType2 ?? 'Type 2';
      case ConnectorType.ccs:
        return l10n?.connectorCcs ?? 'CCS';
      case ConnectorType.chademo:
        return l10n?.connectorChademo ?? 'CHAdeMO';
      case ConnectorType.tesla:
        return l10n?.connectorTesla ?? 'Tesla';
      case ConnectorType.schuko:
        return l10n?.connectorSchuko ?? 'Schuko';
      case ConnectorType.type1:
        return l10n?.connectorType1 ?? 'Type 1';
      case ConnectorType.threePin:
        return l10n?.connectorThreePin ?? '3-pin';
    }
  }

  static (String, Color) _statusBadge(
    BuildContext context,
    ConnectorStatus status,
  ) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case ConnectorStatus.available:
        return (l10n?.evStatusAvailable ?? 'Available', Colors.green);
      case ConnectorStatus.occupied:
        return (l10n?.evStatusOccupied ?? 'Occupied', Colors.orange);
      case ConnectorStatus.outOfOrder:
        return (l10n?.evStatusOutOfOrder ?? 'Out of order', Colors.red);
      case ConnectorStatus.unknown:
        return (l10n?.evStatusUnknown ?? 'Unknown', Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, color) = _statusBadge(context, connector.status);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.power),
        title: Text(_labelForType(context, connector.type)),
        subtitle: Text('${connector.maxPowerKw.round()} kW'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends ConsumerWidget {
  final String stationId;
  const _RatingRow({required this.stationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(stationRatingProvider(stationId));
    final theme = Theme.of(context);

    return Row(
      children: [
        Text('Rating', style: theme.textTheme.titleSmall),
        const Spacer(),
        ...List.generate(5, (i) {
          final starIndex = i + 1;
          return GestureDetector(
            onTap: () =>
                ref.read(stationRatingsProvider.notifier).rate(stationId, starIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                (rating != null && starIndex <= rating)
                    ? Icons.star
                    : Icons.star_border,
                size: 28,
                color: (rating != null && starIndex <= rating)
                    ? Colors.amber
                    : Colors.grey.shade400,
              ),
            ),
          );
        }),
      ],
    );
  }
}
