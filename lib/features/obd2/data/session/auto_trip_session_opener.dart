// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/logging/error_logger.dart';
import '../auto_record_trace_log.dart';
import 'auto_trip_contracts.dart';
import 'obd2_link_supervisor.dart';
import '../obd2_read_telemetry.dart';
import 'obd2_service.dart';

/// Session-open/watch tail of the auto-record state machine (#3727 —
/// extracted from `AutoTripCoordinator`, zero behavior change).
///
/// Owns the movement-watch OBD2 session and its 1 Hz speed
/// subscription end-to-end: dialing (directly or through the
/// [Obd2LinkSupervisor]'s single-flight machinery), the stale-service
/// guards (#3725), the BLE link tuning (#2282 concern 4), the
/// dead-link drop signals (#3569), the threshold-cross hand-off to the
/// recorder, and the supervisor-aware session close. The coordinator
/// keeps the state machine (started / trip-active / sample counting /
/// disconnect debounce) and drives this unit through callbacks —
/// primitives and closures only, per the feature-boundary rule.
class AutoTripSessionOpener {
  /// MAC address of the paired adapter — `AutoRecordConfig.mac`.
  final String mac;

  /// #3527 — the one link supervisor. See the coordinator's field of
  /// the same name; passed through so the movement-watch session can
  /// reuse its live service and report corpses.
  final Obd2LinkSupervisor? linkSupervisor;

  /// Wraps an open service in an `Obd2SpeedStream`. Injected by the
  /// coordinator (which owns the public constructor seam).
  final Obd2SpeedStreamFactory speedStreamFactory;

  /// Bridge to `TripRecording.start(service, automatic: true)` — the
  /// coordinator's `startTrip` field, passed through unchanged.
  final Future<Object?> Function(Obd2Service service) startTrip;

  /// Per-sample callback — the coordinator's threshold counting.
  final void Function(double kmh) onSpeedSample;

  /// Link-drop callback — the coordinator's `_onDisconnected`. Invoked
  /// fire-and-forget from the speed stream's error/done handlers
  /// (#3569) and awaited from the dead-husk hand-off guard.
  final Future<void> Function() onLinkDrop;

  /// True when a freshly dialed session must be abandoned because the
  /// coordinator was stopped or a trip went live mid-open. The
  /// held-session part of that check lives here (this unit owns the
  /// session).
  final bool Function() shouldAbandonOpen;

  /// Clears the coordinator's trip-active flag on a failed hand-off.
  final void Function() clearTripActive;

  StreamSubscription<double>? _speedSub;

  /// Open OBD2 session held between `AdapterConnected` and either
  /// threshold-cross (handed to the recorder) or disconnect (closed
  /// here). Null when the coordinator is idle, when no opener was
  /// injected, or after a successful hand-off.
  Obd2Service? _session;

  AutoTripSessionOpener({
    required this.mac,
    required this.linkSupervisor,
    required this.speedStreamFactory,
    required this.startTrip,
    required this.onSpeedSample,
    required this.onLinkDrop,
    required this.shouldAbandonOpen,
    required this.clearTripActive,
    this.now = DateTime.now, // #3660 seam (tear-off, injectable)
  });

  /// Whether an open OBD2 session is currently held.
  bool get hasOpenSession => _session != null;

  /// Whether the 1 Hz speed subscription is currently wired.
  bool get isWatching => _speedSub != null;

  /// The held session, if any — read-only peek for the coordinator's
  /// liveness checks.
  Obd2Service? get session => _session;

  /// #3891 — failed opens since the last live session; the foreground
  /// re-arm backs off on these instead of redialling a parked car.
  int openFailureStreak = 0;
  DateTime? lastOpenFailureAt;
  final DateTime Function() now;

  void noteOpenFailure() => (openFailureStreak++, lastOpenFailureAt = now());

  /// Re-arm wait after the last failure: 3 min, doubling to 15 min.
  Duration get reArmCooldown {
    if (openFailureStreak <= 0) return Duration.zero;
    final minutes = (3 << (openFailureStreak - 1)).clamp(3, 15);
    return Duration(minutes: minutes);
  }

  /// Null out and return the held session without closing it —
  /// ownership transfer (hand-off) or defensive clear.
  Obd2Service? takeSession() {
    final held = _session;
    _session = null;
    return held;
  }

  /// Cancel the speed subscription. Idempotent.
  Future<void> stopWatching() async {
    await _speedSub?.cancel();
    _speedSub = null;
  }

  /// Shared "open an OBD2 session, then watch its 1 Hz speed stream"
  /// tail used by both the background `AdapterConnected` path and the
  /// foreground-active arm. [opener] selects the connect strategy
  /// (scan-based vs direct). No-ops when no opener was wired (legacy /
  /// event-only tests).
  Future<void> openAndWatch(Obd2SessionOpener? opener) async {
    if (opener == null) {
      // Test / legacy mode: no opener was wired. The coordinator's
      // pre-2b-3 contract was "speed comes from a stream injected at
      // construction time"; that field is gone, so without an opener
      // we simply have no speed source. Stay idle.
      return;
    }
    // #3527 — no lease, no arbitration: reuse the supervisor's live
    // service when one exists (a manual recording in flight shares the
    // one link — never a second RFCOMM session against a live trip),
    // else dial through the supervisor's single-flight machinery.
    final sup = linkSupervisor;
    Obd2Service? service;
    try {
      if (sup == null) {
        service = await opener(mac);
      } else {
        // #3725 — a `ready` supervisor can hold a corpse: a dongle
        // unplugged between trips dies silently (classic RFCOMM death is
        // only visible on I/O, and nothing polls an idle link), so no
        // drop event ever moved the state off `ready`. Reusing that
        // service strands auto-record in an error→retry loop for the
        // whole trip (field log 2026-08-15: 25 min of sessionOpenFailed
        // at 60 s cadence after an adapter swap). Validate before reuse;
        // on a corpse, report the drop so the supervisor recycles
        // (research rule 8: full close + fresh socket) and dial through
        // its single-flight machinery.
        var held = sup.service;
        if (held != null && !held.isConnected) {
          AutoRecordTraceLog.add(
            AutoRecordEventKind.sessionOpenFailed,
            mac: mac,
            detail: 'supervisor service stale (transport dead) — recycling',
          );
          sup.notifyDrop('staleServiceOnReuse');
          held = null;
        }
        service = held ?? // #3642 — automated: respect the stand-down hold
            await sup.connectWith(() => opener(mac), automated: true);
      }
    } catch (e, st) {
      service = null;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.sessionOpenFailed,
        mac: mac,
        detail: 'exception=$e',
      );
      // #2933 (error-log #25) — probing a PARKED car here, an EXPECTED
      // "engine off / adapter asleep" condition spooled 42/44 of that log as a
      // repeated Obd2AdapterUnresponsive ERROR. Route through the shared #2892
      // de-noiser so the expected family records a breadcrumb (sessionOpenFailed
      // above already captures it) while a GENUINE fault still ERROR-logs.
      recordObd2ConnectTransient(e, st,
          where: 'AutoTripCoordinator.openSession mac=$mac',
          layer: ErrorLayer.background);
    }
    if (service == null) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.sessionOpenFailed,
        mac: mac,
        detail: 'opener returned null',
      );
      noteOpenFailure(); // #3891
      return;
    }

    // The connect cycle could have been cancelled between awaiting the
    // opener and now (stop() was called, a disconnect already fired and
    // queued ahead of us, or a trip went live mid-open). Don't wire a
    // dangling subscription — but never close a supervisor-owned link
    // (#3527): the supervisor keeps it healthy for whoever needs it next.
    if (shouldAbandonOpen() || _session != null) {
      if (!identical(linkSupervisor?.service, service)) {
        try {
          await service.disconnect();
        } catch (e, st) {
          unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'AutoTripCoordinator: drop-orphan disconnect failed'}));
        }
      }
      return;
    }

    // Non-null alias — flow promotion doesn't reach the stream-handler
    // closures below.
    final Obd2Service live = service;
    _session = service;
    openFailureStreak = 0; lastOpenFailureAt = null; // #3891 — live → no cooldown
    // #2282 concern 4 — only the 1 Hz auto-record movement stream is
    // live at this point (the recorder hasn't taken over yet), so drop
    // the BLE link to balanced connection priority. The recorder bumps
    // it back to high on threshold-cross when it owns the session.
    unawaited(tuneLinkForBackground(service));
    final speedStream = speedStreamFactory(service, mac: mac);
    // #3569 — a foreground link death produces NO AdapterDisconnected
    // platform event (the FGS is gated off), so the speed stream's own
    // error/done is the only drop signal the coordinator gets. Without
    // these handlers the dead `_session`/`_speedSub` stranded
    // `armForegroundActive` behind its skip-guard for the rest of the
    // day (field log 2026-07-13: zero dials from 10:32 to 21:32).
    _speedSub = speedStream.stream.listen(
      onSpeedSample,
      onError: (Object e, StackTrace st) {
        AutoRecordTraceLog.add(
          AutoRecordEventKind.sessionOpenFailed,
          mac: mac,
          detail: 'speed stream error — treating as link drop: $e',
        );
        _reportSupervisorCorpse(live);
        unawaited(onLinkDrop());
      },
      onDone: () {
        AutoRecordTraceLog.add(
          AutoRecordEventKind.sessionOpenFailed,
          mac: mac,
          detail: 'speed stream closed — treating as link drop',
        );
        _reportSupervisorCorpse(live);
        unawaited(onLinkDrop());
      },
    );
  }

  /// #3725 — when the service that died under the speed watch is the
  /// supervisor's own held link AND its transport is genuinely dead,
  /// tell the supervisor. Without this the supervisor stays `ready`
  /// holding the corpse (a silent transport death produces no drop
  /// event) and serves the exact same dead service to every subsequent
  /// arm attempt. Session-level errors on a live transport are left
  /// alone — the supervisor's link is still healthy for other owners.
  void _reportSupervisorCorpse(Obd2Service service) {
    final sup = linkSupervisor;
    if (sup == null) return;
    if (!identical(sup.service, service)) return;
    if (service.isConnected) return;
    sup.notifyDrop('coordinatorSpeedWatch: transport dead');
  }

  /// Best-effort balanced-priority downgrade (#2282 concern 4). The
  /// service no-ops for non-BLE transports / fakes and swallows platform
  /// rejections internally, so this never throws into the connect path.
  Future<void> tuneLinkForBackground(Obd2Service service) async {
    try {
      await service.tuneLinkForBackground();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st, context: const {
        'where': 'AutoTripCoordinator: tuneLinkForBackground failed',
      }));
    }
  }

  /// Best-effort high-priority restore on threshold-cross hand-off
  /// (#2282 concern 4). Same swallow-and-log contract as
  /// [tuneLinkForBackground].
  Future<void> tuneLinkForRecording(Obd2Service service) async {
    try {
      await service.tuneLinkForRecording();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.background, e, st, context: const {
        'where': 'AutoTripCoordinator: tuneLinkForRecording failed',
      }));
    }
  }

  /// Threshold-cross hand-off: transfer the held session to the
  /// recorder via [startTrip] and classify the outcome. Extracted with
  /// its state (`_session` / `_speedSub`) from the coordinator's
  /// `_invokeStartTrip` (#3727); the coordinator's trip-active flag is
  /// reached through [clearTripActive] / [onLinkDrop].
  Future<void> handOffAndStartTrip(double observedSpeedKmh) async {
    final session = _session;
    if (session == null) {
      // Should not happen — `_onSpeedSample` only fires when the
      // speed stream is wired, and the speed stream only exists when
      // a session was opened. Trace it so a regression here is
      // visible rather than silent.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripStartFailed,
        mac: mac,
        detail: 'no session held at threshold-cross',
      );
      clearTripActive();
      return;
    }
    if (!session.isConnected) {
      // #3569 — never hand a dead husk to the recorder: a link that died
      // between the last speed sample and the threshold-cross would start
      // a trip whose every PID command times out. Tear down instead; the
      // disconnect debounce + the self-healing foreground arm take over.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripStartFailed,
        mac: mac,
        detail: 'session dead at threshold-cross — torn down, not handed off',
      );
      clearTripActive();
      await onLinkDrop();
      return;
    }
    // Stop the coordinator's speed polling immediately — the recorder
    // is about to take ownership and will run its own per-PID
    // sampling. Holding the polling timer alongside would
    // double-issue PID 0x0D commands on the same transport.
    await stopWatching();
    // #2282 concern 4 — the movement watch is over and the recorder is
    // about to drive the full-rate PID poll, so restore the high-
    // throughput BLE link we downgraded to balanced while only the 1 Hz
    // stream was live. Best-effort; the recorder gets a high-priority
    // link for the trip either way (a fresh connect already tunes high).
    await tuneLinkForRecording(session);
    // Transfer ownership: null out the local pointer so neither
    // `stop()` nor `_onDisconnected()` will try to close a session
    // the recorder is using. #3420 — release the auto-record lease at the
    // same moment: the recorder's `start()` acquires its own RECORDING
    // lease, so the hand-off is a clean ownership transfer, not a preempt.
    _session = null;
    AutoRecordTraceLog.add(
      AutoRecordEventKind.sessionHandedOff,
      mac: mac,
      detail: 'observedSpeedKmh=${observedSpeedKmh.toStringAsFixed(1)}',
    );
    try {
      final Object? outcome = await startTrip(session);
      // The coordinator is decoupled from `StartTripOutcome` (it lives
      // in the providers layer). We classify outcomes by their string
      // form: enum `toString()` is `EnumName.value`, so the trailing
      // segment after the dot is the value name. `null` is the test
      // stub's signal for "no outcome to report" and is treated as
      // success — production wiring always returns a typed outcome.
      final String? outcomeName = outcome?.toString().split('.').last;
      if (outcome == null || outcomeName == 'started') {
        AutoRecordTraceLog.add(
          AutoRecordEventKind.tripStarted,
          mac: mac,
          detail: 'observedSpeedKmh=${observedSpeedKmh.toStringAsFixed(1)}',
        );
      } else {
        AutoRecordTraceLog.add(
          AutoRecordEventKind.tripStartFailed,
          mac: mac,
          detail: 'outcome=$outcomeName',
        );
      }
    } catch (e, st) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripStartFailed,
        mac: mac,
        detail: 'exception=$e',
      );
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: <String, Object?>{
          'phase': 'AutoTripCoordinator.startTrip',
          'mac': mac,
          'observedSpeedKmh': observedSpeedKmh,
        },
      );
    }
  }

  /// Close [_session] if held, swallowing transport errors. Idempotent
  /// — `_session` is nulled out either way so a follow-up call is a
  /// no-op. #3527 — a session that IS the supervisor's live link is NOT
  /// closed here: the supervisor owns link health end-to-end, and a
  /// deliberate close would leave it believing a dead socket is ready.
  Future<void> closeSessionIfHeld() async {
    final held = _session;
    if (held == null) return;
    _session = null;
    if (identical(linkSupervisor?.service, held)) return;
    try {
      await held.disconnect();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'AutoTripCoordinator: session close failed'}));
    }
  }
}
