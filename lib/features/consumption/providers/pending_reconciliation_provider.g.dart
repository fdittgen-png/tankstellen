// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_reconciliation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(PendingReconciliations)
final pendingReconciliationsProvider = PendingReconciliationsProvider._();

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
final class PendingReconciliationsProvider
    extends $NotifierProvider<PendingReconciliations, PendingReconciliation?> {
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
  PendingReconciliationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingReconciliationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingReconciliationsHash();

  @$internal
  @override
  PendingReconciliations create() => PendingReconciliations();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingReconciliation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingReconciliation?>(value),
    );
  }
}

String _$pendingReconciliationsHash() =>
    r'40796d569db141ff02094dcd8acb521bfa02f486';

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

abstract class _$PendingReconciliations
    extends $Notifier<PendingReconciliation?> {
  PendingReconciliation? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<PendingReconciliation?, PendingReconciliation?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PendingReconciliation?, PendingReconciliation?>,
              PendingReconciliation?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
