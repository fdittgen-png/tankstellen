import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../providers/privacy_data_provider.dart';
import '../storage_bar.dart';
import 'privacy_data_row.dart';

/// Card listing every category of data the app keeps on the device.
class LocalDataCard extends StatelessWidget {
  final PrivacyDataSnapshot snapshot;

  const LocalDataCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l?.privacyLocalData ?? 'Data on this device',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrivacyDataRow(
              icon: Icons.favorite,
              label: l?.favorites ?? 'Favorites',
              value: '${snapshot.favoritesCount}',
            ),
            PrivacyDataRow(
              icon: Icons.visibility_off,
              label: l?.privacyIgnoredStations ?? 'Ignored stations',
              value: '${snapshot.ignoredCount}',
            ),
            PrivacyDataRow(
              icon: Icons.star,
              label: l?.privacyRatings ?? 'Station ratings',
              value: '${snapshot.ratingsCount}',
            ),
            PrivacyDataRow(
              icon: Icons.notifications,
              label: l?.priceAlerts ?? 'Price alerts',
              value: '${snapshot.alertsCount}',
            ),
            PrivacyDataRow(
              icon: Icons.show_chart,
              label: l?.privacyPriceHistory ?? 'Price history stations',
              value: '${snapshot.priceHistoryStationCount}',
            ),
            PrivacyDataRow(
              icon: Icons.person,
              label: l?.privacyProfiles ?? 'Search profiles',
              value: '${snapshot.profileCount}',
            ),
            PrivacyDataRow(
              icon: Icons.route,
              label: l?.privacyItineraries ?? 'Saved routes',
              value: '${snapshot.itineraryCount}',
            ),
            PrivacyDataRow(
              icon: Icons.cached,
              label: l?.privacyCacheEntries ?? 'Cache entries',
              value: '${snapshot.cacheEntryCount}',
            ),
            PrivacyDataRow(
              icon: Icons.key,
              label: l?.privacyApiKey ?? 'API key stored',
              value:
                  snapshot.hasApiKey ? (l?.yes ?? 'Yes') : (l?.no ?? 'No'),
            ),
            PrivacyDataRow(
              icon: Icons.ev_station,
              label: l?.privacyEvApiKey ?? 'EV API key stored',
              value:
                  snapshot.hasEvApiKey ? (l?.yes ?? 'Yes') : (l?.no ?? 'No'),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l?.privacyEstimatedSize ?? 'Estimated storage',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatBytes(snapshot.estimatedTotalBytes),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
