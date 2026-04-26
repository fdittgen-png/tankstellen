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

  /// Per-litre loyalty discount that applies to this station's brand
  /// (#1120 pilot). When non-null and positive, the column renders
  /// the effective price (raw − discount) as the headline number,
  /// strikes through the raw price below it, and adds a small
  /// `−€0.05` badge so the user can tell why the number changed.
  final double? loyaltyDiscount;
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
    required this.loyaltyDiscount,
    required this.onFavoriteTap,
  });

  /// Effective price after applying [loyaltyDiscount]. Returns the
  /// raw price unchanged when no discount applies. Floors the result
  /// at 0.001 so a hand-edited Hive dump with a wildly large
  /// discount can never produce a negative-looking display.
  double? get _effectivePrice {
    final raw = price;
    if (raw == null) return null;
    final discount = loyaltyDiscount;
    if (discount == null || discount <= 0) return raw;
    final effective = raw - discount;
    return effective < 0.001 ? 0.001 : effective;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective = _effectivePrice;
    final hasDiscount = loyaltyDiscount != null &&
        loyaltyDiscount! > 0 &&
        price != null &&
        effective != null;
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
              price: effective,
              child: Tooltip(
                // #1120 — when a loyalty discount applies, the
                // tooltip surfaces the un-discounted raw price so
                // power users can verify what the operator quoted.
                message: hasDiscount
                    ? 'Raw: ${PriceFormatter.formatPrice(price, currencyOverride: currencyOverride)}'
                    : '',
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: PriceFormatter.priceTextSpan(
                    effective,
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
        if (hasDiscount)
          _LoyaltyDiscountBadge(
            station: station,
            discount: loyaltyDiscount!,
            rawPrice: price!,
            currencyOverride: currencyOverride,
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

/// Small badge rendered under the price row when a loyalty / fuel-club
/// card applies (#1120 pilot). Shows the per-litre discount, the
/// canonical brand name, and a struck-through raw price so the user
/// can read both the headline number and the operator's quoted price
/// at once.
class _LoyaltyDiscountBadge extends StatelessWidget {
  final Station station;
  final double discount;
  final double rawPrice;
  final String? currencyOverride;

  const _LoyaltyDiscountBadge({
    required this.station,
    required this.discount,
    required this.rawPrice,
    required this.currencyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final canonical = BrandRegistry.canonicalize(station.brand) ?? '';
    final prefix = l?.loyaltyBadgePrefix ?? '−';
    final discountStr = PriceFormatter.formatPrice(
      discount,
      currencyOverride: currencyOverride,
    );
    final rawStr = PriceFormatter.formatPrice(
      rawPrice,
      currencyOverride: currencyOverride,
    );
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$prefix$discountStr ${canonical.isEmpty ? '' : canonical}'
                .trim(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 4),
          Text(
            rawStr,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onPrimaryContainer
                  .withValues(alpha: 0.7),
              decoration: TextDecoration.lineThrough,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
