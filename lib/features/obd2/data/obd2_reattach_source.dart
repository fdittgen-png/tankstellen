// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'obd2_link_supervisor.dart';
import 'obd2_service.dart';

/// What the in-trip drop recovery ([DroppedSessionManager]) needs from
/// "something that will get the adapter back" (#3531, Epic #3527).
///
/// Historically this was the [AdapterReconnectScanner] — an in-trip
/// dialing loop that raced the app-wide reconnect authority over the
/// adapter's single RFCOMM channel (the #3386 war). In the rewritten
/// link layer the trip layer NEVER dials: the one
/// [Obd2LinkSupervisor] owns reconnection, and the trip layer merely
/// subscribes for the re-attach moment via [SupervisorReattachSource].
/// The interface keeps the manager's orchestration (silent window,
/// GPS-degrade, grace) untouched.
abstract class Obd2ReattachSource {
  /// Start watching for the link to come back. Idempotent.
  Future<void> start();

  /// Stop watching. Idempotent; safe after the reconnect fired.
  Future<void> stop();

  /// #2767 — invoked when recovery settles into a calm long-wait mode,
  /// so the UI can swap the busy "reconnecting" banner copy.
  set onPassiveWait(VoidCallback? callback);

  /// True while in the calm long-wait mode.
  bool get isPassiveWaiting;

  /// 1-based ordinal of the current recovery attempt (telemetry).
  int get currentAttemptNumber;

  /// Current backoff in milliseconds (telemetry).
  int get currentBackoffMs;
}

/// The #3531 reattach source: a pure SUBSCRIBER to the one
/// [Obd2LinkSupervisor]. Zero dialing, zero timers of its own — the
/// supervisor got the same proactive drop signal the trip layer did and
/// is already running its backoff loop; this object just delivers the
/// re-attach moment ([onConnected] with the fresh service, then
/// [onReconnect]) into the DroppedSessionManager's existing callbacks.
///
/// Passive-wait mapping: the supervisor has no active→passive mode
/// switch (its backoff simply caps at ~30 s); the calm banner copy
/// engages once the backoff has reached the cap.
class SupervisorReattachSource implements Obd2ReattachSource {
  SupervisorReattachSource(
    this._supervisor, {
    required void Function(Obd2Service service) onConnected,
    required VoidCallback onReconnect,
  })  : _onConnected = onConnected,
        _onReconnect = onReconnect;

  final Obd2LinkSupervisor _supervisor;
  final void Function(Obd2Service service) _onConnected;
  final VoidCallback _onReconnect;

  StreamSubscription<Obd2LinkState>? _sub;
  VoidCallback? _onPassiveWait;
  bool _passiveNotified = false;
  bool _fired = false;

  @override
  Future<void> start() async {
    if (_sub != null || _fired) return;
    // The supervisor may have re-attached BEFORE the manager finished
    // its drop bookkeeping and started us — deliver immediately.
    final live = _supervisor.service;
    if (live != null) {
      _fire(live);
      return;
    }
    _sub = _supervisor.states.listen((next) {
      if (next == Obd2LinkState.ready) {
        final svc = _supervisor.service;
        if (svc != null) _fire(svc);
        return;
      }
      if (next == Obd2LinkState.reconnecting &&
          !_passiveNotified &&
          _supervisor.backoffAtCap) {
        _passiveNotified = true;
        _onPassiveWait?.call();
      }
    });
  }

  void _fire(Obd2Service service) {
    if (_fired) return;
    _fired = true;
    unawaited(stop());
    _onConnected(service);
    _onReconnect();
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  set onPassiveWait(VoidCallback? callback) => _onPassiveWait = callback;

  @override
  bool get isPassiveWaiting => _supervisor.backoffAtCap && !_fired;

  @override
  int get currentAttemptNumber => _supervisor.attemptNumber;

  @override
  int get currentBackoffMs => _supervisor.currentBackoffMs;
}
