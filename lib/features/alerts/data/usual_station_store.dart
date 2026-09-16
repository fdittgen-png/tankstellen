// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/hive_boxes.dart';

/// The station the user actually fills up at (#4154).
///
/// A favourite is a bookmark; a *usual* station is semantic. It turns
/// "station X crossed a threshold" into "your usual station is unusually
/// cheap today", and lets the engine skip the ones someone bookmarked
/// and never visits.
///
/// **Confirmed, never assumed.** The candidate is derived from fill-up
/// history ([usualStationCandidate]) and only becomes the usual station
/// when the user says so: a wrong "usual" makes every finding about it
/// wrong.
@immutable
class UsualStation {
  const UsualStation({required this.stationId, this.stationName});

  final String stationId;
  final String? stationName;

  Map<String, dynamic> toJson() => {
        'stationId': stationId,
        if (stationName != null) 'stationName': stationName,
      };

  static UsualStation? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['stationId']?.toString();
    if (id == null || id.isEmpty) return null;
    return UsualStation(
        stationId: id, stationName: raw['stationName']?.toString());
  }
}

class UsualStationStore {
  const UsualStationStore();

  static const String storageKey = 'usual_station';

  Box<dynamic>? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.alerts)) return null;
      return Hive.box(HiveBoxes.alerts);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'UsualStationStore: alerts box unavailable',
      });
      return null;
    }
  }

  /// The confirmed usual station, or null when the user never set one.
  UsualStation? read() {
    final raw = _boxOrNull()?.get(storageKey);
    if (raw is! String || raw.isEmpty) return null;
    try {
      return UsualStation.fromJson(jsonDecode(raw));
    } on FormatException catch (e, st) {
      log.error(e, st, layer: ErrorLayer.storage, context: const {
        'where': 'UsualStationStore.read: malformed row',
      });
      return null;
    }
  }

  Future<void> write(UsualStation station) async {
    final box = _boxOrNull();
    if (box == null) {
      log.debug('write: alerts box closed, dropping ${station.stationId}',
          tag: 'UsualStationStore');
      return;
    }
    await box.put(storageKey, jsonEncode(station.toJson()));
  }

  Future<void> clear() async => _boxOrNull()?.delete(storageKey);
}
