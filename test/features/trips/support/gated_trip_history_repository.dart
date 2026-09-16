// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:tankstellen/features/trips/data/trip_history_repository.dart';

/// A history repository whose [save] parks at a gate (#4162) — "the
/// process is killed at this await". A test waits for [reached], captures
/// the disk, then [release]s the gate so the old process can wind down.
class GatedTripHistoryRepository extends TripHistoryRepository {
  GatedTripHistoryRepository({required super.box});

  final Completer<void> _reached = Completer<void>();
  final Completer<void> _release = Completer<void>();

  /// Completes when the first save arrives at the gate.
  Future<void> get reached => _reached.future;

  /// Let the parked save (and every later one) through.
  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<void> save(TripHistoryEntry entry) async {
    if (!_reached.isCompleted) _reached.complete();
    await _release.future;
    return super.save(entry);
  }
}
