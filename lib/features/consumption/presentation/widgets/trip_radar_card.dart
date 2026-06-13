// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/approach_detector.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../approach/providers/effective_approach_state_provider.dart';
import '../../../approach/providers/radar_candidate_list_provider.dart';
import '../../../approach/providers/radar_swipe_provider.dart';
import '../../../profile/providers/effective_fuel_type_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import 'proximity_fill_bar.dart';
import 'radar_swipe_wrapper.dart';

/// "Closest station" radar card pinned to the TOP of the active
/// trip-recording column (#2380).
///
/// Surfaces the nearest / approaching fuel station and its price for
/// the driver's effective fuel type, updating as the driver moves.
/// Two data sources, in priority order:
///
/// 1. **Approach detector** ([effectiveApproachStateProvider]) — once
///    the driver is inside the configured geo-fence the state is
///    [ApproachInRadius] (or [ApproachLeaving] during the exit grace).
///    The card renders that target station + distance, mirroring the
///    huge-price PiP layout in `trip_recording_pip_view.dart`.
/// 2. **Nearest-station fallback** ([radarCandidateListProvider]) —
///    while still approaching ([ApproachPolling]) the detector carries
///    the live GPS fix; the fallback reuses it to query the search
///    chain for the ranked priced stations so the card isn't empty
///    before the geo-fence is crossed. The driver can swipe LEFT to
///    page to the NEARER station and swipe RIGHT to page to the FARTHER
///    one (#2661) — the shown candidate is the distance-ranked list
///    indexed by [radarSwipeProvider]'s `currentIndex` (clamped against
///    the live list length), and the swipe wiring lives in
///    [RadarSwipeWrapper]. The in-radius target is a single locked
///    station and is NOT swipeable.
///
/// When neither yields a station ([ApproachIdle] / null, no GPS fix, or
/// nothing in range) the card shows a graceful placeholder rather than
/// collapsing — the driver always sees the section is live.
///
/// Prices route through [PriceFormatter] (no hard-coded currency);
/// station / brand names are data, not localised strings.
class TripRadarCard extends ConsumerWidget {
  const TripRadarCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Guard both watches: under tests / first-run that don't bootstrap
    // the chain these can raise; the card degrades to its placeholder
    // rather than crashing the recording screen.
    ApproachState? approach;
    var fuel = FuelType.e10;
    try {
      approach = ref.watch(effectiveApproachStateProvider);
    } on Object {
      approach = null;
    }
    try {
      fuel = ref.watch(effectiveFuelTypeProvider);
    } on Object {
      fuel = FuelType.e10;
    }

    // 1. Approach-radius hit wins — render the targeted station.
    final Station? inRadiusStation = switch (approach) {
      ApproachInRadius(:final station) => station,
      ApproachLeaving(:final lastStation) => lastStation,
      _ => null,
    };
    final double? distanceMeters = approach is ApproachInRadius
        ? approach.distanceMeters
        : null;

    final title = l.tripRadarClosestStation;

    // The proximity fill bar's "indicated radius" is the user's default
    // radar radius (the same `profile.approachRadiusKm` the detector fences
    // against, #2661). Watched here so the bar re-scales if the slider moves.
    double? radiusMeters;
    try {
      final profile = ref.watch(activeProfileProvider);
      if (profile != null) radiusMeters = profile.approachRadiusKm * 1000.0;
    } on Object {
      radiusMeters = null;
    }

    if (inRadiusStation != null) {
      // The in-radius target is a single locked station — NOT swipeable.
      return RadarCard(
        title: title,
        station: inRadiusStation,
        fuel: fuel,
        distanceMeters: distanceMeters,
        live: true,
        radiusMeters: radiusMeters,
      );
    }

    // 2. Fallback — ranked priced stations off the live polling GPS, with
    //    swipe-to-page distance pagination (#2661).
    //
    // `skipLoadingOnReload: true` routes a *re-run* (the provider goes
    // AsyncLoading carrying its previous value via copyWithPrevious on
    // every approach-state tick) back through `data:` with the retained
    // list — so a rescan KEEPS the last station on screen instead of
    // blanking it to the "Scanning…" placeholder (#2583). A genuine
    // FIRST load (no prior value) still falls to `loading:`. The active
    // scan is signalled by a COLOUR-only tint (`scanning`), never text
    // and never a blanked row.
    final fallback = ref.watch(radarCandidateListProvider);
    final scanning = fallback.isLoading;
    final swipeIndex = ref.watch(radarSwipeProvider).currentIndex;
    return fallback.when(
      skipLoadingOnReload: true,
      data: (candidates) {
        if (candidates.isEmpty) {
          // A load COMPLETED with no priced station in range.
          return RadarPlaceholder(
            title: title,
            message: l.tripRadarNoStationNearby,
          );
        }
        // Clamp the page index against the live list length — a stale index
        // from a list that shrank between scans self-heals to the farthest
        // remaining station rather than going blank (#2661). 0 = nearest.
        final idx = swipeIndex.clamp(0, candidates.length - 1);
        return RadarSwipeWrapper(
          title: title,
          candidates: candidates,
          current: candidates[idx],
          fuel: fuel,
          scanning: scanning,
          radiusMeters: radiusMeters,
        );
      },
      // FIRST load only (no retained value) — the row is genuinely empty.
      loading: () =>
          RadarPlaceholder(title: title, message: l.tripRadarScanning),
      error: (_, _) =>
          RadarPlaceholder(title: title, message: l.tripRadarNoStationNearby),
    );
  }
}

/// Station + price row. Mirrors the PiP approach layout's station/price
/// resolution (`station.priceFor(fuel)` → [PriceFormatter.formatPrice],
/// name fallback to brand) in the trip screen's card idiom.
///
/// Public (not `_RadarCard`) so [RadarSwipeWrapper] in the sibling file
/// can render the current candidate inside its `Dismissible` (#2633).
class RadarCard extends StatelessWidget {
  final String title;
  final Station station;
  final FuelType fuel;
  final double? distanceMeters;

  /// True when the station comes from an in-radius approach hit (vs the
  /// nearest-station fallback) — drives the leading icon emphasis.
  final bool live;

  /// True while the fallback provider is re-running (a rescan). Signalled
  /// by a COLOUR tint on the leading icon only — the retained station
  /// stays fully readable, no text and no blanked row (#2583).
  final bool scanning;

  /// True when the swipe-to-page affordance is available (more than one
  /// candidate) — surfaces a faint `swap_horiz` glyph by the title so the
  /// gesture is discoverable (#2661). The fallback path sets this; the
  /// in-radius path never does.
  final bool swipeable;

  /// Radar radius in metres (`profile.approachRadiusKm * 1000`) — the
  /// proximity fill bar's "indicated radius" (#2661). Null collapses the bar.
  final double? radiusMeters;

  const RadarCard({
    super.key,
    required this.title,
    required this.station,
    required this.fuel,
    required this.distanceMeters,
    required this.live,
    this.scanning = false,
    this.swipeable = false,
    this.radiusMeters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final price = station.priceFor(fuel);
    final priceText = price != null ? PriceFormatter.formatPrice(price) : '--';
    final name = station.name.isNotEmpty ? station.name : station.brand;

    // #3258 — route through the SSoT distance formatter so the radar surface
    // matches the search/favorites cards: GB renders miles (and sub-km shows
    // metres/yards), instead of hardcoding km. formatDistance already shows
    // metres under 1 km and km above, so the in-radius vs fallback precision
    // split collapses into one unit-aware call.
    final String? distanceLabel = distanceMeters == null
        ? null
        : PriceFormatter.formatDistance(distanceMeters! / 1000.0);
    final subtitleParts = <String>[fuel.displayName, ?distanceLabel];

    // Tap → hand the station's coords to the SSoT navigation util, which
    // launches the OS's default driving/itinéraire app (geo: URI, Google-
    // Maps web fallback) — #2545. Reuses the existing `navigate` ARB key
    // for the tooltip/semantics affordance (no new key → no 23-locale
    // fan-out).
    final navigateLabel = l.navigate;

    return Card(
      margin: EdgeInsets.zero,
      child: Tooltip(
        message: navigateLabel,
        child: ListTile(
          onTap: () => NavigationUtils.openInMaps(
            station.lat,
            station.lng,
            label: station.displayName,
          ),
          // Leading icon doubles as the (colour-only) scan signal: an
          // in-radius hit is the primary accent; a fallback rescan
          // (`scanning`) tints the gas-station glyph to the primary
          // accent too, so the driver sees the refresh without the row
          // ever blanking or changing text (#2583).
          leading: Icon(
            live ? Icons.my_location : Icons.local_gas_station,
            size: 28,
            color: (live || scanning) ? theme.colorScheme.primary : null,
          ),
          // Overline carries the localised card title; the prominent line
          // is the (data, not ARB) station name + the fuel/distance row.
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // #2903 — Flexible so the overline ellipsizes in a
                  // narrow ListTile (e.g. the landscape split's right
                  // pane) instead of overflowing the title slot.
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (swipeable) ...[
                    const SizedBox(width: 6),
                    // Faint, decorative swipe-available hint — the
                    // discoverable affordance for the page gesture (#2633).
                    // Screen-reader users get the same capability via the
                    // wrapper's customSemanticsActions, so this glyph is
                    // excluded from the semantics tree.
                    ExcludeSemantics(
                      child: Icon(
                        Icons.swap_horiz,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                name.isNotEmpty ? name : title,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitleParts.join(' · '),
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // #2661 — corporate-green battery-style proximity bar: fills as
              // the driver nears the station (100% at the station, 0% at the
              // radar radius edge). Collapses when distance/radius unknown.
              if (distanceMeters != null && radiusMeters != null) ...[
                const SizedBox(height: 4),
                ProximityFillBar(
                  distanceMeters: distanceMeters!,
                  radiusMeters: radiusMeters,
                ),
              ],
            ],
          ),
          trailing: Text(
            priceText,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Graceful "scanning" / "no station nearby" placeholder. Keeps the
/// top slot occupied so the section never flickers in and out.
///
/// Public so the empty-list branch (and the sibling [RadarSwipeWrapper])
/// can reuse the same row idiom (#2633).
class RadarPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  const RadarPlaceholder({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.radar, size: 28),
        title: Text(title, style: theme.textTheme.bodySmall),
        subtitle: Text(message, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
