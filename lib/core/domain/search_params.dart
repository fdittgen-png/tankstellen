// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';
import 'fuel_type.dart';
// Re-export SearchMode so existing data-layer callers keep working while
// presentation imports it straight from domain/.
export 'search_mode.dart';

part 'search_params.freezed.dart';

@freezed
abstract class SearchParams with _$SearchParams {
  const factory SearchParams({
    required double lat,
    required double lng,
    @Default(10.0) double radiusKm,
    @Default(FuelType.all) FuelType fuelType,
    @Default(SortBy.price) SortBy sortBy,
    String? postalCode,
    String? locationName,
    // #2926 follow-up — the SHARED hard-fuel-filter (StationServiceChain →
    // filterByFuel) applies to the main search + radar so a specific fuel
    // shows ONLY forecourts selling it. The cross-border route corridor opts
    // OUT (applyFuelFilter:false) because it does its own per-country pricing
    // with the E5↔E10 sibling fallback (#2641/#2680) — a country that sells
    // only E5 must still be priced for an E10 request, which a hard E10 drop
    // here would break.
    @Default(true) bool applyFuelFilter,
  }) = _SearchParams;
}

enum SortBy {
  price('price', 'Price'),
  distance('dist', 'Distance');

  final String apiValue;
  final String displayName;

  const SortBy(this.apiValue, this.displayName);
}

