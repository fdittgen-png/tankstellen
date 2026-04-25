part of 'station_card.dart';

/// Right-side block: user rating stars, selected-fuel price with tier icon
/// and favorite toggle, optional "Cheapest" badge, and (in all-fuels mode)
/// the alternative-fuel mini price rows.
class _StationPriceColumn extends StatelessWidget {
  final Station station;
  final FuelType selectedFuelType;
  final double? price;
  final String? currencyOverride;
  final Color fuelColor;
  final bool isFavorite;
  final bool isCheapest;
  final PriceTier? priceTier;
  final int? rating;
  final FuelType? profileFuelType;
  final VoidCallback? onFavoriteTap;

  const _StationPriceColumn({
    required this.station,
    required this.selectedFuelType,
    required this.price,
    required this.currencyOverride,
    required this.fuelColor,
    required this.isFavorite,
    required this.isCheapest,
    required this.priceTier,
    required this.rating,
    required this.profileFuelType,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (rating != null && rating! >= 1 && rating! <= 5)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _RatingStars(rating: rating!),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (priceTier != null && priceTier != PriceTier.unknown)
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
            AnimatedPriceText(
              price: price,
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: PriceFormatter.priceTextSpan(
                  price,
                  currencyOverride: currencyOverride,
                  baseStyle: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: station.isOpen
                        ? fuelColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: AnimatedFavoriteStar(
                  isFavorite: isFavorite,
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
