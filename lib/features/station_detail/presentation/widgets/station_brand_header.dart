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

    return Semantics(
      label:
          '${hasRealBrand(station) ? station.brand : station.street}'
          '${hasRealBrand(station) && station.brand != station.street ? ', ${station.street}' : ''}',
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
                  Text(station.street, style: theme.textTheme.bodyLarge),
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
