// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/fleet_review_transport.dart';
import '../../domain/expense.dart';
import '../../providers/fleet_expense_providers.dart';
import '../../providers/fleet_manager_providers.dart';
import '../widgets/expense_status_pill.dart';

/// The organisation's review queue (#4215 built it, #4216 gives it a
/// screen).
///
/// F7 shipped the server half — the manager SELECT restricted to
/// `status <> 'draft'`, the `fleet_review_expense` RPC and
/// `FleetExpenseWorkflow.reviewQueue` — and left the surface to the
/// manager slice. This is that surface.
///
/// A **draft never appears here**, and the absence is stated in the
/// empty text rather than left as a puzzle: it is the employee's
/// working copy of a photograph of their own payment card, and ADR
/// 0025's visibility matrix stops the manager at "submitted".
///
/// Every decision goes server-first through the workflow. A refusal
/// leaves the expense exactly as it was and says so — a manager whose
/// network dropped must not see an approval the company never made.
class FleetExpenseQueueScreen extends ConsumerWidget {
  const FleetExpenseQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PageScaffold(
      title: l.fleetManagerQueueTitle,
      bodyPadding: EdgeInsets.zero,
      body: ref.watch(fleetReviewQueueProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: l.fleetManagerUnavailableTitle,
              subtitle: l.fleetManagerUnavailableBody,
            ),
            data: (queue) => queue.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_outlined,
                    title: l.fleetManagerQueueEmptyTitle,
                    subtitle: l.fleetManagerQueueEmptyBody,
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      Spacing.lg,
                      Spacing.lg,
                      Spacing.lg,
                      shellScrollClearance(context),
                    ),
                    itemCount: queue.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) =>
                        _QueueTile(expense: queue[index]),
                  ),
          ),
    );
  }
}

class _QueueTile extends ConsumerWidget {
  const _QueueTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fields = expense.confirmed;
    final total = fields.total;
    final canDecide = expense.status == ExpenseStatus.submitted;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fields.stationName ?? l.fleetExpenseUnknownStation,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              ExpenseStatusPill(status: expense.status),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            total == null
                ? l.fleetExpenseValueMissing
                : PriceFormatter.formatTotal(total.amount,
                    currencyOverride: total.currency),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Spacing.xs),
          // #4219: approving is a company decision, not a booking.
          Text(
            l.fleetManagerQueueNotAnApproval,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (canDecide) ...[
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _decide(
                      context, ref, FleetReviewDecision.rejected),
                  child: Text(l.fleetManagerQueueReject),
                ),
                const SizedBox(width: Spacing.md),
                FilledButton(
                  onPressed: () => _decide(
                      context, ref, FleetReviewDecision.approved),
                  child: Text(l.fleetManagerQueueApprove),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Server first, then the local move — and nothing at all when the
  /// server refused (#4215).
  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    FleetReviewDecision decision,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final workflow = ref.read(fleetExpenseWorkflowProvider);
    // Who is deciding, for the history stamp the approval workflow is
    // judged on. The server stamps the audit row from `auth.uid()`
    // independently, so the two cannot be talked out of agreeing.
    final result = await workflow.decide(
      expense,
      decision: decision,
      byUserId: ref.read(fleetActingUserIdProvider),
    );
    if (!context.mounted) return;
    if (!result.isAccepted) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.fleetManagerQueueDecisionFailed)));
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text(decision == FleetReviewDecision.approved
          ? l.fleetManagerQueueApproved
          : l.fleetManagerQueueRejected),
    ));
    // The queue is a server read, so refresh it rather than mutating a
    // local list the server has not agreed with.
    ref.invalidate(fleetReviewQueueProvider);
    // A decision changes what the period reports, and the aggregate is
    // audited on every read — so it is re-read, never patched.
    ref.invalidate(fleetPeriodKpisProvider);
  }
}
