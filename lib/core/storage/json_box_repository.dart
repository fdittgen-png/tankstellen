// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../logging/error_logger.dart';
import 'hive_boxes.dart';

/// Shared base for keyed-Hive-JSON repositories (#3614).
///
/// Several repositories persist one entity per Hive key as a
/// JSON-encoded string (loyalty cards, achievements, service
/// reminders). They all hand-rolled the same loop: iterate keys,
/// tolerant-decode each entry, skip-and-log corrupt payloads so a
/// single bad write never hides the whole list. This base extracts
/// that loop once.
///
/// Design notes:
///   - The box is held as `Box<dynamic>` so both `Box<String>` and
///     shared `Box<dynamic>` boxes (e.g. the settings box) fit; only
///     JSON strings are ever written.
///   - [entryKeyPrefix] scopes this repository's entries inside a
///     shared box (empty = the repository owns every String key).
///   - Decoding tolerates both JSON strings and raw `Map` payloads
///     (legacy writes), normalised via [HiveBoxes.toStringDynamicMap].
///   - [fromJson] may return `null` to signal "valid JSON but not a
///     usable entity" — such entries are skipped silently.
///   - Corrupt entries (throwing decode) are logged to [errorLogger]
///     under [ErrorLayer.storage] and skipped.
class JsonBoxRepository<T> {
  JsonBoxRepository({
    required this._box,
    required this._fromJson,
    required this._toJson,
    required this._keyOf,
    this.entryKeyPrefix = '',
    required this.debugName,
  });

  final Box<dynamic> _box;
  final T? Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T value) _toJson;
  final String Function(T value) _keyOf;

  /// Prefix that scopes this repository's keys inside a shared box.
  final String entryKeyPrefix;

  /// Identifier used in error-log context (`'<debugName>.getAll'`).
  final String debugName;

  /// The underlying box, for subclass operations the base doesn't
  /// cover (bulk deletes, containsKey checks, full clears).
  @protected
  Box<dynamic> get box => _box;

  /// Every String key in the box that belongs to this repository.
  @protected
  Iterable<String> get storedKeys =>
      _box.keys.whereType<String>().where((k) => k.startsWith(entryKeyPrefix));

  /// Decode every stored entry, skipping (and logging) corrupt ones.
  /// Order follows the box's key order; subclasses sort as needed.
  List<T> getAll() {
    final out = <T>[];
    for (final key in storedKeys) {
      final value = _decodeEntry(key, _box.get(key));
      if (value != null) out.add(value);
    }
    return out;
  }

  /// Decode the entry stored under (prefixed) [key], or `null` when
  /// absent or corrupt (corruption is logged).
  T? getByKey(String key) {
    final fullKey = '$entryKeyPrefix$key';
    return _decodeEntry(fullKey, _box.get(fullKey));
  }

  /// Insert or overwrite [value] under its (prefixed) key.
  /// Failures propagate — callers own their error contract.
  Future<void> put(T value) =>
      _box.put('$entryKeyPrefix${_keyOf(value)}', jsonEncode(_toJson(value)));

  /// Delete the entry stored under (prefixed) [key]. No-op when absent.
  Future<void> deleteByKey(String key) => _box.delete('$entryKeyPrefix$key');

  /// Delete every entry belonging to this repository, leaving
  /// unrelated keys in a shared box untouched.
  Future<void> clearStored() async {
    final victims = storedKeys.toList();
    if (victims.isNotEmpty) {
      await _box.deleteAll(victims);
    }
  }

  T? _decodeEntry(String key, dynamic raw) {
    if (raw == null) return null;
    try {
      final json = _asJsonMap(raw);
      if (json == null) return null;
      return _fromJson(json);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
        'where': '$debugName.decode: skipping entry',
        'key': key,
      }));
      return null;
    }
  }

  static Map<String, dynamic>? _asJsonMap(dynamic raw) {
    if (raw is String) {
      if (raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return HiveBoxes.toStringDynamicMap(decoded);
      return null;
    }
    if (raw is Map) return HiveBoxes.toStringDynamicMap(raw);
    return null;
  }
}
