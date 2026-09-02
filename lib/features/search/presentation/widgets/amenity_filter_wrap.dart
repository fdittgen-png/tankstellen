// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station_amenity.dart';
import 'criteria/criteria_chip_group.dart';

/// FilterChips, one per [StationAmenity], used by the Search criteria
/// screen to let the user filter results by station equipment (shop,
/// car wash, toilet, EV, …).
///
/// Stateless: the parent owns the selection set and forwards toggles
/// via [onToggle].
///
/// #1529 turned the original [Wrap] into a horizontally-scrolling row to
/// reclaim two rows of vertical space. #3927 reverts that trade: the
/// scroller clipped labels mid-word ("W…") with no affordance that more
/// chips existed, and it could hide an ACTIVE filter off-screen. The
/// group now wraps — about two rows at 360 dp — and folds the remainder
/// behind one "Show more (n)" chip, which costs a single row while
/// keeping every selected chip visible.
class AmenityFilterWrap extends StatelessWidget {
  final Set<StationAmenity> selected;
  final ValueChanged<StationAmenity> onToggle;

  /// How many chips stay visible while the group is collapsed. Selected
  /// chips are shown regardless of their position.
  static const int collapsedCount = 6;

  const AmenityFilterWrap({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const amenities = StationAmenity.values;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CriteriaChipGroup(
        groupKeyPrefix: 'criteria-amenity',
        collapsedCount: collapsedCount,
        selectedFlags: [
          for (final amenity in amenities) selected.contains(amenity),
        ],
        chips: [
          for (final amenity in amenities)
            FilterChip(
              key: ValueKey('criteria-amenity-${amenity.name}'),
              avatar: Icon(amenityIcon(amenity), size: 18),
              label: Text(_label(amenity, l10n)),
              selected: selected.contains(amenity),
              onSelected: (_) => onToggle(amenity),
            ),
        ],
      ),
    );
  }

  String _label(StationAmenity a, AppLocalizations l10n) {
    return switch (a) {
      StationAmenity.shop => l10n.amenityShop,
      StationAmenity.carWash => l10n.amenityCarWash,
      StationAmenity.airPump => l10n.amenityAirPump,
      StationAmenity.toilet => l10n.amenityToilet,
      StationAmenity.restaurant => l10n.amenityRestaurant,
      StationAmenity.atm => l10n.amenityAtm,
      StationAmenity.wifi => l10n.amenityWifi,
      StationAmenity.ev => l10n.amenityEv,
    };
  }
}
