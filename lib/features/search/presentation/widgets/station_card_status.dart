// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'station_card.dart';

/// Status dot (green/red) with optional 24h badge below it.
class _StatusColumn extends StatelessWidget {
  final Station station;

  const _StatusColumn({required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: station.isOpen
                ? DarkModeColors.success(context)
                : DarkModeColors.error(context),
          ),
        ),
        if (station.is24h)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '24h',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Left-side text block: brand/name title, address line, distance / updated
/// indicator, and amenity chips.
class _StationDetails extends StatelessWidget {
  final Station station;
  final bool hasBrand;

  const _StationDetails({required this.station, required this.hasBrand});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final titleText = hasBrand ? station.brand : station.street;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // #2161 — was a Hero flight to the detail-screen title; the
        // detail screen no longer shows the station name in its AppBar
        // and no longer animates the title, so the source Hero is
        // dropped too. Plain Text only.
        Text(
          titleText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          hasBrand
              ? '${station.street}, ${station.postCode} ${station.place}'
              : '${station.postCode} ${station.place}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.xs),
        Row(
          children: [
            // #2622 — distance gets priority in this cramped row; the
            // timestamp (Flexible) is what wraps/ellipsises first.
            Text(
              PriceFormatter.formatDistance(station.dist),
              style: theme.textTheme.bodySmall,
            ),
            if (station.updatedAt != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.update,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.xs),
              Flexible(
                child: Text(
                  // #2622 — wrap the upstream pre-formatted timestamp as
                  // "Updated {time}" so it reads as freshness, not a bare
                  // code. (No relative "2h ago": updatedAt is a lossy,
                  // per-country pre-formatted String.)
                  l10n?.stationUpdatedLabel(station.updatedAt!) ??
                      'Updated ${station.updatedAt!}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        if (station.amenities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AmenityChips(amenities: station.amenities),
          ),
      ],
    );
  }
}
