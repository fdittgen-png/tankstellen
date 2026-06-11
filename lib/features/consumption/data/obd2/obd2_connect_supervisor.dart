// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import 'obd2_connect_trace_log.dart';

/// Coarse admission state of an [Obd2ConnectSupervisor] (#3185). Exposed for
/// diagnostics + tests; the supervisor itself is the only writer.
enum Obd2SupervisorState {
  /// No connect attempt in flight.
  idle,

  /// An ACTIVE (bounded) connect attempt holds the admission slot.
  active,

  /// A PASSIVE attempt (the unbounded autoConnect GATT wait) holds the slot.
  passive,

  /// A passive holder is being preempted for a newly-arrived active
  /// requester — its teardown was triggered and the supervisor is waiting
  /// (bounded by the preempt grace) for it to unwind.
  draining,
}

/// #3185 / Epic #3178 — single-flight CONNECT ADMISSION for the OBD2 stack.
///
/// Six uncoordinated connect owners (picker pinned fast-path, recording
/// pre-warm, auto-record orchestrator, trip-independent reconnect, in-trip
/// [ReconnectConnector], VIN reader) used to race each other through
/// [Obd2ConnectionService]: a second entrant's `_teardownLastDirectChannel()`
/// / `stopScan()` disconnected the first's half-open GATT mid-handshake,
/// manifesting as the very GATT-133 / timeout storms the retries then
/// "fixed". This supervisor sits at the service chokepoint and enforces ONE
/// in-flight connect attempt per process:
///
///  * **Single-flight admission** — every public connect entry [admit]s
///    here first. While an attempt is in flight, later requesters QUEUE
///    (FIFO) instead of tearing the holder down; the wait is stamped into
///    the requester's connect trace (`supervisor-admission` step) so a
///    field export shows who waited on whom.
///  * **Re-entrant by construction** — the connect paths re-enter the
///    public service methods internally (direct → scan fallback →
///    `connect(candidate)` …). A nested call inside an already-admitted
///    attempt runs inline (zone-scoped admission token), so one logical
///    attempt is one admission — mirroring how [Obd2ConnectTraceLog] makes
///    one logical attempt one trace.
///  * **Passive attempts never starve the user** — the unbounded
///    autoConnect wait ([Obd2ConnectionService.connectByMacPassive]) is
///    try-acquire only ([admitPassive]): it SKIPS its cycle when anything
///    else is in flight, and when it holds the slot an arriving active
///    requester PREEMPTS it (its `onPreempt` teardown is invoked — closing
///    the passive channel unwinds the wait), bounded by [preemptGrace]
///    after which the supervisor force-releases the slot (never worse than
///    the pre-#3185 free-for-all).
///
/// The supervisor deliberately owns NO retry, NO timeouts and NO
/// classification: per-stage budgets live on the FBP-native timeouts
/// (#3182), bounded retry-with-backoff on the re-openable channel lives in
/// [BluetoothObd2Transport.connect] (#3179/#3014), failure classification
/// in the connect classifiers, and pairing mode in [Obd2PairingMode]
/// (#3181). It only decides WHO may attempt WHEN.
///
/// One instance lives on the (keepAlive-singleton) production
/// [Obd2ConnectionService], so admission is process-wide in production
/// while unit tests get a fresh, isolated instance per service.
/// Single-isolate like the rest of the OBD2 stack — no locking primitives
/// beyond the FIFO completer queue.
class Obd2ConnectSupervisor {
  Obd2ConnectSupervisor({
    Duration preemptGrace = const Duration(seconds: 5),
    Future<void> Function(Duration)? wait,
  })  : _preemptGrace = preemptGrace,
        _wait = wait ?? _realWait;

  static Future<void> _realWait(Duration d) => Future<void>.delayed(d);

  /// How long a preempted passive holder gets to unwind before the slot is
  /// force-released to the waiting active requester. Past it the active
  /// attempt proceeds; its own scan-stop + channel teardown (the first
  /// thing every connect path does) clears whatever the zombie left — i.e.
  /// the bounded fallback is exactly today's behaviour.
  final Duration _preemptGrace;

  /// Injectable delay (tests drive the grace deterministically).
  final Future<void> Function(Duration) _wait;

  _Obd2Admission? _current;
  final List<_Obd2Admission> _queue = [];

  /// Current admission state, for diagnostics + tests.
  Obd2SupervisorState get state {
    final cur = _current;
    if (cur == null) return Obd2SupervisorState.idle;
    if (cur.passive) {
      return cur.preempting
          ? Obd2SupervisorState.draining
          : Obd2SupervisorState.passive;
    }
    return Obd2SupervisorState.active;
  }

  /// Whether any connect attempt currently holds the admission slot.
  bool get isInFlight => _current != null;

  /// Owner label of the in-flight attempt, or null when idle. Used for the
  /// `supervisor-admission` trace step of a requester that had to wait.
  String? get currentOwner => _current?.owner;

  /// Number of requesters currently queued behind the holder.
  @visibleForTesting
  int get queuedCount => _queue.length;

  /// Admit one ACTIVE (bounded) connect attempt. Runs [attempt] exclusively:
  /// when another attempt is in flight the caller WAITS (FIFO) for the slot;
  /// a passive holder is preempted (see class doc). A nested call from
  /// inside an already-admitted attempt runs [attempt] inline, so the
  /// internal fallback chains (direct → scan → connect) stay one admission.
  ///
  /// Errors from [attempt] propagate unchanged — the supervisor classifies
  /// nothing — but the slot is ALWAYS released (`finally`), so a throwing
  /// attempt can never wedge admission for the next requester.
  Future<T> admit<T>({
    required String owner,
    required Future<T> Function() attempt,
  }) async {
    if (_isReentrant) return attempt();
    final adm = _Obd2Admission(owner: owner, passive: false);
    final sw = Stopwatch()..start();
    await _acquire(adm);
    sw.stop();
    if (adm.queuedBehind != null) {
      // One-shot note consumed by the attempt's own root trace: makes the
      // serialization VISIBLE in a field export instead of an unexplained
      // gap before step 0.
      Obd2ConnectTraceLog.pendingAdmissionNote =
          '"$owner" waited ${sw.elapsedMilliseconds}ms for the connect slot '
          'held by "${adm.queuedBehind}" (#3185)';
    }
    try {
      return await runZoned(attempt, zoneValues: {this: adm});
    } finally {
      _release(adm);
    }
  }

  /// Admit one PASSIVE attempt — the unbounded autoConnect GATT wait. Unlike
  /// [admit] this is try-acquire: when ANY attempt is in flight (or queued)
  /// it returns null WITHOUT running [attempt] — the reconnect scanner just
  /// keeps its backoff cadence, exactly as on any other missed cycle. While
  /// the passive attempt holds the slot, an arriving active requester
  /// triggers [onPreempt] (close the passive channel so the wait unwinds).
  Future<T?> admitPassive<T>({
    required String owner,
    required Future<void> Function() onPreempt,
    required Future<T?> Function() attempt,
  }) async {
    if (_isReentrant) return attempt();
    if (_current != null || _queue.isNotEmpty) {
      debugPrint('Obd2ConnectSupervisor: passive "$owner" skipped — '
          '"${currentOwner ?? 'queued requester'}" is in flight');
      return null;
    }
    final adm =
        _Obd2Admission(owner: owner, passive: true, onPreempt: onPreempt);
    _current = adm;
    try {
      return await runZoned(attempt, zoneValues: {this: adm});
    } finally {
      _release(adm);
    }
  }

  /// True when the caller is already INSIDE an admitted attempt whose slot
  /// is still held — the zone carries the admission token. A stale token
  /// (its admission already released, e.g. work spawned by a past attempt)
  /// does NOT count, so leaked background work re-queues like any requester.
  bool get _isReentrant {
    final token = Zone.current[this];
    return token is _Obd2Admission && !token.released;
  }

  Future<void> _acquire(_Obd2Admission adm) async {
    final cur = _current;
    if (cur == null && _queue.isEmpty) {
      _current = adm;
      return;
    }
    adm.queuedBehind = cur?.owner;
    _queue.add(adm);
    if (cur != null && cur.passive) _preemptPassive(cur);
    await adm.granted.future;
  }

  /// Preempt the passive holder for a waiting active requester: trigger its
  /// teardown (best-effort) and arm the bounded grace after which the slot
  /// is force-released. Idempotent per holder.
  void _preemptPassive(_Obd2Admission passive) {
    if (passive.preempting) return;
    passive.preempting = true;
    unawaited(Future(() async {
      try {
        await passive.onPreempt?.call();
      } catch (e, st) {
        // Best-effort: a throwing teardown must not stop the hand-off — the
        // grace below force-releases regardless.
        debugPrint('Obd2ConnectSupervisor: passive "${passive.owner}" '
            'preempt teardown threw (ignored): $e\n$st');
      }
    }));
    unawaited(_wait(_preemptGrace).then((_) {
      if (identical(_current, passive)) {
        debugPrint('Obd2ConnectSupervisor: passive "${passive.owner}" did '
            'not unwind within $_preemptGrace — force-releasing the slot');
        passive.released = true;
        _handOff();
      }
    }).catchError((Object e) {
      // The injected wait failing must never strand the queue: force-release
      // immediately instead.
      if (identical(_current, passive)) {
        passive.released = true;
        _handOff();
      }
    }));
  }

  void _release(_Obd2Admission adm) {
    if (adm.released) return; // force-released earlier; late unwind no-ops.
    adm.released = true;
    if (!identical(_current, adm)) return;
    _handOff();
  }

  void _handOff() {
    if (_queue.isEmpty) {
      _current = null;
      return;
    }
    final next = _queue.removeAt(0);
    _current = next;
    next.granted.complete();
  }
}

/// One admission ticket. The zone of the running attempt carries it so
/// nested public-method re-entries run inline instead of self-deadlocking.
class _Obd2Admission {
  _Obd2Admission({required this.owner, required this.passive, this.onPreempt});

  final String owner;
  final bool passive;
  final Future<void> Function()? onPreempt;
  final Completer<void> granted = Completer<void>();

  /// Owner of the holder this ticket queued behind (null = ran immediately).
  String? queuedBehind;

  /// A passive holder whose teardown was triggered for a waiting active.
  bool preempting = false;

  /// Slot already released (normally or force-released after the grace).
  bool released = false;
}
