import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/charging_station.dart';

/// Compact card for an EV charging station in the favorites list.
///
/// Uses the canonical `search/` [ChargingStation] type with [Connector]
/// (simple String fields) rather than the richer `ev/` type.
class EvFavoriteCard extends StatelessWidget {
  final ChargingStation station;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const EvFavoriteCard({
    super.key,
    required this.station,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final connectors = station.connectors;
    final available = connectors
        .where((c) => c.status?.toLowerCase().contains('available') == true)
        .length;
    final total = connectors.length;
    final maxPower = connectors.isEmpty
        ? 0.0
        : connectors.map((c) => c.powerKW).reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.ev_station, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (station.operator.isNotEmpty)
                      Text(
                        station.operator,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.bolt, size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${maxPower.round()} kW',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        if (total > 0) ...[
                          Icon(
                            Icons.power,
                            size: 14,
                            color: available > 0 ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$available/$total ${l10n?.evStatusAvailable ?? 'available'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: available > 0 ? Colors.green : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (connectors.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: connectors
                              .map((c) => c.type)
                              .toSet()
                              .map((type) => Chip(
                                    label: Text(type,
                                        style: const TextStyle(fontSize: 10)),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.star, color: Colors.amber, size: 22),
                  onPressed: onFavoriteTap,
                  tooltip: l10n?.removeFavorite ?? 'Remove from favorites',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
