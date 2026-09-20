// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_pill.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/expense.dart';

/// The localized name of an [ExpenseStatus] (#4215).
///
/// One mapping for every fleet surface, so "Submitted" cannot become
/// "Sent" on the next screen — the five states of ADR 0025's
/// accounting boundary only mean something if they are named the same
/// way everywhere.
String expenseStatusLabel(AppLocalizations l, ExpenseStatus status) =>
    switch (status) {
      ExpenseStatus.draft => l.fleetExpenseStatusDraft,
      ExpenseStatus.needsReview => l.fleetExpenseStatusNeedsReview,
      ExpenseStatus.submitted => l.fleetExpenseStatusSubmitted,
      ExpenseStatus.approved => l.fleetExpenseStatusApproved,
      ExpenseStatus.rejected => l.fleetExpenseStatusRejected,
      ExpenseStatus.exported => l.fleetExpenseStatusExported,
      ExpenseStatus.archived => l.fleetExpenseStatusArchived,
    };

/// The localized name of an [ExpenseImportSource] (#4215).
String expenseImportSourceLabel(
  AppLocalizations l,
  ExpenseImportSource source,
) =>
    switch (source) {
      ExpenseImportSource.ocrPhoto => l.fleetExpenseSourceOcrPhoto,
      ExpenseImportSource.ocrPdf => l.fleetExpenseSourceOcrPdf,
      ExpenseImportSource.eReceiptText => l.fleetExpenseSourceEReceipt,
      ExpenseImportSource.structuredInvoice =>
        l.fleetExpenseSourceStructuredInvoice,
    };

/// A passive badge naming where an expense stands (#4215).
///
/// Colour carries the same three-way reading everywhere: the two
/// states that still want something from a human are tinted, the
/// settled ones stay neutral. A rejected claim uses the error pair
/// because it is the one state the employee has to act on again.
class ExpenseStatusPill extends StatelessWidget {
  const ExpenseStatusPill({super.key, required this.status});

  final ExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ExpenseStatus.needsReview => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      ExpenseStatus.rejected => (
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      ExpenseStatus.approved || ExpenseStatus.exported => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return AppPill(
      label: expenseStatusLabel(AppLocalizations.of(context), status),
      background: background,
      foreground: foreground,
    );
  }
}
