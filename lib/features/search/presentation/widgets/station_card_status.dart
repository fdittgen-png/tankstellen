// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'station_card.dart';

/// The card's single **label**-role metadata line (#3949):
/// `distance · Updated {time} · ●`.
///
/// The status dot is the open / closed / unknown state (#3198 tri-state:
/// unknown is the neutral muted dot, never red); its tooltip and
/// semantics carry the localized state and — when the station is open
/// around the clock — the 24 h flag that used to be a separate badge. Both
/// text segments are `Flexible` with ellipsis so a raised text scale or an
/// expanded translation truncates the timestamp first and the distance
/// second, never overflowing the row.
class _MetaLine extends StatelessWidget {
  final Station station;

  /// The localized open state the card already computed for its own
  /// semantic label — reused for the dot so the two never disagree.
  final String semanticStatus;

  /// #3905 — amber "Updated …" segment + "Old price" badge (see
  /// [StationCard.isStalePrice]).
  final bool isStalePrice;

  const _MetaLine({
    required this.station,
    required this.semanticStatus,
    required this.isStalePrice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = AppText.label(context);
    final statusTooltip = station.is24h
        ? l10n.stationCardStatus24h(semanticStatus)
        : semanticStatus;
    return Row(
      children: [
        Flexible(
          flex: 2,
          child: _DistanceSegment(station: station, style: style),
        ),
        if (station.updatedAt != null) ...[
          _Separator(style: style),
          Flexible(
            flex: 3,
            child: _UpdatedRow(
              updatedAt: station.updatedAt!,
              isStalePrice: isStalePrice,
            ),
          ),
        ],
        const SizedBox(width: Spacing.md),
        Tooltip(
          key: const Key('station_card_status_dot'),
          message: statusTooltip,
          child: Semantics(
            label: statusTooltip,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: switch (station.isOpen) {
                  true => DarkModeColors.success(context),
                  false => DarkModeColors.error(context),
                  null => DarkModeColors.mutedText(context),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The middle-dot between two metadata segments.
class _Separator extends StatelessWidget {
  final TextStyle style;

  const _Separator({required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      // A language-neutral punctuation glyph, not a translatable string.
      child: Text('·', style: style),
    );
  }
}

/// The distance segment. #3634 — when the OSRM table has answered for
/// this station, the REAL road distance replaces the crow-flies figure
/// (the route icon marks the difference); otherwise the haversine value
/// stands as always.
class _DistanceSegment extends StatelessWidget {
  final Station station;
  final TextStyle style;

  const _DistanceSegment({required this.station, required this.style});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final roadKm = ref.watch(
          roadDistancesProvider.select((m) => m[station.id]),
        );
        if (roadKm == null) {
          return Text(
            PriceFormatter.formatDistance(station.dist),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, size: 12, color: style.color),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                PriceFormatter.formatDistance(roadKm),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// #3633 — highway mode v2: "via exit {ref} · +{km} km" under the meta
/// line when the radar's exit layer annotated this station (same
/// side-channel pattern as roadDistancesProvider). Absent off-highway /
/// for on-road service areas / when the exits asset hasn't loaded — the
/// line simply doesn't render.
class _HighwayExitLine extends StatelessWidget {
  final Station station;

  const _HighwayExitLine({required this.station});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = AppText.label(context);
    return Consumer(
      builder: (context, ref, _) {
        final info = ref.watch(
          highwayExitInfoMapProvider.select((m) => m[station.id]),
        );
        if (info == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: Spacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fork_right, size: 12, color: style.color),
              const SizedBox(width: Spacing.xs),
              Flexible(
                child: Text(
                  l10n.highwayViaExit(
                    info.exitLabel,
                    UnitFormatter.formatDecimal(info.detourKm),
                  ),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The "Updated {time}" freshness segment (#2622). #3905 — when
/// [isStalePrice] is set the icon + text switch to the tertiary (amber)
/// colour and a small "Old price" badge follows, so a weeks-old price no
/// longer reads like a fresh one. A [Wrap] hosts the two: the badge sits
/// beside the timestamp when the line has room and drops under it
/// otherwise (expanded translations, raised text scale, 320 dp) — a
/// Wrap never overflows horizontally, and the badge text itself
/// ellipsises inside the segment width as a last resort.
class _UpdatedRow extends StatelessWidget {
  final String updatedAt;
  final bool isStalePrice;

  const _UpdatedRow({required this.updatedAt, required this.isStalePrice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final base = AppText.label(context);
    final style = isStalePrice
        ? base.copyWith(color: theme.colorScheme.tertiary)
        : base;
    return Wrap(
      spacing: Spacing.xs,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.update, size: 12, color: style.color),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                // #2622 — wrap the upstream pre-formatted timestamp as
                // "Updated {time}" so it reads as freshness, not a bare
                // code. (No relative "2h ago": updatedAt is a lossy,
                // per-country pre-formatted String.)
                l10n.stationUpdatedLabel(updatedAt),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (isStalePrice)
          Container(
            key: const Key('station_card_stale_price_badge'),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: AppRadius.sm,
            ),
            child: Text(
              l10n.stalePriceBadge,
              style: base.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

/// Build the address line, collapsing empty parts so the line never
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
