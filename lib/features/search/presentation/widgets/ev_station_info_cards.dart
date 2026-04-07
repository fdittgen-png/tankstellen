import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/charging_station.dart';
import 'ev_connector_tile.dart';

/// Address card for an EV charging station.
class EVAddressCard extends StatelessWidget {
  final ChargingStation station;

  const EVAddressCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
    );
  }
}

/// Connectors card showing all available connectors for an EV station.
class EVConnectorsCard extends StatelessWidget {
  final ChargingStation station;
  final Color evColor;

  const EVConnectorsCard({super.key, required this.station, required this.evColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
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
            ...station.connectors.map((c) => EVConnectorTile(connector: c)),
            if (station.connectors.isEmpty)
              Text(l10n?.evNoConnectors ?? 'No connector details available',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Pricing card for an EV station.
class EVPricingCard extends StatelessWidget {
  final ChargingStation station;
  final Color evColor;

  const EVPricingCard({super.key, required this.station, required this.evColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (station.usageCost != null && station.usageCost!.isNotEmpty) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.payments, color: evColor),
          title: Text(l10n?.evUsageCost ?? 'Usage cost'),
          subtitle: Text(
            station.usageCost!,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: evColor),
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(Icons.payments, color: theme.colorScheme.outline),
        title: Text(l10n?.evUsageCost ?? 'Usage cost'),
        subtitle: Text(
          l10n?.evPricingUnavailable ?? 'Pricing not available from provider',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Last updated card with attribution for an EV station.
class EVLastUpdatedCard extends StatelessWidget {
  final ChargingStation station;

  const EVLastUpdatedCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
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
    );
  }
}
