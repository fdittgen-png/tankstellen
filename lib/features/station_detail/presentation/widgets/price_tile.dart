import 'package:flutter/material.dart';

import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../search/domain/entities/fuel_type.dart';

/// A single fuel price row with colored icon and formatted price.
class PriceTile extends StatelessWidget {
  final String label;
  final double? price;
  final FuelType fuelType;

  const PriceTile({
    super.key,
    required this.label,
    required this.price,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context) {
    final color = price != null ? FuelColors.forType(fuelType) : Colors.grey;
    return ListTile(
      dense: true,
      leading: Icon(Icons.local_gas_station, color: color),
      title: Text(label),
      trailing: Text(
        PriceFormatter.formatPrice(price),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
      ),
    );
  }
}
