// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/expense.dart';
import '../../providers/fleet_expense_providers.dart';
import '../widgets/expense_status_pill.dart';

/// Every fuel expense this device holds, newest first (#4215).
///
/// The employee's side of the workflow, and only theirs: the list is
/// the local store, which holds their own submissions. A manager's
/// queue is a different question with a different answer (an org-wide,
/// draft-free server read) and belongs to the manager surface, not
/// here — ADR 0025's visibility matrix keeps the two apart, and so
/// does this screen.
class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final expenses = ref.watch(fleetExpensesProvider);
    return PageScaffold(
      title: l.fleetExpensesTitle,
      bodyPadding: EdgeInsets.zero,
      body: expenses.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l.fleetExpensesEmptyTitle,
              subtitle: l.fleetExpensesEmptyBody,
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                shellScrollClearance(context),
              ),
              itemCount: expenses.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) =>
                  _ExpenseTile(expense: expenses[index]),
            ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fields = expense.confirmed;
    final total = fields.total;
    return InkWell(
      onTap: () => FleetExpenseReviewRoute(expense.id).push<void>(context),
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fields.stationName ?? l.fleetExpenseUnknownStation,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    total == null
                        ? l.fleetExpenseValueMissing
                        : PriceFormatter.formatTotal(total.amount,
                            currencyOverride: total.currency),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            ExpenseStatusPill(status: expense.status),
          ],
        ),
      ),
    );
  }
}
