// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'elm327_protocol.dart';
import 'obd2_comm_diagnostics.dart';
import 'supported_pids_cache.dart';

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
  ///
  /// HIT-skip-0902 (#2253): production keys the cache off
  /// `adapterMac(+make:model:year)` via [_vehicleFallbackKey], which
  /// needs no VIN to compute. So before paying a multi-frame Mode 09
  /// PID 02 read just to derive a lookup key, [prime] probes the cache
  /// with the static fallback key first. On a HIT it loads the cached
  /// bitmap and returns — no 0902, no `01 XX` scan. Only on a miss (or
  /// when no fallback key was supplied) does it fall through to the
  /// precise, VIN-first resolution that older VIN-keyed entries use.
  Future<void> prime() async {
    final cache = _cache;
    if (cache == null) return;
    try {
      // 1. VIN-free fast path (#2253): probe the static fallback key.
      //    A HIT here means we never touch 0902 nor the 8 × 01 XX scan
      //    this session — the whole point of keying off adapterMac +
      //    make:model:year rather than the VIN.
      final fallbackKey = _vehicleFallbackKey;
      if (fallbackKey != null) {
        final cachedByFallback = cache.get(fallbackKey);
        if (cachedByFallback != null) {
          _supportedPids = cachedByFallback;
          debugPrint(
              'OBD2 supported-PID cache HIT for fallback key "$fallbackKey" '
              '(${cachedByFallback.length} PIDs) — skipping 0902 + scan');
          return;
        }
      }
      // 2. Miss (or no fallback key): resolve the precise key. This
      //    reads the VIN (0902) and falls back to [_vehicleFallbackKey]
      //    when the car returns none.
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
    } catch (_) {
      // #2424 (follow-up to #2379) — prime() is best-effort: a transient
      // on a flaky/slow ELM327 (TimeoutException, the legacy concurrent-
      // sendCommand StateError, device-not-connected) is EXPECTED and
      // recoverable — the method just returns and the session falls back
      // to blind querying. The graceful degradation IS the signal, so it
      // must NOT pollute the user error log.
      debugPrint('OBD2 supported-PID cache prime failed — '
          'scanning blindly this session');
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
    } catch (_) {
      // #2424 (follow-up to #2379) — the VIN (0902) probe is best-effort:
      // an engine-off / slow ELM327 times this out routinely, and many
      // old ECUs / clone adapters never answer it. That's EXPECTED and
      // recoverable — we fall back to [_vehicleFallbackKey] below, so a
      // transient here must NOT pollute the user error log.
      debugPrint('OBD2 VIN read for cache key failed — using fallback key');
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
      } catch (_) {
        // #2424 (follow-up to #2379) — the supported-PID scan is best-
        // effort: a transient on a flaky/slow ELM327 (TimeoutException,
        // the legacy concurrent-sendCommand StateError, device-not-
        // connected) is EXPECTED and recoverable — we break and return
        // whatever we've gathered (possibly empty → blind query). The
        // graceful degradation IS the signal, so it must NOT pollute the
        // user error log.
        debugPrint('OBD2 discoverSupportedPids failed on $command — '
            'returning ${supported.length} PIDs gathered so far');
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

  /// Whether the supported-PID set has been resolved this session —
  /// either discovered live or reloaded from the persistent cache during
  /// [prime]. `false` means we're querying blind (a probe-less clone),
  /// in which case [resolvedTargetSet] returns the full target set so the
  /// unconditional core still rotates (#811 don't-reject-blind, #2457).
  bool get isResolved => _supportedPids != null;

  /// The live subscription set for [target] (#2457): the **discover-all ∩
  /// target-set**. Given the polling layer's target PID table, return the
  /// subset the car actually implements.
  ///
  ///   - Discovery has run → `target ∩ discovered`. A car supporting only
  ///     {010C, 010D, 0104, 0111} resolves to exactly those of [target].
  ///   - Discovery has NOT run (probe-less clone, blind session) → the
  ///     full [target] unchanged. We don't know enough to drop any PID,
  ///     so the unconditional core still rotates and unsupported PIDs
  ///     self-evict via the scheduler's #2379 backoff.
  ///
  /// The discovered set itself is persisted once per adapter by [prime]
  /// (keyed off adapterMac + make:model:year via the #2253 fallback key),
  /// so this intersection costs no extra adapter I/O after the first scan.
  /// Returned set is unmodifiable.
  Set<int> resolvedTargetSet(Set<int> target) {
    final discovered = _supportedPids;
    if (discovered == null) return Set.unmodifiable(target);
    return Set.unmodifiable(
      target.where(discovered.contains).toSet(),
    );
  }

  /// Discovered-supported tri-state for [pid] (#2469):
  ///
  ///   - discovery never ran (probe-less clone / blind session) →
  ///     `'unknown'` — we can't assert support either way;
  ///   - discovered set contains [pid] → `'supported'`;
  ///   - discovered set is resolved but lacks [pid] → `'unsupported'`.
  String supportedTriState(int pid) {
    final discovered = _supportedPids;
    if (discovered == null) return triStateUnknown;
    return discovered.contains(pid) ? triStateSupported : triStateUnsupported;
  }

  /// Tee the discovered-supported tri-state for every [targetCommands] entry
  /// (command string → its Mode-01 PID int) into the gated comm-diagnostics
  /// collector (#2469). No-op when the collector is disabled — the
  /// `if(!enabled)` guard is checked before iterating, so production pays a
  /// single branch-not-taken. Keeps the resolver the single source of truth
  /// for support classification without giving it a UI/diagnostics import in
  /// the hot path.
  void recordSupportedTriStateInto(Map<String, int> targetCommands) {
    final diag = Obd2CommDiagnostics.instance;
    if (!diag.enabled) return;
    for (final entry in targetCommands.entries) {
      diag.recordSupportedTriState(entry.key, supportedTriState(entry.value));
    }
  }
}

/// Tri-state tag — discovery never ran, so support is indeterminate.
const String triStateUnknown = 'unknown';

/// Tri-state tag — the discovered set includes the PID.
const String triStateSupported = 'supported';

/// Tri-state tag — the discovered set is resolved but lacks the PID.
const String triStateUnsupported = 'unsupported';
