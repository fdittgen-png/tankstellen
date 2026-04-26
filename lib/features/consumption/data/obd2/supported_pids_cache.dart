import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Persistent cache of Mode 01 supported-PID bitmaps, keyed per
/// vehicle (#811).
///
/// Every serious OSS OBD project (python-OBD, Car Scanner) runs Service
/// 01 PID 00 / 20 / 40 / 60 / 80 / A0 / C0 on first connect to figure
/// out which PIDs the ECU implements, then caches the result so future
/// sessions can skip the eight extra round-trips over a slow Bluetooth
/// pipe. Tankstellen does the same thing here.
///
/// Preferred key is the VIN — globally unique per vehicle and stable
/// for the life of the car. When the car doesn't answer Mode 09 PID 02
/// (older ECUs, some adapters) the fallback key is
/// `'${make}:${model}:${year}'`. Less precise but still better than
/// re-scanning every connect.
///
/// The underlying box is the unencrypted `Box<String>` opened by
/// [HiveBoxes.init]. Values are JSON-encoded `List<int>` of PID
/// indices — mirrors the idiom used by baselines and trip history
/// (also `Box<String>` + JSON) and sidesteps Hive type-adapter
/// registration entirely.
class SupportedPidsCache {
  final Box<String> _box;

  SupportedPidsCache(this._box);

  /// Build a composite cache key from a make, model, and year triple.
  /// Lower-cased so minor capitalisation mismatches (e.g. "Peugeot"
  /// vs "PEUGEOT") still share a cache entry.
  static String fallbackKey({
    required String make,
    required String model,
    required int year,
  }) {
    return '${make.trim().toLowerCase()}:'
        '${model.trim().toLowerCase()}:'
        '$year';
  }

  /// Look up the cached supported-PID set for [key], or null when
  /// there's no entry / the entry is corrupt.
  Set<int>? get(String key) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) {
        debugPrint(
            'SupportedPidsCache: non-list entry at "$key" — ignoring cache');
        return null;
      }
      final pids = <int>{};
      for (final v in decoded) {
        if (v is int) {
          pids.add(v);
        } else if (v is num) {
          pids.add(v.toInt());
        }
      }
      return pids;
    } catch (e, st) {
      debugPrint('SupportedPidsCache: corrupt JSON at "$key": $e\n$st');
      return null;
    }
  }

  /// Persist [pids] under [key]. Stored as a sorted JSON list so
  /// debug inspection of the Hive file surfaces a deterministic
  /// layout.
  Future<void> put(String key, Set<int> pids) async {
    final sorted = pids.toList()..sort();
    await _box.put(key, json.encode(sorted));
  }

  /// Delete every cache entry. Handy when a user switches cars or
  /// wants to re-scan the connected ECU from scratch.
  Future<void> clear() async {
    await _box.clear();
  }
}
