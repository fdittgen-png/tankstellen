// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'package:hive/hive.dart';

/// Contention is distinct from an absent/corrupt record during a full export.
class HiveBoxSnapshotConflict implements Exception {
  const HiveBoxSnapshotConflict();
  @override
  String toString() => 'Trip history changed during snapshot collection';
}

/// Shared mutation fence for repositories over the same Hive box (#4504).
/// Reads wait through multi-step writes and reject snapshots collected across
/// another write, including a failed write or an erased/replaced row.
class HiveBoxMutationEpoch {
  static final _epochs = Expando<HiveBoxMutationEpoch>();
  static HiveBoxMutationEpoch of(BoxBase<dynamic> box) =>
      _epochs[box] ??= HiveBoxMutationEpoch();

  static const maxSnapshotAttempts = 3;
  int _generation = 0;
  int get generation => _generation;
  int _pending = 0;
  Completer<void>? _idle;
  bool get isIdle => _pending == 0;
  Future<void> get whenIdle => _idle?.future ?? Future<void>.value();

  Future<T> mutate<T>(Future<T> Function() write) async {
    _generation++;
    if (_pending++ == 0) _idle = Completer<void>();
    try {
      return await write();
    } finally {
      _generation++;
      if (--_pending == 0) {
        final idle = _idle;
        _idle = null;
        idle!.complete();
      }
    }
  }

  Future<T> snapshot<T>(Future<T> Function() read) async {
    for (var attempt = 0; attempt < maxSnapshotAttempts; attempt++) {
      await whenIdle;
      final before = generation;
      final result = await read();
      if (before == generation && isIdle) return result;
    }
    throw const HiveBoxSnapshotConflict();
  }
}
