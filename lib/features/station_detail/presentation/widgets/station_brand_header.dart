// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/station.dart';
import 'station_brand_helpers.dart';

/// Brand logo + station name block at the top of the station detail body.
///
/// #482: stations returned without a recognised brand previously rendered
/// just the street address, leaving the user unsure whether the missing
/// brand was a bug or the station genuinely had no chain affiliation.
/// Now we also show an explicit "Station indépendante" subtitle when the
/// parser flagged the station with the independent sentinel.
class StationBrandHeader extends StatelessWidget {
  final Station station;

  const StationBrandHeader({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // #1996 — the dedicated body Address section is gone (it just
    // duplicated the street the AppBar already showed). Fold the
    // postal code + place into the brand-header subtitle so the city
    // info still reaches the user. Composed as "<street>, <postcode>
    // <place>" — falls back gracefully to whichever pieces the upstream
    // populated. // i18n-ignore: language-neutral postal format mask.
    final addressLine = [
      if (station.street.isNotEmpty) station.street,
      if (station.postCode.isNotEmpty || station.place.isNotEmpty)
        '${station.postCode} ${station.place}'.trim(),
    ].join(', ');

    // #2161 — when the brand is empty/sentinel, fall back to the
    // station name before the street. Matches the home-widget builder
    // so a station that displays as "Intermarché" in the widget reads
    // as "Intermarché" in the detail header too. `headingIsBrandOrName`
    // tracks whether the heading is the brand/name (and therefore the
    // address should appear as a subtitle) or the street fallback (in
    // which case only the postCode + place should appear below).
    final heading = stationDisplayHeading(station);
    final headingIsBrandOrName = heading != station.street;

    return Semantics(
      label: headingIsBrandOrName && heading != addressLine
          ? '$heading, $addressLine'
          : heading,
      header: true,
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BrandLogo(brand: station.brand, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (headingIsBrandOrName)
                  Text(addressLine, style: theme.textTheme.bodyLarge)
                else if (addressLine != station.street && addressLine.isNotEmpty)
                  // Heading IS the street — still surface postal code +
                  // place on a second line so the user gets the city.
                  Text(
                    '${station.postCode} ${station.place}'.trim(),
                    style: theme.textTheme.bodyLarge,
                  ),
                if (isIndependentSentinel(station))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      l10n?.independentStation ?? 'Independent station',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
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
