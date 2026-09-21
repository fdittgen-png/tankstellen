// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/domain/brand_appearance.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../station_detail/presentation/widgets/station_brand_helpers.dart';
import '../../../../core/domain/brand_registry.dart';

/// Everything a station row shows, derived once (#4133, Epic #4132).
///
/// ## Why this exists
///
/// The same station is rendered by the search list, the route list, the
/// favourites list, the map marker and the map sheet, and each used to
/// re-derive what to show: which price, after which loyalty discount, in
/// which currency, under which brand fallback, and whether the fuel
/// beside it is the one that was asked for.
///
/// That is how #4124 happened. The substituted-fuel label had a caller
/// once, lost it in a refactor, and no other surface noticed for months —
/// the docstring on `shortFuelLabel` still named a caller that no longer
/// existed. #4125 was the same shape in a different place: the
/// best-stops rule existed byte-for-byte in two features and the two
/// counts drifted.
///
/// One derivation, one set of rules, one place to fix them.
///
/// ## What it is not
///
/// Not a domain model. It holds localized, ready-to-render values and is
/// allowed to — that is the difference between this and
/// `core/domain/refuel_economics.dart`, which is pure arithmetic over
/// primitives precisely so it can be reasoned about without a UI.
@immutable
class StationPresentation {
  const StationPresentation({
    required this.title,
    required this.hasBrand,
    required this.brandMark,
    required this.price,
    required this.rawPrice,
    required this.loyaltyDiscount,
    required this.currencySymbol,
    required this.substitutedFuelLabel,
    required this.countryCode,
  });

  /// Brand → name → the localized "unbranded station" label (#2926).
  ///
  /// The raw street is NEVER the title: it is the address line below, so
  /// promoting it read as a broken duplicate ("26 AVENUE DE VERDUN" as a
  /// station name, repeated on the next line).
  final String title;

  /// Whether [title] came from a real brand — not empty, not the legacy
  /// `'Station'` sentinel, not `'Independent'` (#482), not the synthetic
  /// `'Autoroute'` motorway tag (#2061).
  final bool hasBrand;

  /// The offline brand mark (#3931), or null for an unrecognised brand.
  ///
  /// Deliberately absent rather than neutral: a column of identical grey
  /// pump boxes is noise, and the row already names the station.
  final BrandAppearance? brandMark;

  /// The price to show — after [loyaltyDiscount], floored at 0.001 so a
  /// hand-edited dump can never render as negative.
  final double? price;

  /// The price before any discount, for the #1120 tooltip. Equal to
  /// [price] when no discount applies.
  final double? rawPrice;

  /// Per-litre loyalty discount that applied, or null (#1120 pilot).
  final double? loyaltyDiscount;

  /// Per-station currency from its origin country (#514 / #516), or null
  /// when the country does not resolve — the caller then falls back to
  /// the active profile's currency.
  final String? currencySymbol;

  /// #4124 — the pump code to render beside the price when the price is
  /// NOT the fuel the user asked for, else null.
  final String? substitutedFuelLabel;

  /// Resolved country code, or null. Exposed because callers that already
  /// have a presentation should not resolve it a second time — the
  /// bounding-box match is the expensive part of building this.
  final String? countryCode;

  /// True when a discount actually changed the number shown.
  bool get hasDiscount =>
      loyaltyDiscount != null && loyaltyDiscount! > 0 && rawPrice != null;

  /// Derive everything from the station and the caller's context.
  ///
  /// [selectedFuelType] is the fuel this row is PRICED BY;
  /// [requestedFuelType] is what the user asked for, and is non-null only
  /// where the two can differ (the cross-border route list prices each
  /// station by its own country's profile fuel — #2631).
  ///
  /// [activeDiscountsByBrand] is keyed by canonical brand string, so the
  /// caller never has to know the raw API brand spellings.
  factory StationPresentation.of(
    Station station, {
    required FuelType selectedFuelType,
    required AppLocalizations l10n,
    FuelType? requestedFuelType,
    Map<String, double>? activeDiscountsByBrand,
  }) {
    final hasBrand =
        hasRealBrand(station) && station.brand != 'Autoroute';
    final country = Countries.countryForStation(
      id: station.id,
      lat: station.lat,
      lng: station.lng,
    );
    final raw = station.priceFor(selectedFuelType);
    final discount = _discountFor(station, activeDiscountsByBrand);

    return StationPresentation(
      title: hasBrand
          ? station.brand
          : (station.name.isNotEmpty
              ? station.name
              : l10n.stationUnbrandedTitle),
      hasBrand: hasBrand,
      brandMark: hasBrand ? BrandAppearance.of(station.brand) : null,
      price: _effective(raw, discount),
      rawPrice: raw,
      loyaltyDiscount: discount,
      currencySymbol: country?.currencySymbol,
      countryCode: country?.code,
      substitutedFuelLabel: _substitutedLabel(
        selected: selectedFuelType,
        requested: requestedFuelType,
        hasPrice: raw != null,
        countryCode: country?.code,
      ),
    );
  }

  /// Effective price after [discount], floored at 0.001.
  static double? _effective(double? raw, double? discount) {
    if (raw == null) return null;
    if (discount == null || discount <= 0) return raw;
    final effective = raw - discount;
    return effective < 0.001 ? 0.001 : effective;
  }

  static double? _discountFor(
    Station station,
    Map<String, double>? discounts,
  ) {
    if (discounts == null || discounts.isEmpty) return null;
    final canonical = BrandRegistry.canonicalize(station.brand);
    if (canonical == null) return null;
    final discount = discounts[canonical];
    if (discount == null || discount <= 0) return null;
    return discount;
  }

  /// #4124 — name the fuel only when it is NOT the one asked for.
  ///
  /// The wildcard is excluded on purpose: a user who asked for "any fuel"
  /// already expects whatever the forecourt sells, so every row would
  /// wear a label and none of them would mean anything. A row with no
  /// price is excluded too — there is no number to qualify.
  static String? _substitutedLabel({
    required FuelType selected,
    required FuelType? requested,
    required bool hasPrice,
    required String? countryCode,
  }) {
    if (requested == null || requested == selected) return null;
    if (requested == FuelType.all) return null;
    if (!hasPrice) return null;
    // #2717 — the station's own country names the grade (MX reads
    // "Magna", not a grade nobody there uses).
    return fuelDisplayLabel(selected, countryCode: countryCode);
  }
}
