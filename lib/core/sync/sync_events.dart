// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Canonical Supabase table names used on the [SyncEvents] bus, matching
/// the `table:`/`.from(...)` literals in the per-entity sync files. Kept
/// here so emitters and subscribers can never drift on spelling.
abstract final class SyncTables {
  static const String favorites = 'favorites';
  static const String ignoredStations = 'ignored_stations';
  static const String stationRatings = 'station_ratings';
  static const String tripSummaries = 'trip_summaries';
  static const String itineraries = 'itineraries';
  static const String alerts = 'alerts';
  static const String vehicles = 'vehicles';
  static const String fillUps = 'fill_ups';
}

/// One "a sync pull wrote rows into local storage" notification (#3446).
@immutable
class SyncTableChanged {
  const SyncTableChanged(this.table, this.changedCount);

  /// The Supabase table whose pulled rows were persisted locally — use
  /// the [SyncTables] constants.
  final String table;

  /// How many local records the pull actually wrote (added or
  /// overwritten). Events with `changedCount <= 0` are dropped by
  /// [SyncEvents.emit], so call sites can emit unconditionally.
  final int changedCount;

  @override
  String toString() => 'SyncTableChanged($table, $changedCount)';
}

/// #3446 — the app-wide sync-events bus: pulled data always refreshes
/// the UI.
///
/// ## The stale-UI class this kills
///
/// Server rows pulled by TankSync land in Hive/local storage, but several
/// feature providers (favorites, ignored stations, station ratings, trip
/// history, itineraries) are one-shot readers of that storage — without a
/// rebuild trigger the pulled data only appeared one app restart later
/// (Epic #3444). This bus is the single rebuild trigger.
///
/// ## Contract for pull paths
///
/// **EVERY pull path that persists rows into local storage MUST [emit] a
/// [SyncTableChanged] AFTER the write completes** — launch merges
/// (`LaunchSyncPhase`), connect-time `_performInitialSync`, the
/// "sync now" gesture, and any future pull trigger. A path that wrote
/// nothing may skip the emit, but emitting a zero count is free: [emit]
/// drops it. Emitting BEFORE the write is a bug — subscribers re-read
/// storage on the event and would still see the stale state.
/// `test/core/sync/sync_events_completeness_test.dart` guards the known
/// persist sites.
///
/// ## Contract for subscribers
///
/// Feature providers subscribe to their own table via [forTable] inside
/// `build()` (cancel with `ref.onDispose`, mirroring the
/// `LiveHarshEventBus` idiom) and re-read LOCAL storage on each event —
/// never the network, so an event can never fan out into request storms
/// or emit loops.
class SyncEvents {
  SyncEvents._();

  /// The app-wide bus. A plain singleton (not a provider) so core sync
  /// code without a `Ref` — `LaunchSyncPhase`, `SyncState` — can emit.
  static final SyncEvents instance = SyncEvents._();

  final StreamController<SyncTableChanged> _controller =
      StreamController<SyncTableChanged>.broadcast();

  /// Every table's change events, in emit order.
  Stream<SyncTableChanged> get stream => _controller.stream;

  /// Only the events for [table] (a [SyncTables] constant).
  Stream<SyncTableChanged> forTable(String table) =>
      stream.where((e) => e.table == table);

  /// Publish [event] to all subscribers. Drops no-op events
  /// (`changedCount <= 0`) so call sites can emit unconditionally after
  /// their persist step.
  void emit(SyncTableChanged event) {
    if (event.changedCount <= 0) return;
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  /// Convenience for the id-set tables (favorites / ignored stations):
  /// emit the symmetric difference between the persisted [before] and
  /// [after] id sets — additions from the server AND tombstone removals
  /// both count as a change the UI must reflect.
  void emitIdSetDelta(
    String table,
    Iterable<String> before,
    Iterable<String> after,
  ) {
    final b = before.toSet();
    final a = after.toSet();
    final changed = a.difference(b).length + b.difference(a).length;
    emit(SyncTableChanged(table, changed));
  }
}
