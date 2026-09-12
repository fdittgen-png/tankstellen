// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/station.dart';
import '../../../../core/services/country_service_registry.dart';
import '../../../../core/services/radar/motorway_exits_provider.dart';
import '../../../../core/domain/price_freshness.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/price_freshness_words.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/time/app_clock.dart';
import '../../providers/road_distance_provider.dart';
import '../../../../core/country/country_config.dart';

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
class StationCardMetaLine extends StatelessWidget {
  final Station station;

  /// The localized open state the card already computed for its own
  /// semantic label — reused for the dot so the two never disagree.
  final String semanticStatus;

  /// #3905 — amber "Updated …" segment + "Old price" badge (see
  /// [StationCard.isStalePrice]).
  final bool isStalePrice;

  const StationCardMetaLine({
    super.key,
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
        if (station.updatedAt != null)
          Flexible(
            child: _UpdatedRow(
              updatedAt: station.updatedAt!,
              isStalePrice: isStalePrice,
            ),
          ),
        // #4105 — which database this price came from. A cross-border
        // search mixes sources, and the criteria bar already names them
        // with flags; a row said nothing about its own.
        _SourceFlag(station: station, style: style),
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
class StationCardHighwayExitLine extends StatelessWidget {
  final Station station;

  const StationCardHighwayExitLine({super.key, required this.station});

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
class _UpdatedRow extends ConsumerWidget {
  final String updatedAt;
  final bool isStalePrice;

  const _UpdatedRow({required this.updatedAt, required this.isStalePrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // #4092 — freshness in WORDS. The stamp itself is a lossy,
    // per-country pre-formatted string ("14:22" with no date in some
    // countries), so "Updated 14:22" asked the reader to work out
    // whether that was this afternoon or last Tuesday. The band answers
    // that question; the exact stamp stays in the tooltip, so the coarse
    // word never hides the precise figure.
    final band = priceFreshness(
      updatedAt,
      now: ref.watch(appClockProvider).now(),
    );
    final word = priceFreshnessWord(band, l10n);
    final style = AppText.label(context)
        .copyWith(color: priceFreshnessColor(band, context));
    // #3905 — the caller's own staleness verdict still wins where it is
    // given: the favorites list computes it against its own stored row.
    final stale = isStalePrice || band == PriceFreshness.stale;
    final tooltip = l10n.priceFreshnessTooltip(
      word,
      l10n.stationUpdatedLabel(updatedAt),
    );

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stale ? Icons.history_toggle_off : Icons.schedule,
                size: 12,
                color: style.color,
              ),
              const SizedBox(width: Spacing.xs),
              Flexible(
                child: Text(
                  word,
                  key: const Key('station_card_freshness_word'),
                  style: stale
                      ? style.copyWith(fontWeight: FontWeight.w600)
                      : style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Build the address line, collapsing empty parts so the line never
/// shows an orphan comma (#2704). [includeStreet] adds the street as the first
/// segment (for branded stations and the unbranded-label case, where the
/// street is no longer the title — #2926); the city block is always
/// `postCode place` joined on whitespace.
///
/// Still the DETAIL screen's address. The result card stopped showing it
/// at #4091 — see [StationCardPlaceLine].
String stationCardAddressLine(Station station, bool includeStreet) {
  final city = '${station.postCode} ${station.place}'.trim();
  if (!includeStreet || station.street.isEmpty) return city;
  if (city.isEmpty) return station.street;
  return '${station.street}, $city';
}

/// Where it is and how far: `Pézenas · 2.5 km` (#4091).
///
/// The card used to carry the full postal address — street, post code,
/// town — on its own line. Nobody chooses a filling station by its house
/// number; they choose by town and by distance, and the street is one tap
/// away on the detail screen. Collapsing the two facts a driver actually
/// compares onto one line gives the list back a line per card, which is
/// what "four to six stations comparable without scrolling" is made of.
///
/// A station with no place name shows the distance alone. The street is
/// deliberately NOT a fallback: for the brandless stations whose name IS
/// their street (Mexican CRE rows, French independents) it would print
/// the title a second time, which is the #2926 duplicate all over again.
class StationCardPlaceLine extends StatelessWidget {
  const StationCardPlaceLine({super.key, required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final style = AppText.body(context);
    final place = station.place;
    return Row(
      children: [
        if (place.isNotEmpty)
          Flexible(
            child: Text(
              place,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (place.isNotEmpty) _Separator(style: style),
        _DistanceSegment(station: station, style: style),
      ],
    );
  }
}

/// The flag of the country whose open-data service published this price
/// (#4105).
///
/// The same glyph the summary band's `_DataSourceSegment` shows for the
/// search as a whole, at the same 11 pt, now per result — so on a
/// cross-border route the user can see at a glance WHICH database each
/// row came from, not just that several were queried. The tooltip and
/// the spoken label name the country and the service, exactly as the
/// band's credit chip does.
///
/// Resolved by [Countries.countryForStation] — the id prefix first,
/// which is canonical, then the coordinates. Renders nothing when the
/// station cannot be attributed, rather than guessing a flag.
///
/// The emoji itself is decorative: a screen reader hears the sentence,
/// never a lone flag glyph it would have to interpret.
class _SourceFlag extends StatelessWidget {
  const _SourceFlag({required this.station, required this.style});

  final Station station;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final country = Countries.countryForStation(
      id: station.id,
      lat: station.lat,
      lng: station.lng,
    );
    if (country == null || country.flag.isEmpty) {
      return const SizedBox.shrink();
    }
    // The service that published it, named the way the band names it.
    final attribution =
        CountryServiceRegistry.policyFor(country.code)?.attribution ??
            country.apiProvider;
    final label = attribution == null || attribution.isEmpty
        ? country.name
        : AppLocalizations.of(context)
            .stationSourceFlagTooltip(country.name, attribution);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Separator(style: style),
        Tooltip(
          message: label,
          child: Semantics(
            label: label,
            child: ExcludeSemantics(
              // Fixed 11 pt, matching the band's credit chip: the flag is
              // an identifier, so it must not grow and shrink with the
              // metadata text around it.
              child: Text(country.flag, style: const TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }
}
