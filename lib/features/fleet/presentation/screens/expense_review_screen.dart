// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/expense.dart';
import '../../domain/expense_reconciler.dart';
import '../../providers/fleet_expense_providers.dart';
import '../widgets/expense_review_fields.dart';
import '../widgets/expense_status_pill.dart';

/// The employee's check of a scanned receipt before it becomes a claim
/// (#4215, ADR 0025 reimbursement / accounting state boundary).
///
/// The screen holds no copy of the expense: it looks the record up by
/// id on every build, so a correction made anywhere cannot be rendered
/// stale here, and an id this device does not hold lands on an honest
/// "not on this device" rather than a crash.
///
/// One action, PINNED, and its label says which of the two situations
/// you are in. When the arithmetic reconciles and nothing is missing,
/// the employee confirms in one tap without scrolling — that is the
/// #4215 requirement, and it is why `buildReviewFields` groups the
/// way it does.
/// When it does not, the action is disabled WITH ITS REASON on the
/// button, never a silent grey rectangle.
class ExpenseReviewScreen extends ConsumerWidget {
  const ExpenseReviewScreen({super.key, required this.expenseId});

  /// The record to review. Looked up, never carried.
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final expense = ref.watch(fleetExpenseByIdProvider(expenseId));
    if (expense == null) {
      return PageScaffold(
        title: l.fleetExpenseReviewTitle,
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: l.fleetExpenseNotFound,
        ),
      );
    }
    final arithmetic =
        ref.watch(expenseReconcilerProvider).checkArithmetic(expense.confirmed);
    final groups = groupReviewFields(buildReviewFields(
        expense, arithmetic, l, MaterialLocalizations.of(context)));
    final blocked =
        groups.needsAnswer.isNotEmpty || arithmetic == ExpenseArithmetic.mismatch;
    return PageScaffold(
      title: l.fleetExpenseReviewTitle,
      bodyPadding: EdgeInsets.zero,
      body: _ReviewBody(
        expense: expense,
        arithmetic: arithmetic,
        groups: groups,
      ),
      bottomNavigationBar: _SubmitBar(expense: expense, blocked: blocked),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.expense,
    required this.arithmetic,
    required this.groups,
  });

  final Expense expense;
  final ExpenseArithmetic arithmetic;
  final ({List<ReviewField> needsAnswer, List<ReviewField> read}) groups;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        _ArithmeticNote(arithmetic: arithmetic),
        const SizedBox(height: Spacing.md),
        if (groups.needsAnswer.isNotEmpty) ...[
          SectionCard(
            title: l.fleetExpenseNeedsConfirmationTitle,
            leadingIcon: Icons.error_outline,
            child: ReviewFieldList(fields: groups.needsAnswer, highlight: true),
          ),
          const SizedBox(height: Spacing.md),
        ],
        SectionCard(
          title: l.fleetExpenseReadTitle,
          leadingIcon: Icons.document_scanner_outlined,
          child: ReviewFieldList(fields: groups.read, highlight: false),
        ),
        const SizedBox(height: Spacing.md),
        SectionCard(
          title: l.fleetExpenseDocumentTitle,
          leadingIcon: Icons.folder_outlined,
          child: _DocumentNotes(expense: expense),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          l.fleetExpenseNotAnAccountingRecord,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// What the `litres × price ≈ total` check said, in words.
class _ArithmeticNote extends StatelessWidget {
  const _ArithmeticNote({required this.arithmetic});

  final ExpenseArithmetic arithmetic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, message, tint) = switch (arithmetic) {
      ExpenseArithmetic.reconciled => (
          Icons.check_circle_outline,
          l.fleetExpenseArithmeticOk,
          scheme.onSurfaceVariant,
        ),
      ExpenseArithmetic.mismatch => (
          Icons.report_problem_outlined,
          l.fleetExpenseArithmeticMismatch,
          scheme.error,
        ),
      ExpenseArithmetic.incomplete => (
          Icons.help_outline,
          l.fleetExpenseArithmeticIncomplete,
          scheme.onSurfaceVariant,
        ),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: tint),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            message,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(color: tint),
          ),
        ),
      ],
    );
  }
}

/// Where the expense came from, and what that is worth.
class _DocumentNotes extends StatelessWidget {
  const _DocumentNotes({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                expenseImportSourceLabel(l, expense.importSource),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            ExpenseStatusPill(status: expense.status),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          expense.authoritative
              ? l.fleetExpenseAuthoritative
              : l.fleetExpenseNotAuthoritative,
          style: muted,
        ),
        if (expense.isAttachedToFillUp) ...[
          const SizedBox(height: Spacing.xs),
          Text(l.fleetExpenseAttachedToFillUp, style: muted),
        ],
        const SizedBox(height: Spacing.xs),
        Text(l.fleetExpenseCorrections(expense.corrections.length),
            style: muted),
      ],
    );
  }
}

/// The one action, pinned so it is never a scroll away, with a label
/// that states which situation the employee is in — a disabled button
/// must never leave them guessing.
class _SubmitBar extends ConsumerWidget {
  const _SubmitBar({required this.expense, required this.blocked});

  final Expense expense;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final already = expense.isSubmitted;
    final label = already
        ? l.fleetExpenseAlreadySubmitted
        : blocked
            ? l.fleetExpenseFixFirst
            : l.fleetExpenseConfirmAndSubmit;
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: FilledButton.icon(
            onPressed: already || blocked ? null : () => _submit(context, ref),
            icon: const Icon(Icons.send_outlined),
            label: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    // #3159 — capture everything that needs the element BEFORE the
    // await: the screen can be popped out from under the write.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final submitted = ref
        .read(fleetExpenseWorkflowProvider)
        .confirmAndSubmit(expense, byUserId: expense.userId)
        .expense;
    if (submitted == null) {
      messenger
          .showSnackBar(SnackBar(content: Text(l.fleetExpenseSubmitFailed)));
      return;
    }
    await ref.read(fleetExpensesProvider.notifier).upsert(submitted);
    if (navigator.canPop()) navigator.pop();
  }
}
