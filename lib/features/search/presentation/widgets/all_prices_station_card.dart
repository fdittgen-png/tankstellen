import 'package:flutter/material.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';

/// A detailed station card that shows ALL available fuel prices.
///
/// Designed for the all-prices list view, similar to Essence&Co.
/// Shows station name, address, distance, status, and color-coded
/// badges for every available fuel type with prices.
class AllPricesStationCard extends StatelessWidget {
  final Station station;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final Map<FuelType, bool> cheapestFlags;

  /// The user's preferred fuel type from their profile.
  /// When provided, the matching fuel badge is rendered larger and with a
  /// thicker border to make it visually dominant.
  final FuelType? profileFuelType;

  const AllPricesStationCard({
    super.key,
    required this.station,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.cheapestFlags = const {},
    this.profileFuelType,
  });

  bool get _hasBrand =>
      station.brand.isNotEmpty &&
      station.brand != 'Station' &&
      station.brand != 'Autoroute';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: status dot + name + distance + favorite
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: station.isOpen ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Station name
                  Expanded(
                    child: Text(
                      _hasBrand ? station.brand : station.street,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: station.isOpen
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      station.isOpen
                          ? (l10n?.open ?? 'Open')
                          : (l10n?.closed ?? 'Closed'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: station.isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Favorite button
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
                      onPressed: onFavoriteTap,
                      tooltip: isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Address + distance row
              Row(
                children: [
                  const SizedBox(width: 18), // Align with name
                  Expanded(
                    child: Text(
                      _hasBrand
                          ? '${station.street}, ${station.postCode} ${station.place}'
                          : '${station.postCode} ${station.place}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    PriceFormatter.formatDistance(station.dist),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Fuel price badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _buildFuelBadges(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFuelBadges(BuildContext context) {
    final badges = <Widget>[];

    final fuelEntries = <(FuelType, double?, String)>[
      (FuelType.e5, station.e5, 'E5'),
      (FuelType.e10, station.e10, 'E10'),
      (FuelType.e98, station.e98, 'E98'),
      (FuelType.diesel, station.diesel, 'Diesel'),
      (FuelType.dieselPremium, station.dieselPremium, 'Diesel+'),
      (FuelType.e85, station.e85, 'E85'),
      (FuelType.lpg, station.lpg, 'GPL'),
      (FuelType.cng, station.cng, 'GNV'),
    ];

    for (final (fuelType, price, label) in fuelEntries) {
      // Only show fuels that are available or explicitly listed as unavailable
      final isUnavailable = station.unavailableFuels.contains(
          fuelType.apiValue);
      if (price == null && !isUnavailable) continue;

      badges.add(_FuelBadge(
        label: label,
        price: price,
        fuelType: fuelType,
        isUnavailable: isUnavailable,
        isCheapest: cheapestFlags[fuelType] ?? false,
        isProfileFuel: profileFuelType != null &&
            profileFuelType!.apiValue == fuelType.apiValue,
      ));
    }

    return badges;
  }
}

class _FuelBadge extends StatelessWidget {
  final String label;
  final double? price;
  final FuelType fuelType;
  final bool isUnavailable;
  final bool isCheapest;

  /// When true, this badge is the user's preferred fuel type and should be
  /// rendered larger with a thicker border to stand out.
  final bool isProfileFuel;

  const _FuelBadge({
    required this.label,
    required this.price,
    required this.fuelType,
    this.isUnavailable = false,
    this.isCheapest = false,
    this.isProfileFuel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = FuelColors.forType(fuelType);

    final isHighlighted = isProfileFuel && !isUnavailable;
    final isChampion = isCheapest && !isUnavailable;

    final borderColor = isChampion ? color : color;
    final bgColor = isChampion
        ? color
        : isHighlighted
            ? FuelColors.forType(fuelType).withValues(alpha: 0.22)
            : FuelColors.forTypeLight(fuelType);

    final borderWidth = isChampion ? 1.5 : (isHighlighted ? 1.5 : 0.5);
    final labelFontSize = isHighlighted ? 11.0 : 10.0;
    final priceFontSize = isHighlighted ? 13.0 : 11.0;
    final dotSize = isHighlighted ? 8.0 : 6.0;
    final verticalPadding = isHighlighted ? 5.0 : 4.0;
    final horizontalPadding = isHighlighted ? 10.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: isUnavailable
            ? theme.colorScheme.surfaceContainerHighest
            : bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnavailable
              ? theme.colorScheme.outlineVariant
              : borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnavailable
                  ? theme.colorScheme.onSurfaceVariant
                  : isChampion
                      ? Colors.white
                      : color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: isHighlighted || isChampion
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: isUnavailable
                  ? theme.colorScheme.onSurfaceVariant
                  : isChampion
                      ? Colors.white
                      : color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isUnavailable
                ? (l10n?.outOfStock ?? 'Out of stock')
                : PriceFormatter.formatPriceCompact(price),
            style: TextStyle(
              fontSize: priceFontSize,
              fontWeight: FontWeight.bold,
              color: isUnavailable
                  ? theme.colorScheme.onSurfaceVariant
                  : isChampion
                      ? Colors.white
                      : isHighlighted
                          ? color
                          : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
