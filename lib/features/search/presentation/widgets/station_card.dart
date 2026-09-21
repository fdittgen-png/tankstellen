// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/widgets/station_card_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trips/api.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/widgets/amenity_summary.dart';

import 'station_card_badges.dart';
import 'station_card_price_column.dart';
import 'station_card_price_row.dart';
import 'station_presentation.dart';
import 'station_card_status.dart';

/// One station in the results list, laid out against the visual grammar
/// (#3949, Epic #3947).
///
/// The card leads with its **display**-role number — the selected fuel's
/// price, top-left, with the brand mark beside it and the `€/L` unit on
/// its baseline — because the price is the one thing a result row is
/// about. Everything else is subordinate and reads in order:
///
///   1. price (+ tier arrow for colour-blind users) · Cheapest · ★
///   2. station name in the **title** role (+ the user's rating)
///   3. address in the **body** role
///   4. one **label** line: distance · freshness · status dot
///
/// The old layout had no focal number: a bold-ish 22 sp price sat in a
/// right-hand column beside a bold title, two `24h` / open badges competed
/// with it, and the whole card was a `Row` of three columns whose heights
/// never agreed. The 24 h flag and the open / closed / unknown state now
/// live in the status dot's tooltip and semantics (nothing is lost, there
/// is just no separate badge), so a single-price card stays under 150 dp
/// at 320 dp — `station_card_grammar_test.dart` pins that.
///
/// Every public parameter is unchanged; callers (search list, favourites,
/// radar list) are untouched.
class StationCard extends StatelessWidget {
  final Station station;
  final FuelType selectedFuelType;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool isCheapest;

  /// Optional price tier for accessibility icon indicator.
  /// When provided, a small arrow icon is shown next to the price
  /// so colorblind users can distinguish cheap/average/expensive.
  final PriceTier? priceTier;

  /// Optional user rating (1-5) for this station.
  /// When provided, small star icons are shown at the end of the title
  /// line.
  final int? rating;

  /// The user's preferred fuel type from their profile.
  /// When [selectedFuelType] is [FuelType.all], the matching price row
  /// is rendered larger and with the fuel-type color to make it visually
  /// dominant.
  final FuelType? profileFuelType;

  /// #4124 — the fuel the USER asked for, when [selectedFuelType] may not
  /// be it.
  ///
  /// The cross-border route list prices each station by its own country's
  /// profile fuel (#2631) and passes the result as [selectedFuelType], so
  /// under an E85 search a Spanish row can carry an E5 price. Given both,
  /// the card names the fuel it is actually showing. `null` — every other
  /// list — means "[selectedFuelType] is what was asked for", and no row
  /// carries a label: on a single-fuel list it would be noise on every
  /// card.
  final FuelType? requestedFuelType;

  /// Active loyalty/fuel-club discounts keyed by canonical brand
  /// string (#1120 pilot). When this station's brand canonicalizes to
  /// a key in the map and the per-litre discount is positive, the
  /// headline renders an effective price (raw − discount) plus a
  /// `−€0.05` badge. Stations whose brand isn't in the map render
  /// unchanged. Callers typically pass
  /// `ref.watch(activeDiscountByBrandProvider)` after collapsing to
  /// the canonical-brand string keys.
  final Map<String, double>? activeDiscountsByBrand;

  /// Radius (in metres) the Fuel Station Radar "closeness" bar scales to,
  /// or `null` to hide the bar (#2899). Only the on-search Fuel Station Radar
  /// result list passes it — the regular search list leaves it null so the
  /// card is unchanged.
  ///
  /// The list scales to the **search radius** (`searchRadiusProvider × 1000`),
  /// not the small 1 km radar geo-fence: result-list stations routinely exceed
  /// the geo-fence (2.4 km, 6.2 km, …), so scaling to the search radius makes
  /// the bar read as RELATIVE closeness across the list — the nearest forecourt
  /// reads near-full, the farthest near-empty — instead of every row pinning to
  /// empty. The same green→accent [ProximityFillBar] used by the trip card +
  /// PiP overlay, so all three radar surfaces share one fill metaphor.
  final double? closenessRadiusMeters;

  /// #3905 — when true the "Updated …" segment is rendered in the tertiary
  /// (amber) colour with a small "Old price" badge, telling the user the
  /// shown price is older than the caller's staleness threshold. The
  /// Favorites list is the only caller today (its cards are re-read for
  /// weeks and a July timestamp looked current in September); the search
  /// list leaves it `false`, so its cards are unchanged. The card itself
  /// carries no clock or timestamp parsing — the decision is the
  /// caller's (`stale_price_policy.dart` in favorites).
  final bool isStalePrice;

  /// #4094 — draw the hairline that divides this row from the next.
  ///
  /// Defaults to true, which is right everywhere today: a list's final
  /// hairline sits above the scroll clearance and reads as the end of
  /// the list rather than as a dangling line. A caller that wants it
  /// suppressed can, and `StationCardShell`'s tests pin both states —
  /// but the search list does NOT pass it, because threading "am I last"
  /// through `_buildFuelCard` and `SwipeableStationCard` costs three
  /// files of plumbing for one pixel row.
  final bool showSeparator;

  const StationCard({
    super.key,
    required this.station,
    required this.selectedFuelType,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.isCheapest = false,
    this.priceTier,
    this.rating,
    this.profileFuelType,
    this.requestedFuelType,
    this.activeDiscountsByBrand,
    this.closenessRadiusMeters,
    this.isStalePrice = false,
    this.showSeparator = true,
  });

  /// #4133 — every value this row shows, derived once. The card used to
  /// compute price, discount, currency, brand fallback and the #4124 fuel
  /// label itself, and so did the map marker, the map sheet and the
  /// favourites row — each a little differently. See
  /// [StationPresentation] for why that kept producing bugs.
  StationPresentation _presentation(AppLocalizations l10n) =>
      StationPresentation.of(
        station,
        selectedFuelType: selectedFuelType,
        requestedFuelType: requestedFuelType,
        activeDiscountsByBrand: activeDiscountsByBrand,
        l10n: l10n,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = _presentation(l10n);
    final formattedPrice = PriceFormatter.formatPrice(
      p.price,
      currencyOverride: p.currencySymbol,
    );
    // #3198 — tri-state: an unknown open state is announced as unknown,
    // never as closed (and never as open).
    final semanticStatus = switch (station.isOpen) {
      true => l10n.open,
      false => l10n.closed,
      null => l10n.openStateUnknown,
    };
    final semanticLabel = <String>[
      p.hasBrand ? station.brand : station.name,
      station.street,
      formattedPrice,
      // #4124 — a screen reader gets the whole sentence, not the pump
      // code: "E5" read out after a price says nothing on its own.
      if (p.substitutedFuelLabel case final label?)
        l10n.priceIsForFuel(label),
      semanticStatus,
      // #3949 — the 24 h flag left the visible chrome for the status dot's
      // tooltip; the row's own label keeps announcing it.
      if (station.is24h) l10n.open24h,
    ].join(', ');

    // #4091 — the accent is SEMANTIC now. It used to carry the selected
    // fuel's colour on every row, which meant every card in the list wore
    // the same stripe and the colour told the user nothing they had not
    // chosen themselves — twenty rows of decoration reading as twenty
    // rows of signal. Colour is spent only where it means something: the
    // cheapest row. Every other card gets the frame's own hairline.
    final stripeColor =
        isCheapest ? DarkModeColors.success(context) : null;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: StationCardShell(
        onTap: onTap,
        stripeColor: stripeColor,
        stripeWidth: isCheapest ? 6 : 4,
        separator: showSeparator,
        child: Padding(
          // #4091 — tighter vertically. The card's job in a list is to be
          // comparable with the five cards around it, and 8 dp above and
          // below every row cost a whole row of that comparison.
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.md,
            Spacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              StationCardHeadlineRow(
                station: station,
                presentation: p,
                isFavorite: isFavorite,
                isCheapest: isCheapest,
                priceTier: priceTier,
                onFavoriteTap: onFavoriteTap,
              ),
              const SizedBox(height: Spacing.xs),
              _TitleLine(text: p.title, rating: rating),
              // #4091 — where it is and how far, on one line. The full
              // postal address moved to the detail screen: nobody picks a
              // forecourt by its house number.
              StationCardPlaceLine(station: station),
              const SizedBox(height: Spacing.xs),
              StationCardMetaLine(
                station: station,
                semanticStatus: semanticStatus,
                isStalePrice: isStalePrice,
              ),
              StationCardHighwayExitLine(station: station),
              // #2899/#2984 — Fuel Station Radar closeness bar: the SAME
              // green→accent [ProximityFillBar] the trip radar card + PiP
              // overlay use. `station.dist` (km) → metres for the bar; it
              // scales to an ABSOLUTE fixed radius (`closenessRadiusMeters`
              // = min(searchRadius, cap)), so closer = fuller and a given
              // station's fill is stable across result-set changes.
              if (closenessRadiusMeters != null) ...[
                const SizedBox(height: Spacing.xs),
                ProximityFillBar(
                  distanceMeters: station.dist * 1000.0,
                  radiusMeters: closenessRadiusMeters,
                ),
              ],
              // #4091 — facilities are a tie-breaker, not a reason to
              // drive somewhere, so they get a tie-breaker's weight: one
              // line of label type instead of a wrap of bordered pills
              // that cost two rows on a phone.
              if (station.amenities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.xs),
                  child: AmenitySummary(amenities: station.amenities),
                ),
              if (selectedFuelType == FuelType.all && !isCheapest)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm),
                  child: StationCardAllFuelsRows(
                    station: station,
                    profileFuelType: profileFuelType,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title line: the station name in the title role, with the user's rating
/// stars (when any) at the trailing end so they cost no extra line.
class _TitleLine extends StatelessWidget {
  final String text;
  final int? rating;

  const _TitleLine({required this.text, required this.rating});

  @override
  Widget build(BuildContext context) {
    final rating = this.rating;
    final showRating = rating != null && rating >= 1 && rating <= 5;
    return Row(
      children: [
        Expanded(
          // #2161 — was a Hero flight to the detail-screen title; the
          // detail screen no longer animates it, so plain Text only.
          child: Text(
            text,
            style: AppText.title(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showRating) ...[
          const SizedBox(width: Spacing.md),
          StationCardRatingStars(rating: rating),
        ],
      ],
    );
  }
}
