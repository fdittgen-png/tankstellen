import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/station_amenity.dart';

/// Wrap of FilterChips, one per [StationAmenity], used by the Search
/// criteria screen to let the user filter results by station equipment
/// (shop, car wash, toilet, EV, …).
///
/// Stateless: the parent owns the selection set and forwards toggles
/// via [onToggle]. Pulled out of `search_criteria_screen.dart` so the
/// screen drops the inline private widget and so the chip wrap can be
/// exercised by widget tests in isolation.
class AmenityFilterWrap extends StatelessWidget {
  final Set<StationAmenity> selected;
  final ValueChanged<StationAmenity> onToggle;

  const AmenityFilterWrap({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final amenity in StationAmenity.values)
          FilterChip(
            key: ValueKey('criteria-amenity-${amenity.name}'),
            avatar: Icon(amenityIcon(amenity), size: 18),
            label: Text(_label(amenity, l10n)),
            selected: selected.contains(amenity),
            onSelected: (_) => onToggle(amenity),
          ),
      ],
    );
  }

  String _label(StationAmenity a, AppLocalizations? l10n) {
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
