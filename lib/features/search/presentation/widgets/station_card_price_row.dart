part of 'station_card.dart';

/// Compact single-fuel price row used in all-fuels mode: colored dot,
/// fuel label, and formatted price. When [isProfileFuel] is true the
/// row is rendered larger with the fuel-type color to stand out.
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
    final fontSize = isProfileFuel ? 12.0 : null;
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
