// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'station_card.dart';

/// Status dot (green/red) with optional 24h badge below it.
class _StatusColumn extends StatelessWidget {
  final Station station;

  const _StatusColumn({required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: station.isOpen
                ? DarkModeColors.success(context)
                : DarkModeColors.error(context),
          ),
        ),
        if (station.is24h)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '24h',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Left-side text block: brand/name title, address line, distance / updated
/// indicator, and amenity chips.
class _StationDetails extends StatelessWidget {
  final Station station;
  final bool hasBrand;

  /// #2899/#2995 — when non-null, the Fuel Station Radar "closeness" bar is
  /// rendered under the distance row, scaled to this radius in metres. The radar
  /// list passes the user's APPROACH RADIUS (`profile.approachRadiusKm * 1000`),
  /// the SAME base the recording radar card + PiP use, so all three surfaces are
  /// consistent on the user's approach-radius base. Null on the regular search
  /// list, so the card is unchanged there.
  final double? closenessRadiusMeters;

  const _StationDetails({
    required this.station,
    required this.hasBrand,
    this.closenessRadiusMeters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // #2926 — title fallback brand → name → localized "Unbranded station".
    // The raw street is NEVER the title: it is the address subtitle below, so
    // promoting it to the title read as a broken duplicate (e.g. "26 AVENUE DE
    // VERDUN" shown as the station "name", repeated on the next line). An
    // unbranded forecourt that carries a real name (e.g. a Mexican CRE company
    // name) still shows that name; one with no brand AND no name gets the
    // localized label, and the street drops to the address line instead.
    final useName = !hasBrand && station.name.isNotEmpty;
    final titleText = hasBrand
        ? station.brand
        : useName
            ? station.name
            : (l10n?.stationUnbrandedTitle ?? 'Unbranded station');
    // The street is shown on the address line whenever it is NOT the title —
    // i.e. for a branded station (it was already), and now also for the
    // unbranded label case (the street is no longer hoisted to the title).
    final showStreetInAddress = hasBrand || !useName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // #2161 — was a Hero flight to the detail-screen title; the
        // detail screen no longer shows the station name in its AppBar
        // and no longer animates the title, so the source Hero is
        // dropped too. Plain Text only.
        Text(
          titleText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          _addressLine(station, showStreetInAddress),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.xs),
        Row(
          children: [
            // #2622 — distance gets priority in this cramped row; the
            // timestamp (Flexible) is what wraps/ellipsises first.
            Text(
              PriceFormatter.formatDistance(station.dist),
              style: theme.textTheme.bodySmall,
            ),
            if (station.updatedAt != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.update,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.xs),
              Flexible(
                child: Text(
                  // #2622 — wrap the upstream pre-formatted timestamp as
                  // "Updated {time}" so it reads as freshness, not a bare
                  // code. (No relative "2h ago": updatedAt is a lossy,
                  // per-country pre-formatted String.)
                  l10n?.stationUpdatedLabel(station.updatedAt!) ??
                      'Updated ${station.updatedAt!}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        // #2899/#2984 — Fuel Station Radar closeness bar: the SAME green→accent
        // [ProximityFillBar] the trip radar card + PiP overlay use, so all
        // three radar surfaces fill identically as the driver nears a station.
        // `station.dist` is the great-circle distance in km → metres for the
        // bar; it scales to an ABSOLUTE fixed radius (`closenessRadiusMeters` =
        // min(searchRadius, cap), see [StationCard]), so closer = fuller and a
        // given station's fill is stable across result-set changes. Live: the
        // radar re-stamps `dist` on each scan, so the bar re-fills as the user
        // moves — the SCALE stays put, only the distance changes.
        if (closenessRadiusMeters != null) ...[
          const SizedBox(height: Spacing.xs),
          ProximityFillBar(
            distanceMeters: station.dist * 1000.0,
            radiusMeters: closenessRadiusMeters,
          ),
        ],
        if (station.amenities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AmenityChips(amenities: station.amenities),
          ),
      ],
    );
  }
}

/// Build the address subtitle line, collapsing empty parts so the line never
/// shows an orphan comma (#2704). [includeStreet] adds the street as the first
/// segment (for branded stations and the unbranded-label case, where the
/// street is no longer the title — #2926); the city block is always
/// `postCode place` joined on whitespace.
String _addressLine(Station station, bool includeStreet) {
  final city = '${station.postCode} ${station.place}'.trim();
  if (!includeStreet || station.street.isEmpty) return city;
  if (city.isEmpty) return station.street;
  return '${station.street}, $city';
}
