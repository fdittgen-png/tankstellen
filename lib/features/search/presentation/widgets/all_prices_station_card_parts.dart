// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'all_prices_station_card.dart';

/// The card's identity row — status dot, brand/street title, tri-state
/// open badge and the favourite toggle (#3933 keeps it byte-for-byte the
/// same chrome the chip version had; only the price area became a table).
///
/// Library-private (`part of`) so the public API of the card stays
/// unchanged.
class _AllPricesCardHeader extends StatelessWidget {
  final Station station;
  final String title;
  final Color statusColor;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const _AllPricesCardHeader({
    required this.station,
    required this.title,
    required this.statusColor,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        // #3198 tri-state: unknown renders the neutral muted dot, never
        // the red "closed" one.
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: AppRadius.md,
          ),
          child: Text(
            switch (station.isOpen) {
              true => l10n.open,
              false => l10n.closed,
              null => l10n.openStateUnknown,
            },
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : null,
            ),
            // #2974 — selection tick on the favourite toggle (the same
            // everyday tap haptic as the compact card). selectionClick
            // only; fires only on the discrete star tap, never scroll.
            onPressed: onFavoriteTap == null
                ? null
                : () {
                    unawaited(HapticFeedback.selectionClick());
                    onFavoriteTap!();
                  },
            tooltip: isFavorite ? (l10n.removeFavorite) : (l10n.addFavorite),
          ),
        ),
      ],
    );
  }
}

/// Address + distance line, indented to sit under the card title.
class _AllPricesCardAddress extends StatelessWidget {
  final String address;
  final double? distanceKm;

  const _AllPricesCardAddress({
    required this.address,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(width: 18), // Align with the title.
        Expanded(
          child: Text(
            address,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          PriceFormatter.formatDistance(distanceKm),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
