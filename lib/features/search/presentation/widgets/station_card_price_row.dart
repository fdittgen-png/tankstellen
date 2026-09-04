// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'station_card.dart';

/// The all-fuels footer (`FuelType.all`, #3949): the three grade prices
/// as label-role rows in a [Wrap], so they sit on one line where the
/// card has room and fold onto a second one at 320 dp instead of forming
/// a right-hand column that dictated the card's height.
class _AllFuelsRows extends StatelessWidget {
  final Station station;
  final FuelType? profileFuelType;

  const _AllFuelsRows({required this.station, required this.profileFuelType});

  /// ISO country code inferred from the station id, used to pick the
  /// right fuel-grade labels (#2717 — `mx-` → PEMEX Magna/Premium).
  String? get _countryCode => Countries.countryCodeForStationId(station.id);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.lg,
      runSpacing: Spacing.xs,
      children: [
        _PriceRow(
          label: fuelDisplayLabel(FuelType.e5, countryCode: _countryCode),
          price: station.e5,
          fuelType: FuelType.e5,
          isProfileFuel: profileFuelType is FuelTypeE5,
        ),
        _PriceRow(
          label: fuelDisplayLabel(FuelType.e10, countryCode: _countryCode),
          price: station.e10,
          fuelType: FuelType.e10,
          isProfileFuel: profileFuelType is FuelTypeE10,
        ),
        _PriceRow(
          label: fuelDisplayLabel(FuelType.diesel, countryCode: _countryCode),
          price: station.diesel,
          fuelType: FuelType.diesel,
          isProfileFuel: profileFuelType is FuelTypeDiesel,
        ),
      ],
    );
  }
}

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
    final base = AppText.label(context);
    final fontSize = isProfileFuel ? 12.0 : base.fontSize;
    final fontWeight = isProfileFuel ? FontWeight.bold : FontWeight.w600;
    final labelWeight = isProfileFuel ? FontWeight.w600 : FontWeight.normal;
    final labelColor = isProfileFuel ? fuelColor : base.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          margin: const EdgeInsets.only(right: Spacing.sm),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(
          '$label: ',
          style: base.copyWith(
            fontSize: fontSize,
            fontWeight: labelWeight,
            color: labelColor,
          ),
        ),
        // #2973 — flash the alternative-fuel price on change, matching the
        // headline price. Reduced motion is honoured inside the widget.
        AnimatedPriceText(
          price: price,
          child: Text(
            PriceFormatter.formatPriceCompact(price),
            style: base.copyWith(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              fontFeatures: const [AppText.tabularFigures],
            ),
          ),
        ),
      ],
    );
  }
}
