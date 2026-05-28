// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'elm327_protocol.dart';
import 'supported_pids_cache.dart';
import '../../../../core/logging/error_logger.dart';

/// Owns the #811 supported-PID concern, extracted from [Obd2Service]
/// (#1679): the per-connection set of Mode 01 PIDs the car implements,
/// the persistent cache that lets [prime] skip the 8 × `01 XX` bitmap
/// scan, and the vehicle-key resolution that picks the cache slot.
///
/// The collaborator talks to the adapter through an injected
/// [send] closure (the host's `_send`, which applies the active
/// [Elm327Adapter.preParse] hook) and an [isConnected] predicate, so
/// it carries no transport dependency of its own.
class SupportedPidsResolver {
  SupportedPidsResolver({
    required Future<String> Function(String command) send,
    required bool Function() isConnected,
    SupportedPidsCache? cache,
    String? vehicleFallbackKey,
  })  : _send = send,
        _isConnected = isConnected,
        _cache = cache,
        _vehicleFallbackKey = vehicleFallbackKey;

  final Future<String> Function(String command) _send;
  final bool Function() _isConnected;

  /// Optional persistent supported-PID cache (#811). When present and
  /// a VIN (or [_vehicleFallbackKey]) resolves to a cached entry,
  /// [prime] skips the 8 × `01 XX` bitmap scan entirely.
  final SupportedPidsCache? _cache;

  /// Fallback cache key for when the car doesn't return a VIN (old
  /// ECUs / incompatible adapters). Typically `'${make}:${model}:${year}'`.
  final String? _vehicleFallbackKey;

  /// Per-connection cache of the Mode 01 PIDs the car supports,
  /// populated by [discoverSupportedPids] or reloaded from [_cache]
  /// during [prime]. `null` means "we haven't asked the car yet, so
  /// don't trust this cache to reject PIDs" (see [isPidSupported]).
  Set<int>? _supportedPids;

  /// Clear the per-connection supported-PIDs cache. A new session may
  /// be a different car / different adapter firmware. Call at the top
  /// of the host's `connect`.
  void resetForNewConnection() {
    _supportedPids = null;
  }

  /// Attempt to load the supported-PID set from the persistent cache
  /// (#811). Silent no-op when no cache was injected. Always swallows
  /// errors: a broken cache must not break the connect flow — worst
  /// case we fall back to blind querying, which is exactly what the
  /// adapter did before this feature landed.
  Future<void> prime() async {
    final cache = _cache;
    if (cache == null) return;
    try {
      final key = await _resolveVehicleCacheKey();
      if (key == null) {
        debugPrint(
            'OBD2 supported-PID cache: no VIN and no fallback key — '
            'scanning blindly this session');
        return;
      }
      final cached = cache.get(key);
      if (cached != null) {
        _supportedPids = cached;
        debugPrint(
            'OBD2 supported-PID cache HIT for "$key" '
            '(${cached.length} PIDs) — skipping scan');
        return;
      }
      debugPrint('OBD2 supported-PID cache MISS for "$key" — scanning');
      final discovered = await discoverSupportedPids();
      if (discovered.isNotEmpty) {
        await cache.put(key, discovered);
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'OBD2 supported-PID cache prime failed'}));
    }
  }

  /// Resolve the cache key for the currently-connected vehicle.
  /// Prefers the VIN; falls back to the static [_vehicleFallbackKey]
  /// provided at construction time. Returns null when neither is
  /// available, at which point the cache is skipped this session.
  Future<String?> _resolveVehicleCacheKey() async {
    try {
      final response = await _send(Elm327Protocol.vinCommand);
      final vin = Elm327Protocol.parseVin(response);
      if (vin != null && vin.isNotEmpty) return vin;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'OBD2 VIN read for cache key failed'}));
    }
    return _vehicleFallbackKey;
  }

  /// Ask the adapter which Mode 01 PIDs the vehicle supports (#811).
  ///
  /// Walks the standard supported-PIDs chain: `01 00` returns a
  /// bitmap for PIDs 01–20, and bit-32 of that bitmap is set iff PIDs
  /// 21–40 are also addressable — querying `01 20` in turn returns
  /// that range, and so on up to `01 C0`. We stop as soon as a
  /// bitmap's "next-range supported" flag is clear or the query
  /// returns NO DATA.
  ///
  /// Returns an empty set when the adapter isn't connected or the
  /// first bitmap can't be read — the caller should fall back to
  /// blind querying. Also populates the internal per-connection
  /// cache so subsequent [isPidSupported] calls short-circuit.
  Future<Set<int>> discoverSupportedPids() async {
    if (!_isConnected()) return const <int>{};
    final supported = <int>{};
    for (final command in Elm327Protocol.supportedPidsCommands) {
      // Derive the 32-PID group base from the command (e.g. "0140\r"
      // → 0x40). The commands list is in lockstep with the group
      // bases, so we just hex-parse the middle two chars.
      final groupBase = int.parse(command.substring(2, 4), radix: 16);
      try {
        final response = await _send(command);
        final bitmap =
            Elm327Protocol.parseSupportedPidsBitmap(response, groupBase);
        if (bitmap == null) break;
        supported.addAll(bitmap);
        // "Bit 32" of the bitmap — i.e. PID (groupBase + 32) — is
        // conventionally the "are PIDs in the next range supported?"
        // flag. If it's not in the set we just parsed, stop walking.
        final nextRangeFlag = groupBase + 32;
        if (!bitmap.contains(nextRangeFlag)) break;
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {'where': 'OBD2 discoverSupportedPids failed on $command'}));
        break;
      }
    }
    _supportedPids = supported;
    return supported;
  }

  /// Whether [pid] is known to be supported by the connected vehicle
  /// (#811). Key semantics:
  ///
  ///   - When discovery has NOT run yet (cache is null), returns
  ///     `true` — we don't know enough to reject the query, so let it
  ///     go through and surface NO DATA naturally.
  ///   - When the cache IS populated and [pid] is present → `true`.
  ///   - When the cache IS populated and [pid] is absent → `false`.
  bool isPidSupported(int pid) =>
      _supportedPids == null || _supportedPids!.contains(pid);

  /// Alias for [isPidSupported] — matches the name used in the #811
  /// issue.
  bool supportsPid(int pid) => isPidSupported(pid);

  /// Direct view of the supported-PID set for tests and diagnostics.
  /// Returns an unmodifiable empty set when discovery hasn't run.
  Set<int> get debugSupportedPids => Set.unmodifiable(_supportedPids ?? {});
}
