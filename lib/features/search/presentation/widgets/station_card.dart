import 'package:flutter/material.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';

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

  const StationCard({
    super.key,
    required this.station,
    required this.selectedFuelType,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.isCheapest = false,
    this.priceTier,
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
                color: isCheapest ? Colors.green : fuelColor,
                width: isCheapest ? 6 : 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
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
                      color: station.isOpen ? Colors.green : Colors.red,
                    ),
                  ),
                  if (station.is24h)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('24h',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title: brand if available, otherwise address
                    Text(
                      _hasBrand ? station.brand : station.street,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Subtitle: address + city on one line if brand shown
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
                        Text(
                          PriceFormatter.formatDistance(station.dist),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (station.updatedAt != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.update, size: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            station.updatedAt!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Price — superscript 9/10ths cent (European standard)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                                ? FuelColors.forType(selectedFuelType)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      RichText(
                        text: PriceFormatter.priceTextSpan(
                          price,
                          baseStyle: theme.textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: station.isOpen
                                ? FuelColors.forType(selectedFuelType)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isCheapest)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(AppLocalizations.of(context)?.cheapest ?? 'Cheapest',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                  if (selectedFuelType == FuelType.all && !isCheapest) ...[
                    const SizedBox(height: 2),
                    _PriceRow(label: 'E5', price: station.e5, fuelType: FuelType.e5),
                    _PriceRow(label: 'E10', price: station.e10, fuelType: FuelType.e10),
                    _PriceRow(label: 'Diesel', price: station.diesel, fuelType: FuelType.diesel),
                  ],
                ],
              ),

              // Favorite button
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : null,
                ),
                onPressed: onFavoriteTap,
                tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }


}

class _PriceRow extends StatelessWidget {
  final String label;
  final double? price;
  final FuelType fuelType;

  const _PriceRow({
    required this.label,
    required this.price,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context) {
    final color = price != null
        ? FuelColors.forType(fuelType)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          PriceFormatter.formatPriceCompact(price),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
