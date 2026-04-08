import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/station_amenity.dart';

/// Displays station amenities as compact icon chips.
///
/// Shows each amenity as a small chip with an icon and short label.
/// Designed to fit in tight spaces like station cards and detail headers.
class AmenityChips extends StatelessWidget {
  final Set<StationAmenity> amenities;

  /// Maximum number of chips to display. Extra amenities show a "+N" chip.
  final int maxVisible;

  const AmenityChips({
    super.key,
    required this.amenities,
    this.maxVisible = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sorted = amenities.toList();
    final visible = sorted.take(maxVisible).toList();
    final overflow = sorted.length - maxVisible;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        ...visible.map((a) => _AmenityChip(
              amenity: a,
              label: _localizedLabel(a, l10n),
              theme: theme,
            )),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$overflow',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  String _localizedLabel(StationAmenity a, AppLocalizations? l10n) {
    return switch (a) {
      StationAmenity.shop => l10n?.amenityShop ?? 'Shop',
      StationAmenity.carWash => l10n?.amenityCarWash ?? 'Car Wash',
      StationAmenity.airPump => l10n?.amenityAirPump ?? 'Air',
      StationAmenity.toilet => l10n?.amenityToilet ?? 'WC',
      StationAmenity.restaurant => l10n?.amenityRestaurant ?? 'Food',
      StationAmenity.atm => l10n?.amenityAtm ?? 'ATM',
      StationAmenity.wifi => l10n?.amenityWifi ?? 'WiFi',
      StationAmenity.ev => l10n?.amenityEv ?? 'EV',
    };
  }
}

class _AmenityChip extends StatelessWidget {
  final StationAmenity amenity;
  final String label;
  final ThemeData theme;

  const _AmenityChip({
    required this.amenity,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            amenityIcon(amenity),
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
