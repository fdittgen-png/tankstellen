// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Persistent cache of the ELM327 protocol number negotiated for a
/// given adapter + vehicle (#2261 concern 3).
///
/// The very first connect to a car runs `ATSP0` and lets the ELM327
/// auto-search every OBD protocol in turn — a multi-second probe on a
/// slow clone. The negotiated protocol is stable for the life of the
/// vehicle's ECU, so caching it and replaying `ATSP{n}` on warm
/// connects skips the search entirely.
///
/// Key is `adapterMac(:vin)`: rooted on the adapter MAC because two
/// adapters can negotiate differently on the same car (clone quirks),
/// refined with the VIN when one is known. The value is the bare ELM327
/// protocol digit (`1`–`9`, `A`–`C`) — the `ATDPN` reply with its
/// leading `A` auto-flag stripped.
///
/// The underlying box is the unencrypted `Box<String>` opened by
/// [HiveBoxes.initDeferred]. Tiny, not PII — mirrors the privacy
/// treatment of [SupportedPidsCache] and the other OBD2 boxes.
class NegotiatedProtocolCache {
  final Box<String> _box;

  NegotiatedProtocolCache(this._box);

  /// Build the lookup key from an adapter MAC and an optional VIN
  /// (#2261). Lower-cased so capitalisation never splits an entry.
  /// Returns null when even the MAC is unavailable (an unstamped
  /// service), at which point the caller skips the cache and keeps the
  /// ATSP0 cold-search.
  static String? keyFor({required String? adapterMac, String? vin}) {
    final mac = adapterMac?.trim().toLowerCase();
    if (mac == null || mac.isEmpty) return null;
    final v = vin?.trim().toLowerCase();
    if (v == null || v.isEmpty) return mac;
    return '$mac:$v';
  }

  /// The cached protocol digit for [key], or null when there's no entry.
  String? get(String key) {
    final raw = _box.get(key);
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// Persist the negotiated protocol [digit] under [key].
  Future<void> put(String key, String digit) async {
    final trimmed = digit.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    await _box.put(key, trimmed);
  }

  /// Forget the cached protocol for [key] — called when a warm
  /// `ATSP{n}` connect fails (UNABLE TO CONNECT / NO DATA), so the next
  /// connect re-runs the ATSP0 auto-search and re-caches a fresh value.
  Future<void> invalidate(String key) async {
    try {
      await _box.delete(key);
    } catch (e, st) {
      debugPrint('NegotiatedProtocolCache: invalidate("$key") failed: $e\n$st');
    }
  }

  /// Delete every cached protocol. Handy when the user switches cars.
  Future<void> clear() async {
    await _box.clear();
  }
}
