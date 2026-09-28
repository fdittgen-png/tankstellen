// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Labelling a pre-#4136 history in bulk — as an explicit statement by
/// the driver, never as a guess (#4406).
///
/// `FillUp.currency` is null on every fill logged before the currency
/// stamp, and #4364 rightly treats null as UNKNOWN: a history mixing
/// stamped and unstamped fills withholds its money totals. The fix only
/// the driver can supply is the missing fact — "my fills up to *date*
/// were all in *currency*". This file turns that sentence into record
/// changes with three guarantees:
///
///  1. **Nothing is inferred.** The currency and the cut-off are
///     parameters. No default is read from the active country, the
///     profile or today — the caller's UI offers no preselection either.
///  2. **Only the label moves.** Litres, distance, odometer, amounts and
///     every other field are untouched; a record that already carries a
///     currency is never relabelled.
///  3. **It is reversible.** Every record it labels carries
///     `FillUp.currencyStatedAt`, the instant of the statement, so
///     [revertCurrencyBackfill] can return exactly those records — and no
///     others — to unknown.
library;

import 'entities/fill_up.dart';

/// Whether [f] has no recorded currency.
bool hasUnknownCurrency(FillUp f) =>
    f.currency == null || f.currency!.trim().isEmpty;

/// The end of [day]'s calendar day — a statement "on or before 12 May"
/// covers a fill logged at 18:40 that day.
DateTime _endOfDay(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1)
        .subtract(const Duration(microseconds: 1));

/// The records a statement "fills on or before [onOrBefore]" would label.
List<FillUp> currencyBackfillCandidates(
  Iterable<FillUp> fillUps, {
  required DateTime onOrBefore,
}) {
  final cutoff = _endOfDay(onOrBefore);
  return [
    for (final f in fillUps)
      if (hasUnknownCurrency(f) && !f.date.isAfter(cutoff)) f,
  ];
}

/// How many PRICED real fills carry no currency — the ones that hold a
/// money total back (#4364). Corrections carry no money and do not count.
int unknownCurrencyPricedFillCount(Iterable<FillUp> fillUps) => fillUps
    .where((f) => !f.isCorrection && f.totalCost > 0 && hasUnknownCurrency(f))
    .length;

/// The outcome of one bulk statement.
class CurrencyBackfill {
  const CurrencyBackfill({required this.labelled, required this.remaining});

  /// The records that changed, each with its new label and
  /// [FillUp.currencyStatedAt] stamp. Only these need saving.
  final List<FillUp> labelled;

  /// Priced real fills that are STILL unknown after the statement —
  /// reported as a count, never guessed (#4406).
  final int remaining;
}

/// Apply the statement "every unlabelled fill on or before [onOrBefore]
/// was paid in [currency]", made at [statedAt].
CurrencyBackfill applyCurrencyBackfill(
  List<FillUp> fillUps, {
  required String currency,
  required DateTime onOrBefore,
  required DateTime statedAt,
}) {
  final code = currency.trim().toUpperCase();
  if (code.isEmpty) {
    throw ArgumentError.value(currency, 'currency', 'must name an ISO code');
  }
  final targets = {
    for (final f in currencyBackfillCandidates(fillUps, onOrBefore: onOrBefore))
      f.id,
  };
  final labelled = <FillUp>[];
  final after = <FillUp>[];
  for (final f in fillUps) {
    if (targets.contains(f.id)) {
      final changed = f.copyWith(currency: code, currencyStatedAt: statedAt);
      labelled.add(changed);
      after.add(changed);
    } else {
      after.add(f);
    }
  }
  return CurrencyBackfill(
    labelled: List.unmodifiable(labelled),
    remaining: unknownCurrencyPricedFillCount(after),
  );
}

/// The records a bulk statement labelled, returned to unknown — the undo
/// of [applyCurrencyBackfill]. A currency the record carried on its own
/// (stamped at entry, or chosen on its settle sheet) is left alone.
List<FillUp> revertCurrencyBackfill(Iterable<FillUp> fillUps) => [
      for (final f in fillUps)
        if (f.currencyStatedAt != null)
          f.copyWith(currency: null, currencyStatedAt: null),
    ];

/// How many records carry a bulk-stated currency.
int statedCurrencyFillCount(Iterable<FillUp> fillUps) =>
    fillUps.where((f) => f.currencyStatedAt != null).length;
