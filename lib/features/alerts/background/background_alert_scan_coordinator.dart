// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT


import '../../../core/logging/error_logger.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/background/alert_scan_journal.dart';
import '../../../core/background/background_scan_trigger.dart';
import '../../../core/background/scan_run_gate.dart';
import '../../../core/background/scan_run_phase.dart';
import 'background_scan_body.dart';
import 'background_scan_dedup_store.dart';
import 'background_scan_runners.dart';
import 'scan_opportunity_dispatch.dart';
import '../../../core/background/hive_isolate_lock.dart';
import '../../../core/logging/run_scope.dart';

// The trigger taxonomy lives in its own file since #3169 (file-length cap);
// re-exported here so every existing importer keeps working.
export '../../../core/background/background_scan_trigger.dart';

/// Platform-neutral entry point for an on-device background price scan
/// (#2415).
///
/// Every trigger — WorkManager periodic tasks, the Android home-widget
/// refresh (#2412), and the iOS BGAppRefreshTask (#2414) — funnels through
/// [scan] so they all run *exactly the same* fetch → evaluate → notify
/// pipeline. Centralising it here means there is one place that:
///
///   1. acquires the [HiveIsolateLock] so the background and main isolates
///      never write Hive concurrently (a single serialisation point for
///      WorkManager + widget + BGTask),
///   2. enforces a coarse cross-trigger cooldown ([scanCooldown]) via
///      [BackgroundScanDedupStore] so two wakeups seconds apart can't
///      double-fetch or double-notify, and
///   3. sequences the scan body's stages ([ScanBody]: price fetch + daily
///      history, detect → budget → notify, widget refresh).
///
/// ## The run's lifecycle (#4162)
///
/// This class is the ONLY writer of the run's [ScanRunPhase]; every change
/// walks through a [ScanRunGate] that checks it against
/// [kScanRunTransitions], and ends in exactly one [ScanOutcome] — the
/// journal row. The body and the dispatcher report nothing themselves.
///
/// The per-alert throttles are untouched and still own "don't re-notify the
/// same alert too often": [RadiusAlertRunner]'s frequency gate, the price-
/// alert re-trigger cooldown, and the velocity cooldown. [scanCooldown] is a
/// *separate*, shorter window that only dedups redundant *triggers*.
///
/// ## Honest reliability framing
/// Background scanning is **best-effort**, never real-time. Android delays
/// periodic work under Doze; iOS schedules BGAppRefresh opportunistically
/// against the user's app-usage budget; the widget refresh is bounded by
/// the OS. The coordinator makes triggers cheap and idempotent — it does
/// not (and cannot) make them punctual.
class BackgroundAlertScanCoordinator {
  /// Max IDs accepted per Tankerkoenig batch prices request.
  static const tankerkoenigBatchSize = 10;

  /// Coarse cross-trigger scan cooldown (#2415). A scan that lands inside
  /// this window after a completed scan is skipped, so the WorkManager
  /// task and an opportunistic widget/BGTask wake seconds later don't both
  /// hit the API. Chosen far below the twice-daily periodic cadence so a
  /// legitimately-scheduled periodic task is never starved, but long enough
  /// to absorb a burst of near-simultaneous triggers (the widget refresh +
  /// the periodic wake landing seconds apart).
  static const scanCooldown = Duration(minutes: 10);

  /// Do not re-fire the same per-station price alert within this window.
  /// Re-exported from [BackgroundScanRunners] so existing call sites + tests
  /// keep a single name for the per-alert throttle.
  static const priceAlertRetriggerCooldown =
      BackgroundScanRunners.priceAlertRetriggerCooldown;

  /// Connect / receive timeouts for the BG-isolate Dio client.
  static const bgConnectTimeout = BackgroundScanBody.connectTimeout;
  static const bgReceiveTimeout = BackgroundScanBody.receiveTimeout;

  /// Max retry attempts + base backoff for transient network failures.
  static const maxRetryAttempts = 3;
  static const retryBaseDelay = Duration(seconds: 2);

  final BackgroundScanDedupStore _dedup;
  final AlertScanJournal _journal;
  final Future<HiveIsolateLock> Function() _lockFactory;
  final Future<void> Function() _openBoxes;
  final Future<void> Function() _closeBoxes;
  final Future<NotificationService> Function() _notifierFactory;
  final ScanBody Function(HiveStorage storage, DateTime at) _bodyFactory;
  final ScanPhaseSink? _sink;

  /// Creates a coordinator. Every collaborator is injectable so the run's
  /// lifecycle is testable without platform channels (#4162):
  ///
  /// * [dedup] / [journal] — the cooldown gate and the journal;
  /// * [lockFactory] — the cross-isolate lock (a temp-file lock in tests);
  /// * [openBoxes] / [closeBoxes] — the isolate's Hive boxes;
  /// * [notifierFactory] — the initialized notifier the dispatch stage
  ///   posts through;
  /// * [body] — the stages themselves;
  /// * [sink] — told every phase change and the outcome.
  BackgroundAlertScanCoordinator({
    BackgroundScanDedupStore? dedup,
    AlertScanJournal? journal,
    Future<HiveIsolateLock> Function()? lockFactory,
    Future<void> Function()? openBoxes,
    Future<void> Function()? closeBoxes,
    Future<NotificationService> Function()? notifierFactory,
    ScanBody Function(HiveStorage storage, DateTime at)? body,
    this._sink,
  })  : _dedup = dedup ?? BackgroundScanDedupStore(),
        _journal = journal ?? AlertScanJournal(),
        _lockFactory = lockFactory ?? HiveIsolateLock.create,
        _openBoxes = openBoxes ?? HiveStorage.initInIsolate,
        _closeBoxes = closeBoxes ?? HiveStorage.closeIsolateBoxes,
        _notifierFactory = notifierFactory ?? initializedLocalNotifier,
        _bodyFactory = body ?? BackgroundScanBody.new;

  /// Run one background scan on behalf of [trigger].
  ///
  /// Acquires the Hive isolate lock, checks the cross-trigger cooldown,
  /// runs the full scan body, and stamps the dedup record on completion.
  /// Returns `true` when a scan actually ran, `false` when it was skipped
  /// (lock contention or cooldown).
  ///
  /// Every failure is caught and routed through `errorLogger` (which spools
  /// via the isolate error spool when unbound, #3150) for the
  /// foreground TraceRecorder; the call returns `false` rather than
  /// propagating, so a flaky network or storage fault can't crash the OS-
  /// spawned background isolate. The whole body is wrapped in
  /// try/catch/finally so the lock is always released and the Hive boxes
  /// always closed.
  ///
  /// [now] is injectable for tests; defaults to the wall clock.
  /// #3980 — one ADR 0021 runId for everything this call logs.
  Future<bool> scan({
    required BackgroundScanTrigger trigger,
    DateTime? now,
    Duration cooldown = scanCooldown,
  }) =>
      RunScope.run('background-scan', () => _ScanRun(this, trigger,
              at: now ?? DateTime.now(), cooldown: cooldown)
          .run());
}

/// One call to [BackgroundAlertScanCoordinator.scan]: the phase it is in
/// and the gate that checks each change (#4162).
class _ScanRun {
  _ScanRun(this._c, this.trigger, {required this.at, required this.cooldown})
      : _gate = ScanRunGate(sink: _c._sink);

  final BackgroundAlertScanCoordinator _c;
  final BackgroundScanTrigger trigger;
  final DateTime at;
  final Duration cooldown;
  final ScanRunGate _gate;
  ScanRunPhase _phase = ScanRunPhase.idle;

  void _advance(ScanRunPhase to) {
    _gate.change(_phase, to);
    _phase = to;
  }

  Future<void> _end(
    ScanOutcome outcome, {
    int? stationsScanned,
    int? alertsFired,
    String? error,
  }) async {
    _gate.end(outcome, _phase);
    await _c._journal.record(
      outcome,
      at: at,
      trigger: trigger.tag,
      stationsScanned: stationsScanned,
      alertsFired: alertsFired,
      error: error,
    );
  }

  Future<bool> run() async {
    HiveIsolateLock? lock;
    _advance(ScanRunPhase.locking);
    try {
      lock = await _c._lockFactory();
      final acquired = await lock.acquire();
      if (!acquired) {
        log.debug('could not acquire Hive lock (${trigger.tag}), skipping',
            tag: 'BackgroundAlertScanCoordinator');
        // #3147 — best-effort: the alerts box is usually NOT open on this
        // path (the lock holder owns it), so the append may no-op; the
        // concurrent holder journals its own completed row.
        await _end(ScanOutcome.skippedLock);
        return false;
      }

      _advance(ScanRunPhase.opening);
      await _c._openBoxes();

      // Cross-trigger cooldown — read it *after* the lock + box open so the
      // dedup row is consistent with whatever the previous scan wrote.
      _advance(ScanRunPhase.gated);
      // #4333 — a run the OS ended left its marker; this run holds the lock,
      // so no live run can own one. Resolve them into `interrupted` rows.
      await _c._journal.resolveInterrupted();
      final allowed = await _c._dedup.shouldScan(now: at, cooldown: cooldown);
      if (!allowed) {
        final last = await _c._dedup.lastScanAt();
        log.debug(
            'scan skipped (${trigger.tag}) — last scan $last is within '
            '${cooldown.inMinutes}m cooldown',
            tag: 'BackgroundAlertScanCoordinator');
        await _end(ScanOutcome.skippedCooldown);
        return false;
      }

      // #4333 — from here on the run owes the journal a row even if the OS
      // ends it: the marker is that row until the outcome replaces it.
      await _c._journal.markInFlight(at: at, trigger: trigger.tag);
      final body = _c._bodyFactory(HiveStorage(), at);
      _advance(ScanRunPhase.collecting);
      await body.collect();
      var alertsFired = 0;
      if (!body.isEmpty) {
        _advance(ScanRunPhase.dispatching);
        alertsFired = await body.dispatch(_c._notifierFactory);
      }
      _advance(ScanRunPhase.refreshingWidgets);
      await body.refreshWidgets();

      // Stamp completion only after the body finishes so a crash mid-scan
      // leaves the door open for the next trigger to retry.
      _advance(ScanRunPhase.stamping);
      await _c._dedup.recordScan(now: at, trigger: trigger.tag);
      // #3147 — persisted audit row: when, what trigger, how many stations
      // were fetched, how many notifications fired. Rides in the export so
      // "why didn't I get an alert?" is answerable in the field.
      await _end(ScanOutcome.completed,
          stationsScanned: body.stationsScanned, alertsFired: alertsFired);
      return true;
    } catch (e, st) {
      // #3150 — single log call. `errorLogger.log` already routes to the
      // IsolateErrorSpool when unbound (background isolate), so the former
      // explicit `IsolateErrorSpool.enqueue` double-logged every scan
      // failure; the bg_scan tag now travels in the context map instead.
      log.error(e, st, layer: ErrorLayer.other, context: {
        'where': 'BackgroundAlertScanCoordinator: scan failed (${trigger.tag})',
        'isolateTaskName': 'bg_scan_${trigger.tag}',
      });
      // #3147 — the error TYPE only (PII-safe), so the journal shows a
      // failed run distinctly from "no scan ran at all".
      await _end(ScanOutcome.failed, error: e.runtimeType.toString());
      return false;
    } finally {
      try {
        await _c._closeBoxes();
      } catch (e, st) {
        log.error(e, st, layer: ErrorLayer.other, context: const {
          'where': 'BackgroundAlertScanCoordinator: failed to close Hive boxes'
        });
      }
      lock?.release();
      _advance(ScanRunPhase.idle);
    }
  }
}
