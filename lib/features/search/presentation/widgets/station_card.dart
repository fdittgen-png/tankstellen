import 'package:flutter/material.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/price_tier.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/animated_favorite_star.dart';
import '../../../../core/widgets/animated_price_text.dart';
import '../../../../l10n/app_localizations.dart';
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
  bool get _hasBrand =>
      station.brand.isNotEmpty &&
      station.brand != 'Station' &&
      station.brand != 'Autoroute';

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
    final semanticStatus = station.isOpen ? 'Open' : 'Closed';
    final semanticLabel =
        '${_hasBrand ? station.brand : station.name}, ${station.street}, '
        '$formattedPrice, $semanticStatus';

    final fuelColor = FuelColors.forType(selectedFuelType);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        clipBehavior: Clip.antiAlias,
        elevation:
            Theme.of(context).brightness == Brightness.dark ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isCheapest
                      ? DarkModeColors.success(context)
                      : fuelColor,
                  width: isCheapest ? 6 : 4,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusColumn(station: station),
                const SizedBox(width: 12),
                Expanded(
                  child: _StationDetails(
                    station: station,
                    hasBrand: _hasBrand,
                  ),
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
      ),
    );
  }
}
