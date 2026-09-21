// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:tankstellen/features/trips/data/trip_history_repository.dart';

/// A history repository whose [save] parks at a gate (#4162) — "the
/// process is killed at this await". A test waits for [reached], captures
/// the disk, then [release]s the gate so the old process can wind down.
///
/// #4328 — [afterWrite] parks AFTER the row is on disk instead of before
/// it (the kill lands between the history write and the WAL clear), and
/// [fault] makes the gated write throw instead of landing.
class GatedTripHistoryRepository extends TripHistoryRepository {
  GatedTripHistoryRepository({
    required super.box,
    this.afterWrite = false,
    this.fault,
  });

  final bool afterWrite;
  final Exception? fault;

  final Completer<void> _reached = Completer<void>();
  final Completer<void> _release = Completer<void>();

  /// Completes when the first save arrives at the gate.
  Future<void> get reached => _reached.future;

  /// Let the parked save (and every later one) through.
  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<bool> save(TripHistoryEntry entry) async {
    final written = afterWrite ? await super.save(entry) : null;
    if (!_reached.isCompleted) _reached.complete();
    await _release.future;
    final f = fault;
    if (f != null) throw f;
    return written ?? super.save(entry);
  }
}
