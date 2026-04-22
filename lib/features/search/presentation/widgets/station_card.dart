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
import '../../domain/entities/fuel_type.dart';
import '../../domain/entities/station.dart';
import 'amenity_chips.dart';

part 'station_card_parts.dart';

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
  });

  /// True if the station has a real brand name (not empty, not generic "Station")
  bool get _hasBrand =>
      station.brand.isNotEmpty &&
      station.brand != 'Station' &&
      station.brand != 'Autoroute';

  double? get _displayPrice => station.priceFor(selectedFuelType);

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
