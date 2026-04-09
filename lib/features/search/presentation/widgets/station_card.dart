import 'package:flutter/material.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';
import 'amenity_chips.dart';

class StationCard extends StatelessWidget {
  final Station station;
  final FuelType selectedFuelType;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool isCheapest;

  /// Optional price tier for accessibility icon indicator.
  /// When provided, a small arrow icon is shown next to the price
  /// so colorblind users can distinguish cheap/average/expensive.
  final PriceTier? priceTier;

  /// Optional user rating (1-5) for this station.
  /// When provided, small star icons are shown above the price area.
  final int? rating;

  /// The user's preferred fuel type from their profile.
  /// When [selectedFuelType] is [FuelType.all], the matching price row
  /// is rendered larger and with the fuel-type color to make it visually
  /// dominant.
  final FuelType? profileFuelType;

  const StationCard({
    super.key,
    required this.station,
    required this.selectedFuelType,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.isCheapest = false,
    this.priceTier,
    this.rating,
    this.profileFuelType,
  });

  /// True if the station has a real brand name (not empty, not generic "Station")
  bool get _hasBrand =>
      station.brand.isNotEmpty &&
      station.brand != 'Station' &&
      station.brand != 'Autoroute';

  double? get _displayPrice => station.priceFor(selectedFuelType);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = _displayPrice;

    final formattedPrice = PriceFormatter.formatPrice(price);
    final semanticStatus = station.isOpen ? 'Open' : 'Closed';
    final semanticLabel =
        '${_hasBrand ? station.brand : station.name}, ${station.street}, '
        '$formattedPrice, $semanticStatus';

    final fuelColor = FuelColors.forType(selectedFuelType);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isCheapest
                      ? DarkModeColors.success(context)
                      : fuelColor,
                  width: isCheapest ? 6 : 4,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status indicator + 24h badge
                Column(
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
                ),
                const SizedBox(width: 12),

                // Station info (left side, takes remaining space)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _hasBrand ? station.brand : station.street,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (_hasBrand)
                        Text(
                          '${station.street}, ${station.postCode} ${station.place}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          '${station.postCode} ${station.place}',
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
                  ),
                ),

                const SizedBox(width: 8),

                // Right side: rating + price + favorite (right-aligned)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // User rating stars (above price)
                    if (rating != null && rating! >= 1 && rating! <= 5)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: _RatingStars(rating: rating!),
                      ),
                    // Price + favorite star on one row, right-aligned
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (priceTier != null &&
                            priceTier != PriceTier.unknown)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              iconForPriceTier(priceTier!),
                              size: 16,
                              color: station.isOpen
                                  ? fuelColor
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        RichText(
                          overflow: TextOverflow.ellipsis,
                          text: PriceFormatter.priceTextSpan(
                            price,
                            baseStyle: theme.textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: station.isOpen
                                  ? fuelColor
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Favorite button — compact, no extra padding
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: isFavorite ? Colors.amber : null,
                              size: 22,
                            ),
                            onPressed: onFavoriteTap,
                            tooltip: isFavorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                          ),
                        ),
                      ],
                    ),
                    if (isCheapest)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: DarkModeColors.successSurface(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.cheapest ?? 'Cheapest',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: DarkModeColors.success(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (selectedFuelType == FuelType.all && !isCheapest) ...[
                      const SizedBox(height: 2),
                      _PriceRow(
                        label: 'E5',
                        price: station.e5,
                        fuelType: FuelType.e5,
                        isProfileFuel: profileFuelType is FuelTypeE5,
                      ),
                      _PriceRow(
                        label: 'E10',
                        price: station.e10,
                        fuelType: FuelType.e10,
                        isProfileFuel: profileFuelType is FuelTypeE10,
                      ),
                      _PriceRow(
                        label: 'Diesel',
                        price: station.diesel,
                        fuelType: FuelType.diesel,
                        isProfileFuel: profileFuelType is FuelTypeDiesel,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Displays 1-5 small star icons for the user's station rating.
class _RatingStars extends StatelessWidget {
  final int rating;

  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 12,
          color: i < rating ? Colors.amber : Colors.grey.shade400,
        );
      }),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double? price;
  final FuelType fuelType;

  /// When true, this row is the user's preferred fuel type and should be
  /// rendered larger with the fuel-type color to stand out.
  final bool isProfileFuel;

  const _PriceRow({
    required this.label,
    required this.price,
    required this.fuelType,
    this.isProfileFuel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fuelColor = FuelColors.forType(fuelType);
    final color = price != null
        ? fuelColor
        : theme.colorScheme.onSurfaceVariant;

    final dotSize = isProfileFuel ? 8.0 : 6.0;
    final fontSize = isProfileFuel ? 12.0 : null; // null = labelSmall default
    final fontWeight = isProfileFuel ? FontWeight.bold : FontWeight.w600;
    final labelWeight = isProfileFuel ? FontWeight.w600 : FontWeight.normal;
    final labelColor = isProfileFuel ? fuelColor : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: fontSize,
            fontWeight: labelWeight,
            color: labelColor,
          ),
        ),
        Text(
          PriceFormatter.formatPriceCompact(price),
          style: theme.textTheme.labelSmall?.copyWith(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: color,
              ),
        ),
      ],
    );
  }
}
