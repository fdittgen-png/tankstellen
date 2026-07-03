// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/error_logger.dart';
import '../perf/launch_sync_trace.dart';

/// One registered server→local pull covering [tables] (#3447).
///
/// [pull] embeds its own consent gate (it returns 0 without touching the
/// network when its gate is off) and its own `SyncEvents` emit AFTER the
/// persist (#3446). [timeout] bounds the whole pull; the default 15 s is
/// the #3128 per-table budget, the trips merge registers 20 s (#3450).
class SyncPullEntry {
  const SyncPullEntry({
    required this.tables,
    required this.pull,
    this.timeout = const Duration(seconds: 15),
  });

  /// The Supabase tables this pull persists locally (`SyncTables`
  /// constants). Usually one; the favorites/ignored id-set pull covers two
  /// because `syncAndPersistIds` is one seam over both.
  final List<String> tables;

  final Duration timeout;

  /// Runs the merge + persist + emit; returns the pulled-row count for the
  /// #3445 trace attributes.
  final Future<int> Function() pull;
}

/// #3447 — THE pull registry: every trigger that wants "pull all synced
/// tables" (app launch, app resume, the "sync now" gesture) funnels through
/// [pullAll], so full coverage is a property of ONE registration list
/// instead of three hand-maintained call sites drifting apart.
///
/// Registration happens once, in the app layer
/// (`LaunchSyncPhase.registerPulls`), because the pull thunks read feature
/// providers this core file must not import. The registry itself is
/// feature-free, so the "sync now" provider (a feature) may call [pullAll]
/// without new cross-feature imports.
///
/// ## #3450 — parallel + isolated
///
/// [pullAll] runs every entry with `Future.wait`: one hung or failing
/// table can never block the others (each entry carries its own timeout
/// and its own catch), and the wall-clock cost is the SLOWEST pull, not
/// the sum. `test/core/sync/sync_pull_coordinator_test.dart` pins both.
class SyncPullCoordinator {
  SyncPullCoordinator._();

  /// The app-wide registry. A plain singleton (not a provider), mirroring
  /// [SyncEvents.instance], so core-adjacent callers without a `Ref` can
  /// trigger a pull.
  static final SyncPullCoordinator instance = SyncPullCoordinator._();

  final List<SyncPullEntry> _entries = [];

  /// Master gate installed at registration: `false` when TankSync is off /
  /// not initialised. Checked once per [pullAll].
  bool Function() _enabled = () => false;

  bool _running = false;
  DateTime? _lastCompletedAt;

  /// Whether a [pullAll] pass is currently in flight (the resume hook
  /// skips instead of stacking a second pass).
  bool get isRunning => _running;

  /// Wall-clock of the last COMPLETED [pullAll] pass — the #3447 resume
  /// debounce anchor. `null` until the first pass finishes.
  DateTime? get lastCompletedAt => _lastCompletedAt;

  /// Every table covered by the current registration — the pull-matrix
  /// test asserts this equals `SyncTables.all`.
  Set<String> get coveredTables =>
      {for (final e in _entries) ...e.tables};

  /// Install the registration list. Idempotent per app run: re-invoking
  /// (e.g. a second `registerPulls` call after a TankSync re-init) replaces
  /// the previous list so entries are never duplicated.
  void register({
    required bool Function() enabled,
    required List<SyncPullEntry> entries,
  }) {
    _enabled = enabled;
    _entries
      ..clear()
      ..addAll(entries);
  }

  /// Reset to the unregistered state — test isolation only.
  @visibleForTesting
  void resetForTest() {
    _entries.clear();
    _enabled = () => false;
    _running = false;
    _lastCompletedAt = null;
  }

  /// Run every registered pull in parallel (#3450). No-ops when the master
  /// gate is off, nothing is registered yet, or a pass is already running.
  ///
  /// Each entry is independently timed out and error-protected: a failure
  /// logs to [ErrorLayer.sync] and never propagates, so one broken table
  /// can't block the rest — and the method itself never throws.
  /// [now] is injectable so the resume-debounce tests can pin
  /// [lastCompletedAt] deterministically.
  Future<void> pullAll({
    LaunchSyncTrace? trace,
    DateTime Function() now = DateTime.now,
  }) async {
    if (_running || _entries.isEmpty) return;
    _running = true;
    try {
      // The gate closure reads providers — a torn-down container must
      // degrade to "skip this pass", not escape the never-throws contract.
      if (!_enabled()) return;
      await Future.wait(_entries.map((e) => _pullOne(e, trace)));
      _lastCompletedAt = now();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'SyncPullCoordinator.pullAll'}));
    } finally {
      _running = false;
    }
  }

  Future<void> _pullOne(SyncPullEntry entry, LaunchSyncTrace? trace) async {
    final name = entry.tables.join('+');
    var pulled = 0;
    await LaunchSyncTrace.spanned(trace, name, () async {
      try {
        pulled = await entry.pull().timeout(entry.timeout);
      } on TimeoutException catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {
          'where': 'sync pull timed out',
          'tables': name,
          'timeoutSeconds': entry.timeout.inSeconds,
        }));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.sync, e, st,
            context: {'where': 'sync pull FAILED', 'tables': name}));
      }
    }, attributes: () => {'table': name, 'pulled': pulled});
  }
}
