// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station.dart';
import 'station_brand_helpers.dart';
import 'station_header_metrics.dart';

/// Brand logo + station name block at the top of the station detail body.
///
/// #482: stations returned without a recognised brand previously rendered
/// just the street address, leaving the user unsure whether the missing
/// brand was a bug or the station genuinely had no chain affiliation.
/// Now we also show an explicit "Station indépendante" subtitle when the
/// parser flagged the station with the independent sentinel.
///
/// #3902 — the round "directions" button that used to sit at the end of
/// this row (#3344) is gone: the screen already carries the extended
/// "Navigate" FAB (#3337), and two affordances for the same action read as
/// two different actions. The FAB is the ONE navigate action on both the
/// compact and the wide layout.
///
/// The text styles and gaps below are the ones `stationHeaderExpandedHeight`
/// measures — keep [kBrandLogoSize] / [kBrandLogoGap] / the style lookups in
/// sync with that helper, or the collapsing header band mis-sizes.
class StationBrandHeader extends StatelessWidget {
  final Station station;

  const StationBrandHeader({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // #2161 — when the brand is empty/sentinel, fall back to the
    // station name before the street. Matches the home-widget builder
    // so a station that displays as "Intermarché" in the widget reads
    // as "Intermarché" in the detail header too. The subtitle carries the
    // address (or just postcode + place when the heading IS the street).
    final heading = stationDisplayHeading(station);
    final subtitle = stationHeaderSubtitle(station);

    return Semantics(
      label: subtitle != null ? '$heading, $subtitle' : heading,
      header: true,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BrandLogo(brand: station.brand, size: kBrandLogoSize),
          const SizedBox(width: kBrandLogoGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: headerHeadingStyle(theme)),
                if (subtitle != null)
                  Text(subtitle, style: headerSubtitleStyle(theme)),
                if (isIndependentSentinel(station))
                  Padding(
                    padding: const EdgeInsets.only(
                      top: kIndependentLineGap,
                    ),
                    child: Text(
                      l10n.independentStation,
                      style: headerIndependentStyle(theme),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
