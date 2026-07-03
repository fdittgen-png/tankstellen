// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'obd2_link_drop_signal.dart';
import 'obd2_wedge_detector.dart';

/// Priority of an [Obd2LinkLease], ordered low → high. A [tryAcquire] with a
/// STRICTLY higher priority preempts the current holder; an equal-or-lower
/// request is refused (the caller keeps its existing fallback behaviour).
///
/// `idle` is deliberately NOT a lease: the #3019 idle reconnector registers
/// as the FALLBACK drop policy via [Obd2LinkArbiter.registerIdlePolicy] and
/// handles drops only while NO lease is held — its #3013 charter ("idle /
/// between trips") enforced by construction instead of by flag discipline.
enum Obd2LinkPriority {
  /// User-interactive one-shot connects: adapter picker, pre-warm, VIN
  /// read, self-test.
  interactive(1),

  /// The hands-free auto-record coordinator's movement-watch session.
  autoRecord(2),

  /// A live trip recording — the highest authority on the adapter.
  recording(3);

  const Obd2LinkPriority(this.rank);

  /// Numeric rank for comparisons (higher = stronger claim).
  final int rank;
}

/// A granted claim on the one physical OBD2 adapter (#3415 / #3420).
///
/// While a lease is active, the arbiter routes every proactive
/// [Obd2LinkDropSignal] drop to [onDrop] (instead of the idle policy), and
/// [Obd2LinkArbiter.tryAcquire] refuses equal-or-lower rivals — so exactly
/// one authority can drive connect/reconnect cycles at any moment. The
/// 2026-07-02 field evidence on #3415 (ten successful ELM inits in 43 s,
/// alternating firstConnect/liveReconnect) is the war this makes impossible.
class Obd2LinkLease {
  Obd2LinkLease._(this.owner, this.priority, this.onDrop, this.onPreempted);

  /// Stable, low-cardinality owner tag for traces (`recording`,
  /// `auto-record`, `picker`, …).
  final String owner;

  final Obd2LinkPriority priority;

  /// Invoked with every link-drop event observed while this lease holds.
  /// Null → the holder relies on its own transport-level drop handling
  /// (e.g. the in-trip DroppedSessionManager) and the event is dropped.
  final void Function(Obd2LinkDropEvent event)? onDrop;

  /// Invoked when a strictly-higher-priority acquire revokes this lease.
  /// The holder must stop driving connects and abandon/tear down its
  /// session; the lease is already released when this fires.
  final VoidCallback? onPreempted;

  bool _active = true;

  /// Whether this lease still holds the link.
  bool get isActive => _active;

  /// Hand the link back. Idempotent.
  void release() => Obd2LinkArbiter.instance._release(this);
}

/// One session-lease authority for every OBD2 connect, reconnect and drop
/// (#3415 / #3420, design #3418).
///
/// Root cause of the recurring reconnect war: N independent initiators ×
/// 1 adapter, reconciled only by a boolean latch (#3387) + a connect-slot
/// queue (#3185) — both of which serialize WITHOUT deciding who OWNS the
/// link. The arbiter decides ownership:
///
///  * every initiator [tryAcquire]s a lease before driving any connect;
///  * a strictly-higher priority preempts (the holder is told to stand
///    down); an equal-or-lower rival is refused outright;
///  * the arbiter is the SOLE consumer of [Obd2LinkDropSignal] — a drop
///    reaches the current holder only, or the registered idle policy
///    (#3019) when no lease is held.
///
/// Process-wide singleton for the same reason as the latch it absorbs: the
/// data-layer channels, the recording pipeline and the providers coordinate
/// without a cross-feature provider dependency.
class Obd2LinkArbiter {
  Obd2LinkArbiter._() {
    // Held for the process lifetime (never cancelled) — the arbiter IS the
    // app-wide drop router, alive exactly as long as the process.
    Obd2LinkDropSignal.instance.drops.listen(_routeDrop);
    // #3422 — the LinkWedged stand-down: the instant the wedge latches, any
    // in-flight idle loop is told to stop (mirroring a lease grant), so the
    // bounded storm ends the moment the detector calls it.
    Obd2WedgeDetector.instance.linkWedged.addListener(_onWedgeFlip);
  }

  /// Process-wide instance.
  static final Obd2LinkArbiter instance = Obd2LinkArbiter._();

  Obd2LinkLease? _holder;

  final Set<Obd2LinkIdleRegistration> _idlePolicies =
      <Obd2LinkIdleRegistration>{};

  /// Mirrors "a recording lease is held" for the #3387 latch shim
  /// ([Obd2RecordingLinkOwnership]) and its pinned tests. Notifies on every
  /// recording-ownership transition, exactly like the latch it replaces.
  final ValueNotifier<bool> recordingOwnsLink = ValueNotifier<bool>(false);

  /// The current lease holder, if any. Exposed for traces + tests.
  Obd2LinkLease? get holder => _holder;

  /// Whether a recording lease currently holds the link.
  bool get recordingLeaseHeld =>
      _holder?.priority == Obd2LinkPriority.recording && _holder!.isActive;

  /// Claim the link. Grants when the link is free; PREEMPTS a
  /// strictly-lower-priority holder (its [Obd2LinkLease.onPreempted] fires
  /// after its lease is revoked); returns null when an equal-or-higher
  /// holder keeps the link — the caller must NOT drive a connect cycle.
  ///
  /// Synchronous by design: the recording pipeline claims at the very top
  /// of `start()` (before its first await) so no drop can land unowned —
  /// the #3387 claim-after-watchdog race window cannot exist.
  Obd2LinkLease? tryAcquire(
    String owner,
    Obd2LinkPriority priority, {
    void Function(Obd2LinkDropEvent event)? onDrop,
    VoidCallback? onPreempted,
  }) {
    // #3422 — while the link is WEDGED (N consecutive exhausted Classic
    // ladders, `Obd2WedgeDetector`), the auto-record LOOP stands down like
    // every other reconnect policy: its movement-watch would keep dialling
    // the dead adapter all day (the #3415 storm). User-driven claims
    // (interactive, recording) still pass — a user gesture is one of the
    // sanctioned wedge exits.
    if (priority == Obd2LinkPriority.autoRecord &&
        Obd2WedgeDetector.instance.isWedged) {
      return null;
    }
    final current = _holder;
    if (current != null && current.isActive) {
      // Interactive-vs-interactive: the LATEST user gesture wins — a hung
      // earlier attempt (e.g. a native connect blocked for minutes, #3415
      // trace t8) must not wedge every later tap. All other equal-or-lower
      // acquires are refused: loops (idle/auto-record) retry on their own
      // schedule and must never tear down a live holder.
      final gestureOverGesture = priority == Obd2LinkPriority.interactive &&
          current.priority == Obd2LinkPriority.interactive;
      if (priority.rank <= current.priority.rank && !gestureOverGesture) {
        return null;
      }
      // Strictly higher (or gesture-over-gesture) — revoke, then notify the
      // ousted holder.
      current._active = false;
      _holder = null;
      _afterHolderChanged();
      try {
        current.onPreempted?.call();
        // ignore: silent_catch — a misbehaving onPreempted must not block the grant
      } catch (_) {}
    }
    final lease = Obd2LinkLease._(owner, priority, onDrop, onPreempted);
    _holder = lease;
    _afterHolderChanged();
    return lease;
  }

  /// Run [body] under a short-lived [Obd2LinkPriority.interactive] lease
  /// (picker / pre-warm / VIN / self-test). Returns null WITHOUT running
  /// [body] when the link is held by an equal-or-higher authority — the
  /// user-facing caller treats it as "adapter busy" exactly like a failed
  /// connect. The lease is always released when [body] settles.
  Future<T?> runInteractive<T>(
    String owner,
    Future<T> Function() body,
  ) async {
    final lease = tryAcquire(owner, Obd2LinkPriority.interactive);
    if (lease == null) return null;
    try {
      return await body();
    } finally {
      lease.release();
    }
  }

  /// Register the #3019 idle reconnect policy: [onDrop] receives drop
  /// events only while NO lease is held; [onStandDown] fires the instant
  /// any lease is granted (so an in-flight idle loop stops before it can
  /// tear down the new owner's socket). Multiple registrations (one per
  /// live provider container) all receive the callbacks — mirroring the
  /// broadcast drop-signal semantics this replaces. Dispose the returned
  /// registration with the owning provider.
  Obd2LinkIdleRegistration registerIdlePolicy({
    required void Function(Obd2LinkDropEvent event) onDrop,
    required VoidCallback onStandDown,
  }) {
    final reg = Obd2LinkIdleRegistration._(this, onDrop, onStandDown);
    _idlePolicies.add(reg);
    return reg;
  }

  void _routeDrop(Obd2LinkDropEvent event) {
    final current = _holder;
    if (current != null && current.isActive) {
      // The holder owns the drop — the idle policy must NOT also react
      // (that is the #3386/#3415 war). A null onDrop means the holder's
      // own transport-level handling (DroppedSessionManager) covers it.
      try {
        current.onDrop?.call(event);
        // ignore: silent_catch — a throwing holder must not kill the router
      } catch (_) {}
      return;
    }
    // #3422 — LinkWedged: the idle policy stands down (a drop must not kick
    // its bounded loop back into the storm). The recovery ladder / the user
    // own the link until the wedge clears.
    if (Obd2WedgeDetector.instance.isWedged) return;
    for (final reg in List<Obd2LinkIdleRegistration>.of(_idlePolicies)) {
      reg._notifyDrop(event);
    }
  }

  /// #3422 — wedge latched → stop any in-flight idle loop (same broadcast a
  /// lease grant uses). The wedge CLEARING needs no push: the next drop /
  /// retry flows normally once [Obd2WedgeDetector.isWedged] is false.
  void _onWedgeFlip() {
    if (!Obd2WedgeDetector.instance.isWedged) return;
    for (final reg in List<Obd2LinkIdleRegistration>.of(_idlePolicies)) {
      reg._notifyStandDown();
    }
  }

  void _release(Obd2LinkLease lease) {
    if (!lease._active && !identical(_holder, lease)) return;
    lease._active = false;
    if (identical(_holder, lease)) {
      _holder = null;
      _afterHolderChanged();
    }
  }

  void _afterHolderChanged() {
    recordingOwnsLink.value = recordingLeaseHeld;
    final current = _holder;
    if (current != null && current.isActive) {
      // Any granted lease silences the idle loop — not just recording
      // (the auto-record ↔ #3019 pair was the ungated war the field
      // breadcrumbs caught 15 ms apart, #3415).
      for (final reg in List<Obd2LinkIdleRegistration>.of(_idlePolicies)) {
        reg._notifyStandDown();
      }
    }
  }

  /// Revoke any held lease and reset the recording mirror (tests). Idle
  /// registrations are NOT cleared — their owning containers dispose them.
  @visibleForTesting
  void resetForTest() {
    _holder?._active = false;
    _holder = null;
    recordingOwnsLink.value = false;
  }
}

/// Handle for a registered idle policy (#3019). [dispose] with the owning
/// provider so a torn-down container stops receiving callbacks.
class Obd2LinkIdleRegistration {
  Obd2LinkIdleRegistration._(this._arbiter, this._onDrop, this._onStandDown);

  final Obd2LinkArbiter _arbiter;
  final void Function(Obd2LinkDropEvent event) _onDrop;
  final VoidCallback _onStandDown;
  bool _disposed = false;

  void _notifyDrop(Obd2LinkDropEvent event) {
    if (_disposed) return;
    try {
      _onDrop(event);
      // ignore: silent_catch — one broken policy must not starve the others
    } catch (_) {}
  }

  void _notifyStandDown() {
    if (_disposed) return;
    try {
      _onStandDown();
      // ignore: silent_catch — one broken policy must not starve the others
    } catch (_) {}
  }

  /// Stop receiving callbacks. Idempotent.
  void dispose() {
    _disposed = true;
    _arbiter._idlePolicies.remove(this);
  }
}
