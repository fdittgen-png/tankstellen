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
    final titleText = hasBrand ? station.brand : station.street;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // #595 — Hero flight from the card's brand/name to the detail app
        // bar title. Text needs Material ancestry mid-flight so wrap in a
        // transparent Material to avoid "Text requires Material" warnings.
        Hero(
          tag: 'station-name-${station.id}',
          flightShuttleBuilder: (ctx, animation, direction, fromCtx, toCtx) {
            return Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ) ??
                    const TextStyle(fontWeight: FontWeight.bold),
                child: Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
          child: Material(
            type: MaterialType.transparency,
            child: Text(
              titleText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 2),
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
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                PriceFormatter.formatDistance(station.dist),
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (station.updatedAt != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.update,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  station.updatedAt!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
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
