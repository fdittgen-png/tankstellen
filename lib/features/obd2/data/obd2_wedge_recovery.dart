// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/logging/error_logger.dart';
import 'obd2_link_arbiter.dart';
import 'obd2_recovery_natives.dart';
import 'obd2_reconnect_episode_tracer.dart';
import 'obd2_wedge_detector.dart';

/// #3422 — injectable pacing for the recovery ladder. Production values are
/// deliberately generous (the adapter/OS sides are all async kick-offs);
/// tests inject near-zero values plus an instant `wait` seam.
class Obd2WedgeRecoveryTimings {
  const Obd2WedgeRecoveryTimings({
    this.sdpSettle = const Duration(seconds: 4),
    this.bondSettle = const Duration(seconds: 2),
    this.bondWait = const Duration(seconds: 10),
    this.adapterPoll = const Duration(seconds: 1),
    this.adapterOffWait = const Duration(seconds: 20),
    this.adapterOnWait = const Duration(seconds: 20),
    this.postEnableSettle = const Duration(seconds: 3),
    this.settingsGrace = const Duration(seconds: 25),
  });

  /// Rung 1: time for the OS SDP query to land before the probe.
  final Duration sdpSettle;

  /// Rung 2: gap between `removeBond` and `createBond`.
  final Duration bondSettle;

  /// Rung 2: time for the (possibly dialog-assisted) bonding to complete.
  final Duration bondWait;

  /// Rung 3: adapter on/off poll interval.
  final Duration adapterPoll;

  /// Rung 3: how long to await the adapter-OFF edge after REQUEST_DISABLE.
  final Duration adapterOffWait;

  /// Rung 3: how long to await the adapter-ON edge after REQUEST_ENABLE.
  final Duration adapterOnWait;

  /// Rung 3: radio settle after the adapter came back on.
  final Duration postEnableSettle;

  /// Rung 3 fallback: time the user gets on the deep-linked BT settings
  /// screen before the single verification probe.
  final Duration settingsGrace;
}

/// #3422 (epic #3415, subsumes #3404) — the wedge-recovery ESCALATION
/// LADDER, challenging #3404's "a wedged Classic adapter is unrecoverable
/// in code" verdict rung by rung, cheapest first:
///
///  1. **SDP refresh** — `fetchUuidsWithSdp` clears the LOCAL stale
///     SDP/RFCOMM-channel cache (the "wedge" may be local, not remote);
///     settle + one bounded retry.
///  2. **Guarded re-bond** — reflection `removeBond` + public `createBond`.
///     OFF by default ([rebondEnabled], a developer flag: it may surface the
///     system pairing dialog) and never while a RECORDING lease holds the
///     link.
///  3. **In-app consent BT cycle** — fire the REQUEST_DISABLE consent
///     dialog, await the adapter-off edge, fire REQUEST_ENABLE (two taps,
///     never leaving the app; no silent toggle exists on API 31+, #3404).
///     OEM-dependent: resolved first; unresolvable → the #3404 floor, a
///     deep-link straight into the system Bluetooth settings.
///  4. **One-time actionable hint** — the localized "ignition off/on, replug
///     or toggle Bluetooth" banner with a BT-settings button, raised at most
///     once per wedge episode ([hintPending]).
///
/// Each rung ends in ONE bounded verification connect through the injected
/// [probeConnect] seam (production: a pinned direct Classic connect from the
/// reconnect provider — every OTHER reconnect policy is standing down while
/// wedged, so this probe is the only connect traffic). A rung success clears
/// the wedge via [Obd2WedgeDetector.noteRecovered]; every rung start/result
/// is traced through [onTrace] into the reconnect-episode breadcrumbs so a
/// field export shows exactly which rung recovered (or didn't).
///
/// Process-wide singleton beside the detector; fully seam-injected so a unit
/// test drives the whole ladder against scriptable fake natives.
class Obd2WedgeRecovery {
  Obd2WedgeRecovery({
    required Obd2WedgeRecoveryNatives natives,
    Obd2WedgeDetector? detector,
    this.timings = const Obd2WedgeRecoveryTimings(),
    Future<void> Function(Duration)? wait,
    bool Function()? recordingLeaseHeld,
  })  : _natives = natives,
        _detector = detector ?? Obd2WedgeDetector.instance,
        _wait = wait ?? _realWait,
        _recordingLeaseHeld = recordingLeaseHeld ??
            (() => Obd2LinkArbiter.instance.recordingLeaseHeld) {
    // A wedge episode ending FOR ANY REASON (a rung, an external successful
    // connect, a user retry) retires the hint and re-arms its one-shot for
    // the NEXT episode.
    _detector.linkWedged.addListener(_onWedgeFlip);
  }

  static Future<void> _realWait(Duration d) => Future<void>.delayed(d);

  /// The single process-wide instance production wires (channel natives).
  static final Obd2WedgeRecovery instance =
      Obd2WedgeRecovery(natives: const ChannelObd2WedgeRecoveryNatives());

  final Obd2WedgeRecoveryNatives _natives;
  final Obd2WedgeDetector _detector;
  final Obd2WedgeRecoveryTimings timings;
  final Future<void> Function(Duration) _wait;
  final bool Function() _recordingLeaseHeld;

  /// Rung-2 developer flag — OFF by default: a re-bond may surface the
  /// system pairing dialog mid-drive, so it must be an explicit opt-in
  /// (a developer/settings surface flips this; #3422). Mutable by design.
  bool rebondEnabled = false;

  /// ONE bounded verification connect for [start]'s rungs. Wired by the
  /// reconnect provider (a pinned direct Classic connect); null (a harness
  /// without the connection graph) skips verification — the ladder then
  /// runs its side effects and ends at the rung-4 hint.
  Future<bool> Function(String mac)? probeConnect;

  /// Breadcrumb sink (same shape as the reconnect-episode tracer, #3346);
  /// wired by the reconnect provider into BreadcrumbCollector. Guarded.
  Obd2ReconnectTraceSink? onTrace;

  /// True while the rung-4 hint should be visible. Raised at most once per
  /// wedge episode; cleared on recovery / wedge exit / [dismissHint].
  final ValueNotifier<bool> hintPending = ValueNotifier<bool>(false);

  bool _hintRaisedThisWedge = false;
  bool _running = false;

  /// Whether a ladder run is currently in flight.
  bool get isRunning => _running;

  /// A later rung only runs while the wedge is still latched (an external
  /// successful connect / user retry may have cleared it mid-ladder).
  bool get _stillWedged => _detector.isWedged;

  /// Run the ladder for the wedged [mac]. Re-entrant-safe (a second call
  /// while running is traced + ignored). Never throws — recovery failing
  /// must never take down the caller; the stand-down (the storm bound) is
  /// already in effect regardless.
  Future<void> start(String mac) async {
    if (_running) {
      _trace('ladder-already-running', {'mac': mac});
      return;
    }
    _running = true;
    try {
      _trace('ladder-start', {'mac': mac, 'rebondEnabled': rebondEnabled});
      if (await _rungSdpRefresh(mac)) return _recovered('sdp-refresh');
      if (!_stillWedged) return;
      if (await _rungRebond(mac)) return _recovered('rebond');
      if (!_stillWedged) return;
      if (await _rungBtCycle(mac)) return _recovered('bt-cycle');
      if (!_stillWedged) return;
      _rungUserHint();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'Obd2WedgeRecovery: ladder run failed',
      }));
    } finally {
      _running = false;
    }
  }

  /// Rung 1 — SDP refresh + settle, with ONE bounded retry.
  Future<bool> _rungSdpRefresh(String mac) async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      _trace('rung-sdp-start', {'attempt': attempt});
      final kicked = await _natives.fetchUuidsWithSdp(mac);
      _trace('rung-sdp-kickoff', {'attempt': attempt, 'accepted': kicked});
      if (!kicked) return false; // adapter/native gone — retrying is moot.
      await _wait(timings.sdpSettle);
      if (await _probe(mac, rung: 'sdp-refresh', attempt: attempt)) {
        return true;
      }
    }
    return false;
  }

  /// Rung 2 — guarded re-bond. Skipped unless the [rebondEnabled] developer
  /// flag is on, and never while a recording lease holds the link (#3422).
  Future<bool> _rungRebond(String mac) async {
    if (!rebondEnabled) {
      _trace('rung-rebond-skipped', {'reason': 'config-off'});
      return false;
    }
    if (_recordingLeaseHeld()) {
      _trace('rung-rebond-skipped', {'reason': 'recording-lease-held'});
      return false;
    }
    final removed = await _natives.removeBond(mac);
    _trace('rung-rebond-removebond', {'ok': removed});
    if (!removed) return false;
    await _wait(timings.bondSettle);
    final created = await _natives.createBond(mac);
    _trace('rung-rebond-createbond', {'ok': created});
    if (!created) return false;
    await _wait(timings.bondWait);
    return _probe(mac, rung: 'rebond', attempt: 1);
  }

  /// Rung 3 — in-app consent BT cycle, or the #3404 settings deep-link when
  /// the OEM doesn't ship the consent dialogs.
  Future<bool> _rungBtCycle(String mac) async {
    if (await _natives.resolveBtIntent(kBtActionRequestDisable)) {
      final offFired = await _natives.fireBtIntent(kBtActionRequestDisable);
      _trace('rung-btcycle-disable-fired', {'ok': offFired});
      if (!offFired) return false;
      if (!await _awaitAdapter(enabled: false, max: timings.adapterOffWait)) {
        _trace('rung-btcycle-off-edge-missed', const {});
        return false; // user declined / dialog never landed.
      }
      final onFired = await _natives.fireBtIntent(kBtActionRequestEnable);
      _trace('rung-btcycle-enable-fired', {'ok': onFired});
      if (!onFired) return false;
      if (!await _awaitAdapter(enabled: true, max: timings.adapterOnWait)) {
        _trace('rung-btcycle-on-edge-missed', const {});
        return false;
      }
      await _wait(timings.postEnableSettle);
      return _probe(mac, rung: 'bt-cycle', attempt: 1);
    }
    // No consent dialogs on this OEM — the #3404 floor: deep-link the
    // system Bluetooth settings, give the user a grace window to toggle,
    // then run the single verification probe.
    final opened = await _natives.openBluetoothSettings();
    _trace('rung-btcycle-settings-deeplink', {'ok': opened});
    if (!opened) return false;
    await _wait(timings.settingsGrace);
    return _probe(mac, rung: 'bt-settings', attempt: 1);
  }

  /// Rung 4 — raise the one-time actionable hint ([hintPending] drives the
  /// localized banner). At most once per wedge episode.
  void _rungUserHint() {
    if (_hintRaisedThisWedge) {
      _trace('rung-hint-suppressed', {'reason': 'already-raised'});
      return;
    }
    _hintRaisedThisWedge = true;
    hintPending.value = true;
    _trace('rung-hint-raised', const {});
  }

  /// Poll the adapter enabled state until it matches [enabled] or [max]
  /// elapses. Iteration-bounded so an instant test `wait` can't spin.
  Future<bool> _awaitAdapter({required bool enabled, required Duration max}) async {
    final polls = timings.adapterPoll.inMilliseconds <= 0
        ? 1
        : (max.inMilliseconds ~/ timings.adapterPoll.inMilliseconds)
            .clamp(1, 120);
    for (var i = 0; i < polls; i++) {
      if (await _natives.adapterEnabled() == enabled) return true;
      await _wait(timings.adapterPoll);
    }
    return await _natives.adapterEnabled() == enabled;
  }

  /// One bounded verification connect through the injected seam. Guarded —
  /// a throwing probe counts as a miss, never as a ladder crash.
  Future<bool> _probe(String mac,
      {required String rung, required int attempt}) async {
    final probe = probeConnect;
    if (probe == null) {
      _trace('probe-skipped', {'rung': rung, 'reason': 'no-seam'});
      return false;
    }
    _trace('probe-start', {'rung': rung, 'attempt': attempt});
    var ok = false;
    try {
      ok = await probe(mac);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'Obd2WedgeRecovery: verification probe threw',
      }));
    }
    _trace('probe-result', {'rung': rung, 'attempt': attempt, 'ok': ok});
    return ok;
  }

  void _recovered(String rung) {
    _trace('wedge-recovered', {'rung': rung});
    _detector.noteRecovered('rung-$rung');
  }

  /// The user dismissed the rung-4 hint (it stays down for this episode).
  void dismissHint() => hintPending.value = false;

  /// The rung-4 banner button: deep-link the system Bluetooth settings.
  /// Best-effort; the hint stays up (the user may come back still wedged).
  Future<void> openBluetoothSettings() async {
    final opened = await _natives.openBluetoothSettings();
    _trace('hint-open-bt-settings', {'ok': opened});
  }

  void _onWedgeFlip() {
    if (_detector.linkWedged.value) return;
    // Wedge cleared — retire the hint and re-arm its one-shot.
    hintPending.value = false;
    _hintRaisedThisWedge = false;
  }

  /// Emit one breadcrumb defensively — observability must never derail the
  /// ladder (#1103).
  void _trace(String event, Map<String, Object?> data) {
    final sink = onTrace;
    if (sink == null) return;
    try {
      sink('wedge: $event', data);
    } catch (e, st) {
      debugPrint('Obd2WedgeRecovery: onTrace sink threw (ignored) — $e\n$st');
    }
  }

  /// Drop hint/one-shot/flags (tests sharing the process-wide [instance]).
  @visibleForTesting
  void resetForTest() {
    _running = false;
    _hintRaisedThisWedge = false;
    hintPending.value = false;
    rebondEnabled = false;
    probeConnect = null;
    onTrace = null;
  }
}
