// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../core/logging/error_logger.dart';
import '../../features/search/domain/entities/station.dart';
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
  } on FormatException catch (e, st) {
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
    };

StationDetail? deserializeStationDetail(Map<String, dynamic> data) {
  try {
    final stationJson = data['station'] as Map<String, dynamic>?;
    if (stationJson == null) return null;

    final otList = data['openingTimes'] as List<dynamic>? ?? [];
    return StationDetail(
      station: Station.fromJson(stationJson),
      openingTimes: otList
          .map((j) => OpeningTime.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList(),
      overrides: List<String>.from(data['overrides'] as List? ?? []),
      wholeDay: data['wholeDay'] as bool? ?? false,
      state: data['state'] as String?,
    );
  } on FormatException catch (e, st) {
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
  } on FormatException catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.other, e, st,
        context: const {'where': 'Cache: prices parse failed'}));
    return null;
  }
}
