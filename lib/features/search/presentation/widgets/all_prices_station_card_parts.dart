part of 'all_prices_station_card.dart';

/// A single fuel badge rendered inside [AllPricesStationCard].
///
/// Library-private (`part of`) so the public API of the card stays unchanged.
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
