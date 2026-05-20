import 'package:flutter/material.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/station.dart';
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

    return Semantics(
      label:
          '${hasRealBrand(station) ? station.brand : station.street}'
          '${hasRealBrand(station) && station.brand != station.street ? ', $addressLine' : ''}',
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
                  hasRealBrand(station) ? station.brand : station.street,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasRealBrand(station) && station.brand != station.street)
                  Text(addressLine, style: theme.textTheme.bodyLarge)
                else if (addressLine != station.street && addressLine.isNotEmpty)
                  // Brand IS the street (independent station rendering) —
                  // still surface postal code + place on a second line so
                  // the user gets the city without the body Address block.
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
