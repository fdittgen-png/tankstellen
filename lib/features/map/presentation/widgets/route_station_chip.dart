import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../search/domain/entities/station.dart';

/// A chip representing a station stop along the route.
///
/// Shows a sequence number badge, station name, price, and distance.
/// Selected chips use a filled primary style; unselected use an outlined style.
class RouteStationChip extends StatelessWidget {
  final Station station;
  final int stopNumber;
  final bool isSelected;
  final double? price;
  final VoidCallback onTap;

  const RouteStationChip({
    super.key,
    required this.station,
    required this.stopNumber,
    required this.isSelected,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final selectedBg = theme.colorScheme.primary;
    final selectedFg = theme.colorScheme.onPrimary;
    final unselectedBg = theme.colorScheme.surface;
    final unselectedFg = theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? selectedBg
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBg.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedFg.withValues(alpha: 0.25)
                    : theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$stopNumber',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? selectedFg
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    station.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? selectedFg : unselectedFg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      price != null
                          ? PriceFormatter.formatPrice(price)
                          : '--',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? selectedFg.withValues(alpha: 0.9)
                            : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      ' \u00b7 ${UnitFormatter.formatDistance(station.dist)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? selectedFg.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
