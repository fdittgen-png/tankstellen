// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/telemetry/collectors/breadcrumb_collector.dart';
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

  /// #3915 — the trip's adoption gate: which instances it refuses, and
  /// the notification of each adoption. Null = adopt anything live.
  set adoptionGate(Obd2AdoptionGate? gate);

  /// True while in the calm long-wait mode.
  bool get isPassiveWaiting;

  /// 1-based ordinal of the current recovery attempt (telemetry).
  int get currentAttemptNumber;

  /// Current backoff in milliseconds (telemetry).
  int get currentBackoffMs;
}

/// #3915 (Epic #3914) — the trip layer's say over WHICH instance a
/// reattach may hand it. The [DroppedSessionManager] owns the policy
/// (the re-adoption cycle breaker); the source consults it before every
/// fire and reports every adoption back so the policy can count.
abstract class Obd2AdoptionGate {
  /// True when [service] was refused for this trip: the source must not
  /// fire it and must hand it back to the owner for recycling.
  bool isRefused(Obd2Service service);

  /// [service] is about to be handed to the trip.
  void noteAdopted(Obd2Service service);
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
///
/// #3915 — adoption is proven by a ROUND-TRIP, never by the transport's
/// connected flag: the 2026-09-01 field trip re-adopted, every 8.2 s
/// for 43 minutes, an instance whose flag said connected while every
/// command threw instantly. A held service is probed first; a mute one
/// is handed back to the owner (`adoption-probe`) and the source keeps
/// waiting for a genuine `ready`.
class SupervisorReattachSource implements Obd2ReattachSource {
  SupervisorReattachSource(
    this._supervisor, {
    required this._onConnected,
    required this._onReconnect,
    this._revalidateInterval = defaultRevalidateInterval,
  });

  /// #3777 — cadence of the level revalidation while unfired. Cheap (a
  /// state + bool read); exists so NO missed edge can strand the trip:
  /// the supervisor's `_setState` dedupes, so a supervisor already
  /// parked in `ready` holding a corpse never emits a transition — the
  /// 2026-08-25 field trip waited on that edge for the whole drive.
  static const Duration defaultRevalidateInterval = Duration(seconds: 5);

  final Obd2LinkSupervisor _supervisor;
  final void Function(Obd2Service service) _onConnected;
  final VoidCallback _onReconnect;
  final Duration _revalidateInterval;

  StreamSubscription<Obd2LinkState>? _sub;
  Timer? _revalidate;
  VoidCallback? _onPassiveWait;
  Obd2AdoptionGate? _gate;
  bool _passiveNotified = false;
  bool _fired = false;
  bool _stopped = false;

  /// #3915 — a liveness probe is in flight; re-entrant pokes (state
  /// events, the revalidate tick) wait for its verdict.
  bool _probing = false;

  @override
  Future<void> start() async {
    if (_sub != null || _fired) return;
    _stopped = false;
    _sub = _supervisor.states.listen((next) {
      if (next == Obd2LinkState.ready) {
        _poke();
        return;
      }
      if (next == Obd2LinkState.reconnecting &&
          !_passiveNotified &&
          _supervisor.backoffAtCap) {
        _passiveNotified = true;
        _onPassiveWait?.call();
      }
    });
    // #3777 — LEVEL-triggered, not edge-triggered: evaluate the current
    // state immediately (the supervisor may have re-attached before the
    // manager finished its drop bookkeeping and started us) and keep
    // revalidating on a slow tick until fired. Whatever upstream defect
    // leaves the supervisor `ready` with a dead service, the poke routes
    // it into `ensureLive` → recycle → a genuine ready.
    _revalidate = Timer.periodic(_revalidateInterval, (_) => _poke());
    _poke();
  }

  /// One level evaluation. `ready` + a service that answers a probe
  /// fires the rebind (#3625 — a held-but-dead corpse must never be
  /// handed to the trip; #3915 — nor a connected-flag mute one);
  /// `ready` + dead transport is the corpse shape → ask the owner to
  /// self-heal; `reconnecting` means the ladder is already working;
  /// `engineOff` waits for a wake trigger.
  void _poke() {
    if (_fired || _probing) return;
    if (_supervisor.state.value != Obd2LinkState.ready) return;
    final svc = _supervisor.service;
    if (svc == null || !svc.isConnected) {
      _supervisor.ensureLive(reason: 'trip-reattach');
      return;
    }
    if (_gate?.isRefused(svc) ?? false) {
      // #3915 — the cycle breaker refused this very instance and the
      // owner still holds it: recycle it through the owner and wait for
      // a DIFFERENT one. No dial happens here (rule 2 — one authority).
      BreadcrumbCollector.add(
        'OBD2 recording: refused instance still held — recycling (#3915)',
      );
      _supervisor.reportServiceDead(svc, reason: 'readoption-cycle');
      return;
    }
    _probing = true;
    unawaited(_probeThenFire(svc));
  }

  /// #3915 — the adoption round-trip. A reply fires the rebind (if the
  /// owner still holds this very instance); silence or an instant throw
  /// hands the instance back to the owner, whose ladder recycles it.
  Future<void> _probeThenFire(Obd2Service svc) async {
    var live = false;
    try {
      live = await svc.probeLiveness();
    } catch (e, st) {
      // The probe swallows link faults itself; anything reaching here
      // is a programming fault worth a trace — treat it as "not live".
      logFailure(e, st,
          where: 'SupervisorReattachSource: adoption probe threw',
          layer: ErrorLayer.other);
    } finally {
      _probing = false;
    }
    if (_fired || _stopped) return;
    if (live) {
      // Re-check the level: the owner may have moved on mid-probe.
      if (identical(_supervisor.service, svc) && svc.isConnected) _fire(svc);
      return;
    }
    BreadcrumbCollector.add(
      'OBD2 recording: adoption probe failed (#3915)',
      detail: 'connected flag but no reply — handing back to the owner',
    );
    _supervisor.reportServiceDead(svc, reason: 'adoption-probe');
  }

  void _fire(Obd2Service service) {
    if (_fired) return;
    _fired = true;
    unawaited(stop());
    _gate?.noteAdopted(service);
    _onConnected(service);
    _onReconnect();
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    _revalidate?.cancel();
    _revalidate = null;
    await _sub?.cancel();
    _sub = null;
  }

  @override
  set onPassiveWait(VoidCallback? callback) => _onPassiveWait = callback;

  @override
  set adoptionGate(Obd2AdoptionGate? gate) => _gate = gate;

  @override
  bool get isPassiveWaiting => _supervisor.backoffAtCap && !_fired;

  @override
  int get currentAttemptNumber => _supervisor.attemptNumber;

  @override
  int get currentBackoffMs => _supervisor.currentBackoffMs;
}
