// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../core/logging/error_logger.dart';
import '../domain/station.dart';
import '../domain/opening_hours.dart';
import 'station_service.dart';

/// JSON-safe (de)serialization helpers for the [StationServiceChain] cache
/// envelopes. Extracted from `station_service_chain.dart` (#2264) to keep the
/// chain itself under the file-length norm; these are pure, stateless codecs
/// so they live cleanest as top-level functions.

Map<String, dynamic> serializeStationList(List<Station> stations) => {
      'stations': stations.map((s) => s.toJson()).toList(),
    };

List<Station>? deserializeStationList(Map<String, dynamic> data) {
  try {
    final list = data['stations'] as List<dynamic>?;
    if (list == null) return null;
    return list
        .map((j) => Station.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
    // #2296 — catch Object, not just FormatException: a `j as Map` cast on
    // a corrupted or older-schema Hive entry throws a TypeError (an Error,
    // not an Exception), which would otherwise escape the catch, propagate
    // through _executeChain (no surrounding try/catch at the call sites) and
    // crash the UI — bypassing the stale-cache fallback. Treat any corrupt
    // entry as a cache miss (return null) + log.
  } on Object catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.other, e, st,
        context: const {'where': 'Cache: station list parse failed'}));
    return null;
  }
}

Map<String, dynamic> serializeStationDetail(StationDetail detail) => {
      'station': detail.station.toJson(),
      'openingTimes': detail.openingTimes.map((ot) => ot.toJson()).toList(),
      'overrides': detail.overrides,
      'wholeDay': detail.wholeDay,
      'state': detail.state,
      // #2708 — round-trip the structured opening hours (null when no
      // adapter has run yet; the legacy fields above carry the fallback).
      'openingHours': detail.openingHours?.toJson(),
    };

StationDetail? deserializeStationDetail(Map<String, dynamic> data) {
  try {
    final stationJson = data['station'] as Map<String, dynamic>?;
    if (stationJson == null) return null;

    final otList = data['openingTimes'] as List<dynamic>? ?? [];
    final ohJson = data['openingHours'];
    return StationDetail(
      station: Station.fromJson(stationJson),
      openingTimes: otList
          .map((j) => OpeningTime.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList(),
      overrides: List<String>.from(data['overrides'] as List? ?? []),
      wholeDay: data['wholeDay'] as bool? ?? false,
      state: data['state'] as String?,
      // #2708 — older cache entries (pre-field) have no key → null, which
      // round-trips cleanly to the back-compat legacy fallback.
      openingHours: ohJson is Map
          ? WeeklyOpeningHours.fromJson(Map<String, dynamic>.from(ohJson))
          : null,
    );
    // #2296 — catch Object (TypeError from a bad cast on a corrupt /
    // older-schema entry is an Error, not an Exception) so a corrupt cache
    // entry is treated as a miss, not a UI crash that bypasses the
    // stale-cache fallback.
  } on Object catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.other, e, st,
        context: const {'where': 'Cache: station detail parse failed'}));
    return null;
  }
}

Map<String, dynamic> serializePrices(Map<String, StationPrices> prices) => {
      'prices': prices.map((k, v) => MapEntry(k, v.toJson())),
    };

Map<String, StationPrices>? deserializePrices(Map<String, dynamic> data) {
  try {
    final raw = data['prices'] as Map<String, dynamic>?;
    if (raw == null) return null;
    return raw.map(
      (k, v) =>
          MapEntry(k, StationPrices.fromJson(Map<String, dynamic>.from(v as Map))),
    );
    // #2296 — catch Object (a `v as Map` cast on a corrupt / older-schema
    // entry throws a TypeError, an Error not an Exception) so the corrupt
    // entry becomes a cache miss instead of crashing the UI past the
    // stale-cache fallback.
  } on Object catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.other, e, st,
        context: const {'where': 'Cache: prices parse failed'}));
    return null;
  }
}
