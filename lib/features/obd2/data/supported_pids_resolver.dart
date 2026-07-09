// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'elm327_protocol.dart';
import 'obd2_comm_diagnostics.dart';
import 'pid_probation.dart';
import 'supported_pids_cache.dart';
import 'supported_pids_probe.dart';

export 'supported_pids_probe.dart' show Obd2BusProbeResult;

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
    Future<String> Function(String command)? searchSend,
    SupportedPidsCache? cache,
    String? vehicleFallbackKey,
  })  : _send = send,
        // #3037 — the first `0100` probe sends through [searchSend] (the
        // host's GENEROUS protocol-search window, ~15 s) instead of [_send]'s
        // ~5 s steady-state ceiling, so the ELM327 auto-search resolves within
        // ONE read rather than being re-sent (which restarts the search).
        // Defaults to [_send] for callers / tests that don't supply a separate
        // long-window send (the plain send still applies its own first-command
        // search class).
        _searchSend = searchSend ?? send,
        _isConnected = isConnected,
        _cache = cache,
        _vehicleFallbackKey = vehicleFallbackKey;

  final Future<String> Function(String command) _send;
  final Future<String> Function(String command) _searchSend;
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

  /// Tri-state outcome of the most recent `0100` probe this session
  /// (#3035). Drives the host's [Obd2Service.busProbe] so the connection
  /// layer can tell a genuine engine-off ([Obd2BusProbeResult.probedSilent])
  /// apart from a slow/flaky link ([Obd2BusProbeResult.transient]) — only
  /// the former may classify ignition-off. [Obd2BusProbeResult.notProbed]
  /// until [discoverSupportedPids] runs (a cache-hit [prime] leaves it).
  Obd2BusProbeResult _lastProbeResult = Obd2BusProbeResult.notProbed;

  /// Tri-state outcome of the most recent `0100` probe (#3035). See
  /// [Obd2BusProbeResult]. [Obd2BusProbeResult.notProbed] before discovery
  /// runs (incl. when [prime] served the set straight from the cache).
  Obd2BusProbeResult get lastProbeResult => _lastProbeResult;

  /// #3532 — consecutive REAL `NO DATA` replies a PID must return at
  /// runtime before it enters probation. Kept as the resolver's public
  /// constant (tests + docs reference it); [PidProbation] carries the
  /// same default.
  static const int probationThreshold = 3;

  /// #3532 — per-connection runtime probation (see [PidProbation]).
  final PidProbation _probation = PidProbation(threshold: probationThreshold);

  /// Clear the per-connection supported-PIDs cache. A new session may
  /// be a different car / different adapter firmware. Call at the top
  /// of the host's `connect`.
  void resetForNewConnection() {
    _supportedPids = null;
    _lastProbeResult = Obd2BusProbeResult.notProbed;
    _probation.reset();
  }

  /// #3532 — feed one runtime mode-01 reply into the probation state.
  /// [parsed] is whether the caller's parser extracted a value; see
  /// [PidProbation.noteReply] for the counting rules.
  void noteMode01Reply(String command, String raw, {required bool parsed}) =>
      _probation.noteReply(command, raw, parsed: parsed);

  /// #3532 — whether [pid] is parked by runtime probation.
  bool isPidInProbation(int pid) => _probation.contains(pid);

  /// PIDs currently parked by probation (diagnostics view).
  Set<int> get debugProbationPids => _probation.parked;

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
  /// cache so subsequent [isPidSupported] calls short-circuit, and
  /// records the tri-state [lastProbeResult] of the first `0100` probe.
  ///
  /// #3035 — the first `0100` is made resilient to the ELM327 protocol
  /// search: it retries [_probeAttempts] times with [_probeBackoffs]
  /// backoff, treats a `SEARCHING…` reply (and any empty/partial reply
  /// during the search) as "search still in progress → re-read", and only
  /// declares the bus silent ([Obd2BusProbeResult.probedSilent]) when the
  /// ECU returns a genuine NO DATA / `UNABLE TO CONNECT` through every
  /// retry. Timeouts / thrown sends through every retry are
  /// [Obd2BusProbeResult.transient] — never a confirmed engine-off.
  Future<Set<int>> discoverSupportedPids() async {
    if (!_isConnected()) return const <int>{};
    final supported = <int>{};
    final firstCommand = Elm327Protocol.supportedPidsCommands.first;
    final firstGroupBase = int.parse(firstCommand.substring(2, 4), radix: 16);

    // First `0100` — the only command that actually contacts the ECU and
    // triggers the protocol search, so it gets the GENEROUS single-shot search
    // window (#3037) via [_searchSend] (re-read, not re-send mid-search) and
    // is teed into the active connect trace for observability.
    final probeSw = Stopwatch()..start();
    final firstProbe = await probeFirstSupportedPids(
      searchSend: _searchSend,
      isConnected: _isConnected,
      command: firstCommand,
      groupBase: firstGroupBase,
      recordTrace: (raw, timedOut) {
        // #3037 root cause 3 — record the `0100` probe read into the active
        // connect trace (via the chokepoint that tees handshake lines), so a
        // future trace shows EXACTLY what the ECU returned (`SEARCHING…` /
        // `41 00 …` / `NO DATA` / `UNABLE TO CONNECT`) + the timing. A no-op
        // when no trace is active. The collector gate is irrelevant here: the
        // tee writes to the (always-on) connect-trace ring.
        Obd2CommDiagnostics.instance.recordHandshakeLine(
            firstCommand, raw, probeSw.elapsedMilliseconds);
      },
    );
    _lastProbeResult = firstProbe.result;
    if (firstProbe.bitmap == null) {
      // No bitmap — either genuine engine-off (probedSilent) or a transient.
      // Either way there is nothing to walk; record the (empty) set so the
      // session falls back to blind querying.
      _supportedPids = supported;
      return supported;
    }
    supported.addAll(firstProbe.bitmap!);

    // Walk the remaining 32-PID groups (`0120`…`01C0`) only while the
    // previous bitmap's next-range flag is set. These never re-contact the
    // ECU's protocol search (it has already locked), so they keep the
    // cheaper single-shot read with the legacy best-effort break.
    if (firstProbe.bitmap!.contains(firstGroupBase + 32)) {
      for (final command in Elm327Protocol.supportedPidsCommands.skip(1)) {
        final groupBase = int.parse(command.substring(2, 4), radix: 16);
        try {
          final response = await _send(command);
          final bitmap =
              Elm327Protocol.parseSupportedPidsBitmap(response, groupBase);
          if (bitmap == null) break;
          supported.addAll(bitmap);
          if (!bitmap.contains(groupBase + 32)) break;
        } catch (_) {
          // #2424 — best-effort tail: a transient on a flaky/slow ELM327 is
          // EXPECTED; break and keep whatever we gathered. The first probe
          // already answered, so the bus state is settled here.
          debugPrint('OBD2 discoverSupportedPids failed on $command — '
              'returning ${supported.length} PIDs gathered so far');
          break;
        }
      }
    }
    _supportedPids = supported;
    return supported;
  }

  /// Whether [pid] should be queried this connection (#811, rewritten by
  /// #3532). OPTIMISTIC: the discovered `0100` bitmap no longer rejects —
  /// clone adapters routinely UNDER-report it, and #2475's hard intersect
  /// (target ∩ bitmap) permanently starved PIDs the ECU actually answers
  /// ("less adapter info", Epic #3527). Only runtime probation parks a
  /// PID: [probationThreshold] consecutive REAL `NO DATA` replies, fed
  /// through [noteMode01Reply]. An honest bitmap converges to the same
  /// rejections after ≤3 cheap misses per absent PID; an under-reporting
  /// one keeps every answering PID live.
  ///
  /// Callers that need the STRICT bitmap claim (rare opt-in PIDs that
  /// must never be probed blind, #3416) use [isPidInBitmap] via the
  /// host's `isPidKnownSupported`.
  bool isPidSupported(int pid) => !_probation.contains(pid);

  /// STRICT bitmap membership (#3416/#3532): whether the discovered
  /// `0100` bitmap CLAIMS [pid]. False when discovery hasn't run.
  bool isPidInBitmap(int pid) => _supportedPids?.contains(pid) ?? false;

  /// Direct view of the supported-PID set for tests and diagnostics.
  /// Returns an unmodifiable empty set when discovery hasn't run.
  Set<int> get debugSupportedPids => Set.unmodifiable(_supportedPids ?? {});

  /// Whether the supported-PID set has been resolved this session —
  /// either discovered live or reloaded from the persistent cache during
  /// [prime]. `false` means we're querying blind (a probe-less clone),
  /// in which case [resolvedTargetSet] returns the full target set so the
  /// unconditional core still rotates (#811 don't-reject-blind, #2457).
  bool get isResolved => _supportedPids != null;

  /// Test seam (#3416): force-resolve the supported set so strict
  /// `isResolved`-gated PIDs (wideband phi, 0x66, 0x9D/0xA2, 0x52) can be
  /// exercised without scripting the 8 x `01 XX` bitmap scan.
  @visibleForTesting
  void debugSetSupportedPids(Set<int> pids) {
    _supportedPids = Set.of(pids);
  }

  /// The live subscription set for [target] (#2457, rewritten by #3532):
  /// the **optimistic union**. The full target set is subscribed whether
  /// or not discovery ran — the `0100` bitmap is a prior, not a gate
  /// (under-reporting clones starved real PIDs under the old
  /// `target ∩ discovered`, Epic #3527). Only PIDs parked by runtime
  /// probation ([noteMode01Reply], [probationThreshold]× real `NO DATA`)
  /// are dropped; genuinely-absent PIDs also self-evict via the
  /// scheduler's #2379 backoff in the meantime. Returned set is
  /// unmodifiable.
  Set<int> resolvedTargetSet(Set<int> target) => Set.unmodifiable(
        target.where((pid) => !_probation.contains(pid)).toSet(),
      );

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
