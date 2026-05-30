// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/fill_up.dart';
import '../../domain/entities/pending_reconciliation.dart';
import '../../domain/reconciliation_resolution.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/pending_reconciliation_provider.dart';
import 'guided_reconciliation_workflow.dart';

/// Raises the guided reconciliation workflow (Epic #2439 / #2442) when
/// the just-completed plein save published a pending gap for the same
/// vehicle, then applies the user's chosen resolution via the single
/// apply seam in [FillUpList]. No-op (returns immediately) when no gap
/// was published — the common case.
///
/// Extracted from `add_fill_up_screen.dart` so the save flow stays lean
/// and the workflow trigger is independently testable. The caller passes
/// a still-mounted [BuildContext] (it raises a dialog) and the [ref] it
/// reads providers from; it must re-check `mounted` itself after this
/// returns, since the dialog awaits user input.
///
/// NEVER silent: a correction or virtual trajet is created ONLY when the
/// user completes the workflow. "Decide later" / dismiss leaves the
/// pending gap intact (#2445 owns the re-entry surface).
Future<void> runReconciliationWorkflowIfPending({
  required BuildContext context,
  required WidgetRef ref,
  required FillUp savedFillUp,
}) async {
  final pending = ref.read(pendingReconciliationsProvider);
  if (pending == null) return;
  // Only resolve a gap that belongs to the vehicle the user just
  // filled — a stale gap from a different vehicle must not hijack this
  // save.
  if (pending.vehicleId != savedFillUp.vehicleId) return;

  await runReconciliationWorkflow(
    context: context,
    ref: ref,
    pending: pending,
  );
}

/// Re-opens the guided reconciliation workflow for an EXISTING pending
/// gap and applies the chosen resolution. This is the shared seam behind
/// both entry points (#2445):
///
///   * the post-plein launcher ([runReconciliationWorkflowIfPending]),
///     which raises it automatically when a fresh gap was published, and
///   * the persistent **'Resolve gap'** affordance on the consumption
///     stats card, which lets the user return to a gap they chose to
///     "Decide later" on — the decision is never lost.
///
/// NEVER silent: a correction or virtual trajet is created ONLY when the
/// user completes the workflow. "Decide later" / dismiss leaves [pending]
/// intact so the affordance keeps offering re-entry.
Future<void> runReconciliationWorkflow({
  required BuildContext context,
  required WidgetRef ref,
  required PendingReconciliation pending,
}) async {
  final locale = Localizations.localeOf(context).toString();
  final nf = NumberFormat.decimalPattern(locale)..maximumFractionDigits = 1;
  final defaultDistanceKm = virtualDistanceEstimateKm(pending);

  final resolution = await showGuidedReconciliationWorkflow(
    context: context,
    pumpedText: nf.format(pending.pumped),
    consumedText: nf.format(pending.consumed),
    gapText: nf.format(pending.gap),
    gapLiters: pending.gap,
    defaultDistanceKm: defaultDistanceKm,
  );

  final notifier = ref.read(fillUpListProvider.notifier);
  switch (resolution.path) {
    case ReconciliationPath.correctFillUp:
      await notifier.applyReconciliation(
        pending.correction.copyWith(
          liters: resolution.correctionLiters ?? pending.gap,
        ),
      );
    case ReconciliationPath.virtualTrajet:
      await notifier.applyVirtualTrajet(
        pending: pending,
        gapLiters: pending.gap,
        distanceKm: resolution.virtualDistanceKm ?? defaultDistanceKm,
      );
    case ReconciliationPath.deferred:
      // Nothing to apply — the pending gap is intentionally kept (#2445
      // owns the re-entry surface).
      break;
  }
}

/// Seed the editable "how far was the unrecorded drive?" field (#2444).
/// We can't know the exact missing distance, so we estimate it from the
/// gap litres at a nominal mid-range consumption (7 L/100 km) — the user
/// adjusts it in the workflow. Rounded to the nearest km so the prefill
/// reads cleanly.
double virtualDistanceEstimateKm(PendingReconciliation pending) {
  const nominalLPer100Km = 7.0;
  return (pending.gap / nominalLPer100Km * 100).roundToDouble();
}
