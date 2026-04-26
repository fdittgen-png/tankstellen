import 'package:freezed_annotation/freezed_annotation.dart';

part 'refuel_price.freezed.dart';

/// Unit of a [RefuelPrice]. Fuel and EV are normalized to the same
/// shape (numeric value + unit tag) so the unified search list can
/// render them with one formatter switch.
enum RefuelPriceUnit {
  /// Cents per liter — the canonical fuel-pump unit across Europe.
  centsPerLiter,

  /// Cents per kWh — the canonical EV unit. Some networks bill flat
  /// per session instead, see [perSession].
  centsPerKwh,

  /// Flat per-session price (some EV networks bill this way). The
  /// numeric [RefuelPrice.value] is then the whole-session cost in
  /// cents, not a per-unit rate.
  perSession,
}

/// Best-known current price for a refueling option.
///
/// Phase 1 of the fuel/EV unification (#1116). The value is stored in
/// the lowest unit (cents) regardless of currency — display layers
/// already format prices country-by-country, so a numeric scalar plus
/// a [unit] tag is all the data layer needs to expose.
///
/// [lastUpdated] is `null` when the upstream API doesn't supply a
/// timestamp (some EV networks). UI may then fall back to the
/// surrounding [ServiceResult.fetchedAt] value.
@freezed
abstract class RefuelPrice with _$RefuelPrice {
  const factory RefuelPrice({
    /// Numeric price in the lowest currency unit (e.g. cents).
    required double value,

    /// What [value] is per — liter, kWh, or whole session.
    required RefuelPriceUnit unit,

    /// When the upstream API last refreshed this price, if known.
    DateTime? lastUpdated,
  }) = _RefuelPrice;
}
