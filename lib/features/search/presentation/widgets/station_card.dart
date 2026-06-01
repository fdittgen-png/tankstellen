// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/animated_favorite_star.dart';
import '../../../../core/widgets/animated_price_text.dart';
import '../../../../core/widgets/station_card_shell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../station_detail/presentation/widgets/station_brand_helpers.dart';
import '../../domain/entities/brand_registry.dart';
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';
import 'amenity_chips.dart';

part 'station_card_price_column.dart';
part 'station_card_price_row.dart';
part 'station_card_status.dart';

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
  /// When provided, small star icons are shown above the price area.
  final int? rating;

  /// The user's preferred fuel type from their profile.
  /// When [selectedFuelType] is [FuelType.all], the matching price row
  /// is rendered larger and with the fuel-type color to make it visually
  /// dominant.
  final FuelType? profileFuelType;

  /// Active loyalty/fuel-club discounts keyed by canonical brand
  /// string (#1120 pilot). When this station's brand canonicalizes to
  /// a key in the map and the per-litre discount is positive, the
  /// price column renders an effective price (raw − discount) plus a
  /// `−€0.05` badge. Stations whose brand isn't in the map render
  /// unchanged. Callers typically pass
  /// `ref.watch(activeDiscountByBrandProvider)` after collapsing to
  /// the canonical-brand string keys.
  final Map<String, double>? activeDiscountsByBrand;

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
  });

  /// True if the station has a real brand name (not empty, not generic "Station")
  /// Defers to the shared [hasRealBrand] helper so the search card and
  /// the detail screen agree on what counts as a brand (#2061). The
  /// helper excludes the legacy `'Station'` sentinel + the
  /// `BrandRegistry.independentLabel` (`'Independent'` from #482).
  /// `'Autoroute'` is a synthetic motorway tag, kept excluded here.
  bool get _hasBrand => hasRealBrand(station) && station.brand != 'Autoroute';

  double? get _displayPrice => station.priceFor(selectedFuelType);

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

  @override
  Widget build(BuildContext context) {
    final price = _displayPrice;
    final currencyOverride = _stationCurrency;
    final formattedPrice = PriceFormatter.formatPrice(
      price,
      currencyOverride: currencyOverride,
    );
    final l10n = AppLocalizations.of(context);
    final semanticStatus = station.isOpen
        ? (l10n?.open ?? 'Open')
        : (l10n?.closed ?? 'Closed');
    final semanticLabel =
        '${_hasBrand ? station.brand : station.name}, ${station.street}, '
        '$formattedPrice, $semanticStatus';

    final fuelColor = FuelColors.forType(selectedFuelType);
    // #2493 — the stripe (unlike the price-text tint) uses the visible
    // all-fuels colour so a `FuelType.all` card no longer shows the near-
    // invisible neutral grey. Cheapest still wins with the success stripe.
    final stripeColor = isCheapest
        ? DarkModeColors.success(context)
        : FuelColors.stripeColor(context, selectedFuelType);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: StationCardShell(
        onTap: onTap,
        stripeColor: stripeColor,
        stripeWidth: isCheapest ? 6 : 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusColumn(station: station),
              const SizedBox(width: 12),
              Expanded(
                child: _StationDetails(station: station, hasBrand: _hasBrand),
              ),
              const SizedBox(width: 8),
              _StationPriceColumn(
                station: station,
                selectedFuelType: selectedFuelType,
                price: price,
                currencyOverride: currencyOverride,
                fuelColor: fuelColor,
                isFavorite: isFavorite,
                isCheapest: isCheapest,
                priceTier: priceTier,
                rating: rating,
                profileFuelType: profileFuelType,
                loyaltyDiscount: _loyaltyDiscount,
                onFavoriteTap: onFavoriteTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
