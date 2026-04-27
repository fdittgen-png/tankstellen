import 'package:flutter/material.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';

part 'all_prices_station_card_parts.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      clipBehavior: Clip.antiAlias,
      elevation: theme.brightness == Brightness.dark ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
