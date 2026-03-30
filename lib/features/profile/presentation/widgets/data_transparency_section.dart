import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

enum DataSensitivity { low, medium }

class DataTransparencySection extends StatelessWidget {
  const DataTransparencySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.whatIsShared ?? 'What is shared?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _DataFlowTile(
              icon: Icons.location_on,
              dataType: l?.gpsCoordinates ?? "GPS",
              recipient: 'API',
              reason: l?.gpsReason ?? "",
              sensitivity: DataSensitivity.medium,
            ),
            const Divider(),
            _DataFlowTile(
              icon: Icons.pin_drop,
              dataType: l?.postalCodeData ?? "Postal code",
              recipient: 'Nominatim (OSM)',
              reason: l?.postalReason ?? "",
              sensitivity: DataSensitivity.low,
            ),
            const Divider(),
            _DataFlowTile(
              icon: Icons.map,
              dataType: l?.mapViewport ?? "Map",
              recipient: 'OpenStreetMap',
              reason: l?.mapReason ?? "",
              sensitivity: DataSensitivity.low,
            ),
            const Divider(),
            _DataFlowTile(
              icon: Icons.key,
              dataType: l?.apiKeyData ?? 'API Key',
              recipient: 'API',
              reason: l?.apiKeyReason ?? "",
              sensitivity: DataSensitivity.medium,
            ),
            const Divider(),
            _NotSharedTile(
              items: [
                l?.searchHistory ?? 'Search history',
                l?.favoritesData ?? 'Favorites',
                l?.profileNames ?? 'Profile names',
                l?.homeZipData ?? 'Home ZIP',
                l?.usageData ?? 'Usage data',
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l?.privacyBanner ?? "No server. All data on device.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataFlowTile extends StatelessWidget {
  final IconData icon;
  final String dataType;
  final String recipient;
  final String reason;
  final DataSensitivity sensitivity;

  const _DataFlowTile({
    required this.icon,
    required this.dataType,
    required this.recipient,
    required this.reason,
    required this.sensitivity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = sensitivity == DataSensitivity.medium
        ? Colors.orange
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dataType,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 14, color: color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        recipient,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotSharedTile extends StatelessWidget {
  final List<String> items;

  const _NotSharedTile({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, size: 20, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.notShared ?? 'NOT shared:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map((item) => Chip(
                      label:
                          Text(item, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Colors.green.shade200),
                      backgroundColor: Colors.green.shade50,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
