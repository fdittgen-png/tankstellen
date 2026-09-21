// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/foundation.dart';

/// What the fence decided about one restored peripheral (#4357).
enum IosRestorationVerdict {
  /// The peripheral is the one the current (or recoverable) trip is
  /// bound to — the pending connect may be re-armed for it.
  admitted,

  /// The peripheral was already admitted under this binding. iOS may
  /// deliver `willRestoreState` more than once per relaunch; a second
  /// delivery must not re-arm anything a second time.
  duplicateIgnored,

  /// No identity is bound YET. The callback arrived before its owner
  /// finished arming, which on a restoration relaunch is the NORMAL
  /// ordering. Held, and re-judged the moment an identity binds.
  deferred,

  /// An identity is bound and this is not it. Refused — never adopted,
  /// never silently reassigned to the bound trip.
  refusedUnknownAdapter,

  /// The owner has stopped (user Stop, consent withdrawal, a superseding
  /// session). A queued restoration event may not revive it, and it is
  /// not held for a future binding either.
  refusedAfterStop,
}

/// One peripheral, one verdict.
@immutable
class IosRestorationDecision {
  const IosRestorationDecision(this.peripheralUuid, this.verdict);

  /// The `CBPeripheral.identifier` UUID iOS handed back.
  final String peripheralUuid;

  /// What the fence decided.
  final IosRestorationVerdict verdict;

  /// True for the two verdicts that mean "do nothing with this
  /// peripheral" — the caller must not re-arm, connect or emit.
  bool get isRefusal =>
      verdict == IosRestorationVerdict.refusedUnknownAdapter ||
      verdict == IosRestorationVerdict.refusedAfterStop;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IosRestorationDecision &&
          other.peripheralUuid == peripheralUuid &&
          other.verdict == verdict;

  @override
  int get hashCode => Object.hash(peripheralUuid, verdict);

  @override
  String toString() => 'IosRestorationDecision($peripheralUuid, '
      '${verdict.name})';
}

/// #4357 — the rule that decides which trip a restored Core Bluetooth
/// peripheral may bind to.
///
/// ## The problem
///
/// `centralManager:willRestoreState:` hands back whatever peripherals
/// the OS was holding for this app. The app has no say in *when*: the
/// callback can arrive before the owner that would consume it exists
/// (a background relaunch), twice for one relaunch, or long after the
/// user pressed Stop. Nothing previously compared those UUIDs against
/// the trip that is actually running — the restored peripheral was
/// simply whatever the OS said it was.
///
/// Three failures follow from that, and this class is the one place
/// each is named:
///
/// * A peripheral that is **not** this trip's adapter gets adopted, so
///   a second car's ELM327 (a shared garage adapter, a previous
///   vehicle still paired) feeds a trip it has nothing to do with.
/// * A restoration event that arrives **early** is dropped, so the
///   relaunch that iOS performed specifically to resume the link
///   resumes nothing.
/// * A restoration event that arrives **late** — after Stop — revives
///   a finished trip.
///
/// ## The rule
///
/// A restored peripheral binds only to the identity the owner has
/// bound, and to nothing else. Before any identity is bound the event
/// is *held*, not guessed at; after [unbind] it is *refused*, not held.
/// Holding is bounded ([_maxDeferred]) because an unbounded buffer fed
/// by the OS is a leak, and the newest events are the ones worth
/// keeping.
///
/// The fence is pure: no clock, no I/O, no platform channel. Every
/// ordering it must survive is therefore reproducible in CI.
class IosRestorationIdentityFence {
  /// Restoration callbacks held while no identity is bound. The OS
  /// hands back a handful of peripherals at most; the cap only exists
  /// so a pathological relaunch loop cannot grow it without bound.
  static const int _maxDeferred = 16;

  String? _boundAdapterId;
  bool _stopped = false;
  final Set<String> _admitted = <String>{};
  final List<String> _deferred = <String>[];

  /// The adapter UUID the current trip is bound to, or null.
  String? get boundAdapterId => _boundAdapterId;

  /// Peripheral UUIDs held for a not-yet-bound owner.
  List<String> get deferredPeripheralUuids => List.unmodifiable(_deferred);

  /// Bind the fence to [adapterId] (the trip's own adapter) and judge
  /// everything that arrived early. Returns the decisions for those
  /// held events, in arrival order.
  ///
  /// Re-binding to the same id keeps the admitted set, so a repeated
  /// arm does not re-admit a peripheral. Binding to a DIFFERENT id is
  /// a new trip identity: the admitted set is dropped.
  List<IosRestorationDecision> bind(String adapterId) {
    if (_boundAdapterId != adapterId) _admitted.clear();
    _boundAdapterId = adapterId;
    _stopped = false;
    if (_deferred.isEmpty) return const <IosRestorationDecision>[];
    final held = List<String>.of(_deferred);
    _deferred.clear();
    return offer(held);
  }

  /// The owner stopped. Any later restoration event is refused, and
  /// nothing stays held for a trip that no longer exists.
  void unbind() {
    _boundAdapterId = null;
    _stopped = true;
    _admitted.clear();
    _deferred.clear();
  }

  /// Judge [peripheralUuids] against the bound identity.
  List<IosRestorationDecision> offer(Iterable<String> peripheralUuids) {
    final out = <IosRestorationDecision>[];
    for (final uuid in peripheralUuids) {
      out.add(IosRestorationDecision(uuid, _judge(uuid)));
    }
    return out;
  }

  IosRestorationVerdict _judge(String uuid) {
    final bound = _boundAdapterId;
    if (bound == null) {
      if (_stopped) return IosRestorationVerdict.refusedAfterStop;
      if (_deferred.length >= _maxDeferred) _deferred.removeAt(0);
      _deferred.add(uuid);
      return IosRestorationVerdict.deferred;
    }
    if (uuid != bound) return IosRestorationVerdict.refusedUnknownAdapter;
    if (!_admitted.add(uuid)) return IosRestorationVerdict.duplicateIgnored;
    return IosRestorationVerdict.admitted;
  }
}
