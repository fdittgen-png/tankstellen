// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/expense.dart';
import '../../domain/expense_reconciler.dart';
import '../../domain/money.dart';

/// One row of the review list: what the field is, what was read, and
/// whether the employee still has to answer for it (#4215).
typedef ReviewField = ({String label, String? value, bool needsAnswer});

/// The ten receipt facts, in reading order, each paired with whether it
/// still wants an answer (#4215).
///
/// #4215 asks for fields "grouped by confidence", with only the
/// uncertain ones highlighted. On a fuel receipt confidence is not a
/// per-character score — it is whether the value is THERE, and whether
/// the three numbers that must agree do agree. So:
///
///  * a field the document did not yield needs an answer;
///  * when the arithmetic does not reconcile, all three participants
///    need one, even though each was read: exactly one of them is
///    wrong, the machine cannot say which, and pointing at the wrong
///    number would be worse than pointing at all three;
///  * VAT, its rate, the payment reference and the odometer never
///    block a submission. They are not part of the sum and a receipt
///    that omits them is an ordinary receipt.
///
/// Pure apart from its two localization arguments, so the grouping is
/// testable without pumping a widget.
List<ReviewField> buildReviewFields(
  Expense expense,
  ExpenseArithmetic arithmetic,
  AppLocalizations l,
  MaterialLocalizations dates,
) {
  final f = expense.confirmed;
  final suspect = arithmetic == ExpenseArithmetic.mismatch;
  String? money(Money? value) => value == null
      ? null
      : PriceFormatter.formatTotal(value.amount,
          currencyOverride: value.currency);
  return [
    (
      label: l.fleetExpenseFieldStation,
      value: f.stationName,
      needsAnswer: f.stationName == null,
    ),
    (
      label: l.fleetExpenseFieldDate,
      value: f.occurredAt == null
          ? null
          : dates.formatFullDate(f.occurredAt!.toLocal()),
      needsAnswer: f.occurredAt == null,
    ),
    (
      label: l.fleetExpenseFieldFuel,
      value: f.fuelApiValue,
      needsAnswer: f.fuelApiValue == null,
    ),
    (
      label: l.fleetExpenseFieldLitres,
      value: f.litres == null ? null : UnitFormatter.formatVolume(f.litres),
      needsAnswer: f.litres == null || suspect,
    ),
    (
      label: l.fleetExpenseFieldPricePerLitre,
      value: f.pricePerLitre == null
          ? null
          : UnitFormatter.formatDecimal(f.pricePerLitre, fractionDigits: 3),
      needsAnswer: f.pricePerLitre == null || suspect,
    ),
    (
      label: l.fleetExpenseFieldTotal,
      value: money(f.total),
      needsAnswer: f.total == null || suspect,
    ),
    (label: l.fleetExpenseFieldVat, value: money(f.vat), needsAnswer: false),
    (
      label: l.fleetExpenseFieldVatRate,
      value: f.vatRate == null
          ? null
          : UnitFormatter.formatDecimal(f.vatRate, fractionDigits: 1),
      needsAnswer: false,
    ),
    (
      label: l.fleetExpenseFieldPaymentReference,
      value: f.paymentReference,
      needsAnswer: false,
    ),
    (
      label: l.fleetExpenseFieldOdometer,
      value: f.odometerKm == null
          ? null
          : UnitFormatter.formatDecimal(f.odometerKm, fractionDigits: 0),
      needsAnswer: false,
    ),
  ];
}

/// Split [fields] into "the machine answered this" and "you still have
/// to", preserving reading order in both.
({List<ReviewField> needsAnswer, List<ReviewField> read}) groupReviewFields(
  List<ReviewField> fields,
) =>
    (
      needsAnswer: [for (final f in fields) if (f.needsAnswer) f],
      read: [for (final f in fields) if (!f.needsAnswer) f],
    );

/// A label/value list; [highlight] paints the values that still want an
/// answer in the error colour rather than hiding them.
///
/// Both columns are [Expanded] and neither is capped at one line: a
/// station name, a masked card reference and a 2.0-scale label all have
/// to be READ, and a review screen that ellipsises the number under
/// review defeats its own purpose.
class ReviewFieldList extends StatelessWidget {
  const ReviewFieldList({
    super.key,
    required this.fields,
    required this.highlight,
  });

  final List<ReviewField> fields;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    field.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    field.value ?? l.fleetExpenseValueMissing,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: highlight
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
