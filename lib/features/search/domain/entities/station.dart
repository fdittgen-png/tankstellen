// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../station_detail/domain/opening_hours.dart';
import 'station_amenity.dart';

part 'station.freezed.dart';
part 'station.g.dart';

@freezed
abstract class Station with _$Station {
  const factory Station({
    required String id,
    required String name,
    required String brand,
    required String street,
    String? houseNumber,
    @JsonKey(fromJson: _postCodeToString) required String postCode,
    required String place,
    required double lat,
    required double lng,
    @Default(0) double dist,
    @JsonKey(fromJson: _priceFromJson) double? e5,
    @JsonKey(fromJson: _priceFromJson) double? e10,
    @JsonKey(fromJson: _priceFromJson) double? e98,
    @JsonKey(fromJson: _priceFromJson) double? diesel,
    @JsonKey(fromJson: _priceFromJson) double? dieselPremium,
    @JsonKey(fromJson: _priceFromJson) double? e85,
    @JsonKey(fromJson: _priceFromJson) double? lpg,
    @JsonKey(fromJson: _priceFromJson) double? cng,
    required bool isOpen,
    String? updatedAt,
    String? openingHoursText,  // "Lun 07:00-18:30, Mar 07:00-18:30..."
    // Epic C4 — structured weekly hours from a per-country
    // [OpeningHoursAdapter], carried on the search-result station so a
    // country whose service has no detail endpoint (e.g. AT E-Control)
    // still surfaces structured hours via `StationDetail(station:…)`.
    // ADDITIVE: `openingHoursText` / `is24h` stay for back-compat.
    //
    // #2777 — MUST serialize: the search-list cache codec
    // (serializeStationList/deserializeStationList) and the favorites/widget/
    // deep-link `station.toJson()` paths all round-trip through JSON. With the
    // field JSON-excluded, a cache-hit search (the dominant repeat path for the
    // polled FR/AT/CL sources) rehydrated stations with `openingHours == null`
    // and the detail fast path rendered empty hours. `WeeklyOpeningHours` has
    // to/fromJson; older cache entries lack the key → null, the same graceful
    // back-compat fallback the structured `StationDetail.openingHours` uses.
    WeeklyOpeningHours? openingHours,
    @Default(false) bool is24h,
    @Default([]) List<String> services,
    @Default([]) List<String> availableFuels,
    @Default([]) List<String> unavailableFuels,
    String? stationType,  // "R" retail, "A" autoroute
    String? department,
    String? region,
    @JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson)
    @Default({}) Set<StationAmenity> amenities,
  }) = _Station;

  factory Station.fromJson(Map<String, dynamic> json) =>
      _$StationFromJson(json);
}

/// Handles postCode as int from API → String in model.
String _postCodeToString(dynamic value) =>
    value.toString().padLeft(5, '0');

/// Handles price as num, false (closed station), or null → double?.
double? _priceFromJson(dynamic value) =>
    value is num ? value.toDouble() : null;

/// Deserializes amenities from JSON list of enum name strings.
Set<StationAmenity> _amenitiesFromJson(dynamic value) {
  if (value is! List) return const {};
  return value
      .map((e) {
        final name = e.toString();
        return StationAmenity.values.where((a) => a.name == name).firstOrNull;
      })
      .whereType<StationAmenity>()
      .toSet();
}

/// Serializes amenities to JSON list of enum name strings.
List<String> _amenitiesToJson(Set<StationAmenity> amenities) =>
    amenities.map((a) => a.name).toList();

@freezed
abstract class StationDetail with _$StationDetail {
  const factory StationDetail({
    required Station station,
    @Default([]) List<OpeningTime> openingTimes,
    @Default([]) List<String> overrides,
    @Default(false) bool wholeDay,
    String? state,
    // Epic C1 (#2708) — structured opening hours from a per-country
    // [OpeningHoursAdapter]. ADDITIVE: the legacy `Station.is24h` /
    // `openingHoursText` and this entity's `openingTimes` / `wholeDay` stay
    // for back-compat; until a country's adapter lands this is null and the
    // display layer falls back through `legacyOpeningHoursBridge`.
    WeeklyOpeningHours? openingHours,
  }) = _StationDetail;
}

@freezed
abstract class OpeningTime with _$OpeningTime {
  const factory OpeningTime({
    required String text,
    required String start,
    required String end,
  }) = _OpeningTime;

  factory OpeningTime.fromJson(Map<String, dynamic> json) =>
      _$OpeningTimeFromJson(json);
}
