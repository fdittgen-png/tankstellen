// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/domain/station.dart';
import '../../../../core/services/station_offer.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../l10n/app_localizations.dart';
import 'station_brand_helpers.dart';

/// #3337 — prominent, labelled "directions" affordance for the station-detail
/// screen.
///
/// Getting directions to a forecourt is the single most common action on this
/// screen, but it used to be a small `Icons.directions` `IconButton` buried as
/// one of five AppBar action icons — users struggled to find it ("très
/// petit"). Surfacing it as an extended FAB (icon + `l10n.navigate` label)
/// makes it immediately discoverable, mirroring the "Directions" affordance on
/// a maps place card. Behaviour is identical to the old icon
/// ([NavigationUtils.openInMaps]).
///
/// #4120 — [extended] false collapses it to the icon alone while the
/// list is moving, so the label stops covering the rating stars a user
/// is scrolling towards. See [ScrollAwareFabHost].
class StationDirectionsFab extends StatelessWidget {
  final Station station;

  /// Whether to show the label beside the icon. Defaults to true, the
  /// resting state — the labelled form is the whole point of #3337.
  final bool extended;

  const StationDirectionsFab({
    super.key,
    required this.station,
    this.extended = true,
  });

  /// The FAB, or null when [station] is a reference price with nowhere
  /// to drive to (#4348). The hosts pass this straight to
  /// `Scaffold.floatingActionButton`, so a deep-linked LU/GR detail shows
  /// its price without a Navigate button pointing at a town square.
  static StationDirectionsFab? forStation(Station station,
      {bool extended = true}) {
    final offer = StationOffer.forStation(
        stationId: station.id, lat: station.lat, lng: station.lng);
    return offer.canNavigate
        ? StationDirectionsFab(station: station, extended: extended)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FloatingActionButton.extended(
      key: const Key('station_directions_fab'),
      onPressed: () => unawaited(
        NavigationUtils.openStation(
          stationId: station.id,
          lat: station.lat,
          lng: station.lng,
          label: hasRealBrand(station) ? station.brand : station.street,
        ),
      ),
      icon: const Icon(Icons.directions),
      label: Text(l10n.navigate),
      // The tooltip carries the label while it is collapsed, so the
      // button never becomes an unexplained icon — and the semantic
      // label stays constant either way.
      isExtended: extended,
      tooltip: l10n.navigate,
    );
  }
}
