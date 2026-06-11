// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station_amenity.dart';

/// FilterChips, one per [StationAmenity], used by the Search criteria
/// screen to let the user filter results by station equipment (shop,
/// car wash, toilet, EV, …).
///
/// Stateless: the parent owns the selection set and forwards toggles
/// via [onToggle].
///
/// #1529 — switched from a multi-row [Wrap] to a single horizontally-
/// scrolling [Row]. The 8 chips at default chip width wrap to 3 rows
/// on Samsung S20 portrait, eating ~180 dp. A horizontal scroll
/// shows only ~3 chips at once but the user can pan to reveal the
/// rest, and the screen reclaims two full rows of vertical space for
/// the search-criteria controls below.
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Negative left padding cancels the default ListTile-like inset
      // when this widget sits inside a SectionContent, so the leftmost
      // chip aligns with the section title above it.
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final amenity in StationAmenity.values) ...[
            FilterChip(
              key: ValueKey('criteria-amenity-${amenity.name}'),
              avatar: Icon(amenityIcon(amenity), size: 18),
              label: Text(_label(amenity, l10n)),
              selected: selected.contains(amenity),
              onSelected: (_) => onToggle(amenity),
            ),
            if (amenity != StationAmenity.values.last)
              const SizedBox(width: 8),
          ],
        ],
      ),
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
