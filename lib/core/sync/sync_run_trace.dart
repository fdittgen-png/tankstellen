// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../telemetry/collectors/breadcrumb_collector.dart';

/// Sync-run tracing through the breadcrumb pipeline (#3126).
///
/// The sync *success* path used to be invisible: every merge logged via
/// `debugPrint` only — a no-op in release builds — so for "my fill-up
/// disappeared after sync" there was ZERO on-device record of what the
/// last sync uploaded / downloaded / tombstone-filtered.
///
/// [begin] mints a short run id per sync entry point (connect-time
/// `_performInitialSync`, the launch-time entity merges); each table
/// merge then reports its counts via [table]. Both land in
/// [BreadcrumbCollector], whose ring is snapshotted into every recorded
/// `ErrorTrace` — i.e. the exportable error log — so the report can
/// reconstruct which run moved what, per table, instead of guessing.
class SyncRunTrace {
  SyncRunTrace._();

  static final _random = Random();
  static String? _runId;

  /// Optional tap invoked by [table] with the raw per-table counts
  /// (#3445). The launch-sync span recorder installs it while armed so
  /// entity-merge spans carry pushed/pulled row counts without a second
  /// reporting channel; `null` (the default) costs one null check.
  static void Function(
    String table,
    int uploaded,
    int downloaded,
    int tombstoned,
  )? tableSink;

  /// The id of the sync run currently in flight (or the most recent one)
  /// in this session, `null` before the first [begin].
  static String? get currentRunId => _runId;

  /// Mint a fresh run id for a sync pass started by [trigger]
  /// (`'connect'`, `'launch'`, …), breadcrumb it, and return it.
  static String begin(String trigger) {
    final id = List.generate(
      6,
      (_) => '0123456789abcdef'[_random.nextInt(16)],
    ).join();
    _runId = id;
    BreadcrumbCollector.add('sync:run', detail: 'run=$id trigger=$trigger');
    debugPrint('SyncRunTrace: run=$id trigger=$trigger');
    return id;
  }

  /// Report one table merge's counts for the current run:
  /// [uploaded] rows pushed, [downloaded] rows pulled into local state
  /// (server-only + LWW server-newer overwrites), [tombstoned] ids
  /// filtered from the union. A merge with no surrounding [begin] (e.g.
  /// a single-entity pull on a local edit) reports `run=untracked`.
  static void table(
    String tableName, {
    int uploaded = 0,
    int downloaded = 0,
    int tombstoned = 0,
  }) {
    final detail = 'run=${_runId ?? 'untracked'} up=$uploaded '
        'down=$downloaded tomb=$tombstoned';
    BreadcrumbCollector.add('sync:$tableName', detail: detail);
    tableSink?.call(tableName, uploaded, downloaded, tombstoned);
    debugPrint('SyncRunTrace: $tableName $detail');
  }

  /// Clear the current run id between tests.
  @visibleForTesting
  static void resetForTest() => _runId = null;
}
