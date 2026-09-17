// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';

import '../../../core/background/background_price_fetcher.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'slc_wake_monitor.dart';

/// Whether this process last armed or cancelled the background schedule
/// (#4162).
///
/// The schedule itself lives outside Dart — the WorkManager database, the
/// iOS BGTask requests, the persisted callback handle — so this is what
/// the one Dart writer last APPLIED, not a read of the OS.
///
/// * [unknown] — nothing applied yet in this process.
/// * [armed] — periodic work registered (and, on iOS, the SLC wake armed
///   when the Always grant exists).
/// * [cancelled] — every registered task cancelled, SLC disarmed.
enum AlertSchedulePhase { unknown, armed, cancelled }

/// Every schedule change the reconciler legitimately makes (#4162).
///
/// * `unknown → armed | cancelled` — the first apply of the process (the
///   launch reconcile, or a boot re-arm in a background isolate).
/// * `armed → cancelled` — the last alert was deleted or disabled.
/// * `cancelled → armed` — an alert was created or re-enabled.
///
/// `armed → armed` is not a transition: every launch re-registers with
/// `ExistingPeriodicWorkPolicy.update`, and the iOS processing lane is
/// re-armed after each run (`callbackDispatcher`) without changing phase.
///
/// ## Hidden sub-states (deliberately not phases)
///
/// * armed with a callback handle persisted by the PREVIOUS build — after
///   an update, until the next launch re-persists it (#3688);
/// * armed on iOS without SLC — no Always grant, which never prompts;
/// * cancelled with a still-fresh handle stamp: the native widget enqueuer
///   gates on the stamp, not on this phase (#4331).
const Map<AlertSchedulePhase, Set<AlertSchedulePhase>>
    kAlertScheduleTransitions = {
  AlertSchedulePhase.unknown: {
    AlertSchedulePhase.armed,
    AlertSchedulePhase.cancelled,
  },
  AlertSchedulePhase.armed: {AlertSchedulePhase.cancelled},
  AlertSchedulePhase.cancelled: {AlertSchedulePhase.armed},
};

/// Whether [from] → [to] is a documented change — or no change at all.
bool isAlertScheduleTransition(AlertSchedulePhase from, AlertSchedulePhase to) =>
    from == to || (kAlertScheduleTransitions[from]?.contains(to) ?? false);

/// What an apply read from the alerts gate before acting.
enum ScheduleGateReading {
  /// At least one alert is active.
  active,

  /// No alert is active.
  inactive,

  /// The gate threw (e.g. the alerts box is not open) — nothing applied.
  unreadable,

  /// The gate was never consulted.
  unread,
}

/// An apply the reconciler's invariant says must not happen (#4162).
///
/// The invariant: **every apply acts on the newest gate reading.** An
/// apply acting on no reading, or on a reading a later apply has already
/// superseded, leaves the schedule contradicting the user's alerts.
enum ScheduleViolation {
  /// The schedule was armed without consulting the alerts gate at all.
  bootRearmWithoutGate,

  /// An arm landed after a cancel that read the gate LATER had already
  /// landed — the schedule ends armed although the newest reading said
  /// cancel.
  staleArmAfterCancel,
}

/// One apply: what it read, what it did, and in which order it read.
typedef ScheduleApply = ({
  int generation,
  ScheduleGateReading gate,
  AlertSchedulePhase result,
  String cause,
});

/// The one owner of the background schedule (#4162).
///
/// Before this, "arm or cancel" was decided in `BackgroundService.reconcile`
/// AND, without the gate, in the boot branch of `callbackDispatcher`, and
/// nothing recorded which reading an apply acted on. Every caller now goes
/// through here: the alert providers and the post-frame startup reconcile
/// via `BackgroundService.reconcile`, the Android boot re-arm via
/// [bootRearm].
///
/// ## Observe-only
///
/// Each apply is numbered when it reads the gate, and recorded with that
/// reading. An apply that breaks the invariant (see [ScheduleViolation])
/// is recorded in [debugViolations] and left as a breadcrumb — and still
/// performed, exactly as before. Fixing a violation is a behaviour change
/// with its own issue; this class only makes it visible.
///
/// Never throws: a scheduling hiccup must not crash an alert mutation, the
/// startup phase or a boot task.
class AlertScheduleReconciler {
  AlertScheduleReconciler({
    required this._gate,
    required this._fetcher,
    required this._slc,
    required this._persistTemplates,
  });

  final Future<bool> Function() _gate;
  final BackgroundPriceFetcher Function() _fetcher;
  final SlcWakeMonitor Function() _slc;
  final Future<void> Function() _persistTemplates;

  /// How many applies / violations the debug rings keep (newest win).
  static const int maxRecords = 16;

  AlertSchedulePhase _phase = AlertSchedulePhase.unknown;
  int _generation = 0;
  int _newestCancelLanded = 0;
  final Queue<ScheduleApply> _applies = Queue<ScheduleApply>();
  final Queue<(ScheduleViolation, ScheduleApply)> _violations =
      Queue<(ScheduleViolation, ScheduleApply)>();

  /// What this process last applied.
  AlertSchedulePhase get phase => _phase;

  /// The most recent applies, oldest first.
  List<ScheduleApply> get debugApplies => List.unmodifiable(_applies);

  /// The most recent invariant violations, oldest first.
  List<(ScheduleViolation, ScheduleApply)> get debugViolations =>
      List.unmodifiable(_violations);

  /// Arm or cancel according to the alerts gate — `BackgroundService
  /// .reconcile`'s body, unchanged in order: read the gate; when active,
  /// persist the localized templates (#2306) and register; otherwise
  /// cancel; then mirror the result into the iOS SLC wake (#3169).
  Future<void> reconcile({String cause = 'reconcile'}) async {
    final generation = ++_generation;
    bool? active;
    try {
      active = await _gate();
      if (active) {
        await _persistTemplates();
        await _fetcher().init();
      } else {
        await _fetcher().cancelAll();
      }
      await _slc().setEnabled(active);
      _landed((
        generation: generation,
        gate: active ? ScheduleGateReading.active : ScheduleGateReading.inactive,
        result: active ? AlertSchedulePhase.armed : AlertSchedulePhase.cancelled,
        cause: cause,
      ));
    } catch (e, st) {
      if (active == null) {
        // The gate itself threw: nothing was applied, and the schedule
        // stays as the last apply left it.
        _record((
          generation: generation,
          gate: ScheduleGateReading.unreadable,
          result: _phase,
          cause: cause,
        ));
      }
      // Never let a scheduling hiccup crash an alert mutation or startup.
      log.error(e, st,
          layer: ErrorLayer.background,
          context: const {'where': 'BackgroundService.reconcile'});
    }
  }

  /// The Android boot re-arm (#2413): re-register the periodic work after
  /// a reboot. Registers WITHOUT reading the gate — recorded as
  /// [ScheduleViolation.bootRearmWithoutGate].
  Future<void> bootRearm() async {
    final generation = ++_generation;
    try {
      await _fetcher().init();
      _landed((
        generation: generation,
        gate: ScheduleGateReading.unread,
        result: AlertSchedulePhase.armed,
        cause: 'boot',
      ));
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.background, context: const {
        'where': 'BackgroundService.bootRearm',
      });
    }
  }

  void _landed(ScheduleApply apply) {
    if (apply.gate == ScheduleGateReading.unread) {
      _violation(ScheduleViolation.bootRearmWithoutGate, apply);
    }
    if (apply.result == AlertSchedulePhase.armed &&
        _newestCancelLanded > apply.generation) {
      _violation(ScheduleViolation.staleArmAfterCancel, apply);
    }
    if (apply.result == AlertSchedulePhase.cancelled &&
        apply.generation > _newestCancelLanded) {
      _newestCancelLanded = apply.generation;
    }
    _phase = apply.result;
    _record(apply);
  }

  void _record(ScheduleApply apply) {
    _applies.addLast(apply);
    while (_applies.length > maxRecords) {
      _applies.removeFirst();
    }
  }

  void _violation(ScheduleViolation violation, ScheduleApply apply) {
    _violations.addLast((violation, apply));
    while (_violations.length > maxRecords) {
      _violations.removeFirst();
    }
    try {
      BreadcrumbCollector.add('schedule: ${violation.name}',
          detail: 'gen ${apply.generation} ${apply.gate.name} → '
              '${apply.result.name} (${apply.cause})');
    } catch (e, st) {
      log.warn('AlertScheduleReconciler: breadcrumb failed',
          error: e, stack: st, layer: ErrorLayer.background);
    }
  }
}
