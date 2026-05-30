// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/pending_reconciliation.dart';

part 'pending_reconciliation_provider.g.dart';

/// Holds the most recent pending reconciliation gap surfaced by the
/// detector (Epic #2439 / #2441).
///
/// This is the read-side seam the guided reconciliation workflow
/// (#2442) will consume: when `Reconciler.reconcile` returns a created
/// action, `FillUpList` publishes the [PendingReconciliation] here
/// BEFORE applying it. Today the apply-step still performs the silent
/// auto-save (behaviour-neutral — see `FillUpList.applyReconciliation`),
/// so exposing the pending gap changes nothing the user sees; it is
/// purely a hook the workflow will later take over.
///
/// Only the most recent gap is retained. Cleared to `null` for every
/// non-created outcome (skipped / negative / no-trips / no gap) so a
/// stale gap never lingers after a window that needs no correction.
@Riverpod(keepAlive: true)
class PendingReconciliations extends _$PendingReconciliations {
  @override
  PendingReconciliation? build() => null;

  /// Publish the latest pending gap. Pass `null` to clear when the
  /// most recent window produced no correction.
  void set(PendingReconciliation? pending) {
    state = pending;
  }
}
