// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

/// Thrown by a sync seam when the pull pass that opened it has been
/// abandoned (#4377): its per-table generation is no longer the current
/// one, so the answer it is about to hand back — or the write it is about
/// to send — belongs to a pass the coordinator already gave up on.
class SyncPullAbandonedException implements Exception {
  const SyncPullAbandonedException(this.tables, this.generation);

  /// The entry's tables, joined with `+` (the coordinator's entry name).
  final String tables;

  /// The generation the abandoned pass held.
  final int generation;

  @override
  String toString() => 'SyncPullAbandonedException: the $tables pull '
      '(generation $generation) was abandoned by its timeout — its result '
      'is discarded, not persisted';
}

/// #4377 — the generation token of one registered pull in one pass.
///
/// `Future.timeout` abandons a future without cancelling it: the pull
/// keeps running on the wire, the pass ends (`completedWithTimeouts`) and
/// releases the coordinator, the next resume or "sync now" pass starts
/// the same table again — and when the abandoned select finally answers,
/// both persist the same table from different snapshots (S6 in the #4162
/// lifecycle suite). The coordinator therefore mints one lease per entry
/// per pass and carries it in the [Zone] the pull runs in — the way
/// `RunScope` carries the run id — so every transport call inside the
/// pull, however deep, can ask whether its pass is still the current one
/// without a parameter threaded through every merge signature. A timeout
/// retires the lease; the next pass mints a newer generation; a check on
/// a retired lease throws [SyncPullAbandonedException], and the merge it
/// interrupts returns its input unchanged — nothing is written.
class SyncPullLease {
  SyncPullLease({
    required this.tables,
    required this.generation,
    required this._isCurrent,
    required this._onDiscarded,
  });

  /// The zone key the ambient lease lives under.
  static const Symbol zoneKey = #tankstellenSyncPullLease;

  /// The lease of the pull pass this code runs inside, or null outside
  /// any coordinated pull (a single-entity upload on a local edit, a
  /// test driving a merge directly).
  static SyncPullLease? get current =>
      Zone.current[zoneKey] as SyncPullLease?;

  /// The entry's tables, joined with `+`.
  final String tables;

  /// This pass's generation for [tables]; the coordinator's counter.
  final int generation;

  final bool Function() _isCurrent;
  final void Function(SyncPullLease lease, StackTrace stack) _onDiscarded;
  bool _reported = false;

  /// Whether this lease still names the table's current generation.
  bool get isLive => _isCurrent();

  /// Refuse to go on when the pass this lease belongs to was abandoned:
  /// the first refusal is reported to the coordinator with the stack it
  /// happened on (logged, breadcrumbed, counted); every refusal throws
  /// [SyncPullAbandonedException]. A live lease returns at once.
  void checkLive() {
    if (_isCurrent()) return;
    if (!_reported) {
      _reported = true;
      _onDiscarded(this, StackTrace.current);
    }
    throw SyncPullAbandonedException(tables, generation);
  }

  /// Run [body] with this lease as the ambient [current] one.
  Future<T> run<T>(Future<T> Function() body) =>
      runZoned(body, zoneValues: {zoneKey: this});
}
