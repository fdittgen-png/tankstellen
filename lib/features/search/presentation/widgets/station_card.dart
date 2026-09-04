// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/domain/brand_appearance.dart';
import '../../../../core/widgets/animated_favorite_star.dart';
import '../../../../core/widgets/animated_price_text.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/widgets/station_card_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../trips/api.dart';
import '../../../station_detail/presentation/widgets/station_brand_helpers.dart';
import '../../domain/entities/brand_registry.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import 'amenity_chips.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/road_distance_provider.dart';
import '../../../../core/services/radar/motorway_exits_provider.dart';
import '../../../../core/utils/unit_formatter.dart';

part 'station_card_badges.dart';
part 'station_card_price_column.dart';
part 'station_card_price_row.dart';
part 'station_card_status.dart';

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
    this.activeDiscountsByBrand,
    this.closenessRadiusMeters,
    this.isStalePrice = false,
  });

  /// True if the station has a real brand name (not empty, not generic "Station")
  /// Defers to the shared [hasRealBrand] helper so the search card and
  /// the detail screen agree on what counts as a brand (#2061). The
  /// helper excludes the legacy `'Station'` sentinel + the
  /// `BrandRegistry.independentLabel` (`'Independent'` from #482).
  /// `'Autoroute'` is a synthetic motorway tag, kept excluded here.
  bool get _hasBrand => hasRealBrand(station) && station.brand != 'Autoroute';

  double? get _displayPrice => station.priceFor(selectedFuelType);

  /// The offline brand mark for this row (#3931), or `null` when the
  /// station has no recognised brand.
  ///
  /// Deliberately absent rather than neutral for an unknown brand: a
  /// column of identical grey pump boxes down a result list is noise,
  /// and the row already names the station. The mark only appears where
  /// it carries information — the colour the driver recognises from the
  /// forecourt sign.
  BrandAppearance? get _brandMark =>
      _hasBrand ? BrandAppearance.of(station.brand) : null;

  /// Resolve the per-litre loyalty discount that applies to this
  /// station, or `null` if no card matches (#1120 pilot). The lookup
  /// is canonical-brand → discount, so the caller doesn't have to
  /// know about the raw API brand strings.
  double? get _loyaltyDiscount {
    final discounts = activeDiscountsByBrand;
    if (discounts == null || discounts.isEmpty) return null;
    final canonical = BrandRegistry.canonicalize(station.brand);
    if (canonical == null) return null;
    final discount = discounts[canonical];
    if (discount == null || discount <= 0) return null;
    return discount;
  }

  /// Per-station currency symbol derived from the station's origin
  /// country (#514 / #516). The resolution order is:
  ///
  /// 1. Id prefix (`uk-`, `pt-`, `mx-`, …) for services that tag
  ///    their ids with a country code.
  /// 2. Bounding-box match on `lat` / `lng` — catches raw upstream
  ///    ids (DE Tankerkoenig UUIDs, FR Prix-Carburants numeric ids,
  ///    AT E-Control, ES MITECO, IT MISE) and repairs legacy
  ///    favorites saved before the prefix scheme existed.
  ///
  /// Returns `null` when neither path resolves — the caller falls
  /// back to the globally-set active profile currency.
  String? get _stationCurrency => Countries.countryForStation(
    id: station.id,
    lat: station.lat,
    lng: station.lng,
  )?.currencySymbol;

  /// #2926 — title fallback brand → name → localized "Unbranded station".
  /// The raw street is NEVER the title: it is the address line below, so
  /// promoting it to the title read as a broken duplicate (e.g. "26 AVENUE DE
  /// VERDUN" shown as the station "name", repeated on the next line). An
  /// unbranded forecourt that carries a real name (e.g. a Mexican CRE company
  /// name) still shows that name; one with no brand AND no name gets the
  /// localized label, and the street drops to the address line instead.
  String _titleText(AppLocalizations l10n) {
    if (_hasBrand) return station.brand;
    if (station.name.isNotEmpty) return station.name;
    return l10n.stationUnbrandedTitle;
  }

  @override
  Widget build(BuildContext context) {
    final price = _displayPrice;
    final currencyOverride = _stationCurrency;
    final formattedPrice = PriceFormatter.formatPrice(
      price,
      currencyOverride: currencyOverride,
    );
    final l10n = AppLocalizations.of(context);
    // #3198 — tri-state: an unknown open state is announced as unknown,
    // never as closed (and never as open).
    final semanticStatus = switch (station.isOpen) {
      true => l10n.open,
      false => l10n.closed,
      null => l10n.openStateUnknown,
    };
    final semanticLabel = <String>[
      _hasBrand ? station.brand : station.name,
      station.street,
      formattedPrice,
      semanticStatus,
      // #3949 — the 24 h flag left the visible chrome for the status dot's
      // tooltip; the row's own label keeps announcing it.
      if (station.is24h) l10n.open24h,
    ].join(', ');

    // #2493 — the stripe (unlike the price-text tint) uses the visible
    // all-fuels colour so a `FuelType.all` card no longer shows the near-
    // invisible neutral grey. Cheapest still wins with the success stripe.
    final stripeColor = isCheapest
        ? DarkModeColors.success(context)
        : FuelColors.stripeColor(context, selectedFuelType);
    final titleText = _titleText(l10n);
    // The street is shown on the address line whenever it is NOT the title
    // — for a branded station, and for the unbranded-label case.
    final showStreetInAddress = _hasBrand || station.name.isEmpty;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: StationCardShell(
        onTap: onTap,
        stripeColor: stripeColor,
        stripeWidth: isCheapest ? 6 : 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.md,
            Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeadlineRow(
                station: station,
                brandMark: _brandMark,
                price: price,
                currencyOverride: currencyOverride,
                isFavorite: isFavorite,
                isCheapest: isCheapest,
                priceTier: priceTier,
                loyaltyDiscount: _loyaltyDiscount,
                onFavoriteTap: onFavoriteTap,
              ),
              const SizedBox(height: Spacing.xs),
              _TitleLine(text: titleText, rating: rating),
              Text(
                _addressLine(station, showStreetInAddress),
                style: AppText.body(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.xs),
              _MetaLine(
                station: station,
                semanticStatus: semanticStatus,
                isStalePrice: isStalePrice,
              ),
              _HighwayExitLine(station: station),
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
              if (station.amenities.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.xs),
                  child: AmenityChips(amenities: station.amenities),
                ),
              if (selectedFuelType == FuelType.all && !isCheapest)
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm),
                  child: _AllFuelsRows(
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
          _RatingStars(rating: rating),
        ],
      ],
    );
  }
}
