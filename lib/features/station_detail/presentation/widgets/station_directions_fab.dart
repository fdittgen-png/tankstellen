// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/domain/station.dart';
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
class StationDirectionsFab extends StatelessWidget {
  final Station station;

  const StationDirectionsFab({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FloatingActionButton.extended(
      key: const Key('station_directions_fab'),
      onPressed: () => unawaited(
        NavigationUtils.openInMaps(
          station.lat,
          station.lng,
          label: hasRealBrand(station) ? station.brand : station.street,
        ),
      ),
      icon: const Icon(Icons.directions),
      label: Text(l10n.navigate),
    );
  }
}
