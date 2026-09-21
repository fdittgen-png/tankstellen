// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import 'expense.dart';
import 'expense_fields.dart';

/// What the arithmetic on a receipt says (#4215).
enum ExpenseArithmetic {
  /// `litres × price/L` matches the printed total inside the
  /// currency's tolerance.
  reconciled,

  /// The three numbers are all present and do NOT agree. The read is
  /// wrong somewhere; a human has to look.
  mismatch,

  /// At least one of the three is missing, so there is nothing to
  /// check. Not the same as agreeing — and not the same as failing.
  incomplete,
}

/// What happened when a scanned receipt was offered to the device.
enum ExpenseIntakeOutcome {
  /// Nothing matched; this is a new expense.
  created,

  /// A fill-up the user had already logged is the same purchase, so
  /// the expense points at it instead of inventing a second one.
  attachedToFillUp,

  /// The same receipt again (same document hash, or the same purchase
  /// down to the field). The EXISTING expense is returned.
  duplicate,
}

/// An expense already on the device, paired with the hash of the
/// document it came from (null when it was typed by hand).
typedef StoredExpense = ({Expense expense, String? documentSha256});

/// The reconciler's answer: the expense to keep, why, and what the
/// arithmetic said about it.
class ExpenseIntakeResult {
  const ExpenseIntakeResult({
    required this.expense,
    required this.outcome,
    required this.arithmetic,
  });

  /// The expense the caller should persist. For
  /// [ExpenseIntakeOutcome.duplicate] this is the EXISTING one — never
  /// a second row for the same purchase.
  final Expense expense;

  final ExpenseIntakeOutcome outcome;
  final ExpenseArithmetic arithmetic;

  /// `true` when this intake added nothing new to the device.
  bool get isDuplicate => outcome == ExpenseIntakeOutcome.duplicate;
}

/// Decides whether a freshly-read receipt adds up, whether the app has
/// already seen it, and whether it belongs to a fill-up the user
/// logged themselves (#4215).
///
/// Three separate questions, deliberately not collapsed into one:
///
///  1. **Does it add up?** `litres × price/L ≈ total`, within a
///     tolerance derived from the CURRENCY (a Czech receipt is printed
///     to the whole koruna; a euro one to the cent) and from the
///     rounding the forecourt itself applies. A mismatch never becomes
///     a silent correction — it becomes [ExpenseStatus.needsReview].
///  2. **Have we seen this document?** Same SHA-256, or the same
///     purchase field-for-field. Either way the existing expense wins
///     and the new read attaches to it.
///  3. **Did the user already log this fill-up?** Then the expense
///     points at it. #4215: "a receipt cannot silently create a
///     different fill-up than the employee sees".
///
/// The four facts the reconciler needs about an existing fill-up, as
/// plain values (#4215).
///
/// It deliberately does NOT take `FillUp`. The fleet feature is a leaf
/// of the dependency graph — `fill_ups` imports `fleet` for the
/// vehicle attribution a record is stamped with (#4213), so a
/// `fleet -> fill_ups` import would close a cycle that
/// `feature_boundary_test`'s barrel-aware SCC gate (#4346) rejects, and
/// that nobody could break later without moving a type.
///
/// The caller maps its own rows into this; matching a purchase needs a
/// time, a volume and optionally a station name, not a fill-up.
@immutable
class FillUpMatchCandidate {
  const FillUpMatchCandidate({
    required this.id,
    required this.date,
    required this.liters,
    this.stationName,
  });

  /// Identifies the row to attach to; opaque here.
  final String id;
  final DateTime date;
  final double liters;
  final String? stationName;
}

/// Pure and clock-free: every timestamp it needs arrives on the values
/// it is given. Nothing here throws — a receipt that makes no sense is
/// an outcome, not an exception.
class ExpenseReconciler {
  const ExpenseReconciler({
    this.fillUpDateWindow = const Duration(hours: 12),
    this.fillUpLitreTolerance = 0.5,
  });

  /// How far a logged fill-up's timestamp may sit from the receipt's
  /// and still be the same purchase. Twelve hours covers a receipt
  /// logged "that evening" and a timestamp printed in local time while
  /// the fill-up was stamped in UTC.
  final Duration fillUpDateWindow;

  /// How many litres apart the two records may be — the pump prints
  /// two decimals and people round when they type.
  final double fillUpLitreTolerance;

  /// The largest difference between `litres × price/L` and the printed
  /// total that is still rounding rather than a misread.
  ///
  /// Two terms, both real:
  ///  * `2 × minorUnit` — the forecourt rounds the total to the
  ///    currency's smallest unit, and the read may be off by one step
  ///    at either end (five centimes in CHF, a whole koruna in CZK);
  ///  * `litres × halfUnitPriceStep` — a unit price printed to three
  ///    decimals is itself rounded, and that error is multiplied by
  ///    every litre dispensed (≈ 2.5 cents over a 50 L fill).
  static double toleranceFor(ExtractedReceiptFields fields) {
    final unit = fields.total?.minorUnit ?? 0.01;
    final litres = fields.litres ?? 0;
    return 2 * unit + litres * _halfUnitPriceStep;
  }

  /// Half of the last printed digit of a per-litre price (3 decimals).
  static const double _halfUnitPriceStep = 0.0005;

  /// Binary floating point cannot represent 0.01, so `85.01 - 85.00`
  /// is 0.010000000000005 and an exact `<=` against one minor unit
  /// rejects a receipt that matches to the cent. This epsilon is the
  /// representation error, nothing more — it is nine orders of
  /// magnitude below any tolerance it is added to.
  static const double _floatSlack = 1e-9;

  /// Whether the three printed numbers agree.
  ExpenseArithmetic checkArithmetic(ExtractedReceiptFields fields) {
    final predicted = fields.predictedTotal;
    final total = fields.total;
    if (predicted == null || total == null) return ExpenseArithmetic.incomplete;
    final delta = (predicted.amount - total.amount).abs();
    return delta <= toleranceFor(fields) + _floatSlack
        ? ExpenseArithmetic.reconciled
        : ExpenseArithmetic.mismatch;
  }

  /// The status a freshly-read receipt may take.
  ///
  /// Only two are reachable: ADR 0025 is explicit that receipt
  /// presence never sets anything past [ExpenseStatus.draft], so this
  /// returns [ExpenseStatus.draft] or [ExpenseStatus.needsReview] and
  /// nothing else. Anything the employee has to look at — an
  /// arithmetic mismatch, a missing number, no currency — lands in
  /// review rather than being quietly accepted.
  ExpenseStatus statusForIntake(ExtractedReceiptFields fields) {
    switch (checkArithmetic(fields)) {
      case ExpenseArithmetic.mismatch:
      case ExpenseArithmetic.incomplete:
        return ExpenseStatus.needsReview;
      case ExpenseArithmetic.reconciled:
        return fields.occurredAt == null
            ? ExpenseStatus.needsReview
            : ExpenseStatus.draft;
    }
  }

  /// The fill-up [fields] describes, or null when none of [candidates]
  /// is the same purchase.
  ///
  /// A candidate has to match on time AND volume. The station name is
  /// corroborating only: when both sides name one they must agree, but
  /// a fill-up logged with no station never blocks the match — the
  /// common case is a user who typed litres and price and nothing else.
  FillUpMatchCandidate? findFillUpMatch(
    ExtractedReceiptFields fields,
    List<FillUpMatchCandidate> candidates,
  ) {
    final at = fields.occurredAt;
    final litres = fields.litres;
    if (at == null || litres == null) return null;
    FillUpMatchCandidate? best;
    Duration? bestGap;
    for (final candidate in candidates) {
      final gap = candidate.date.difference(at).abs();
      if (gap > fillUpDateWindow) continue;
      if ((candidate.liters - litres).abs() > fillUpLitreTolerance) continue;
      if (!_stationsAgree(fields.stationName, candidate.stationName)) continue;
      if (bestGap == null || gap < bestGap) {
        best = candidate;
        bestGap = gap;
      }
    }
    return best;
  }

  /// The expense among [existing] that is the same receipt as
  /// [candidate], or null when this one is new.
  ///
  /// The hash is checked first because it is exact: the same file
  /// imported twice is the same document whatever the OCR made of it.
  /// The field comparison catches the other case — the same receipt
  /// photographed twice produces two different files and one purchase.
  Expense? findDuplicate(
    List<StoredExpense> existing, {
    required Expense candidate,
    String? documentSha256,
  }) {
    if (documentSha256 != null && documentSha256.isNotEmpty) {
      for (final stored in existing) {
        if (stored.documentSha256 == documentSha256) return stored.expense;
      }
    }
    for (final stored in existing) {
      if (stored.expense.orgId != candidate.orgId) continue;
      if (_samePurchase(stored.expense.confirmed, candidate.confirmed)) {
        return stored.expense;
      }
    }
    return null;
  }

  /// The whole intake decision for one freshly-read [candidate].
  ///
  /// Order matters and is the point: a duplicate is settled BEFORE a
  /// fill-up match, so re-scanning a receipt that is already attached
  /// cannot detach it or produce a rival expense.
  ExpenseIntakeResult intake(
    Expense candidate, {
    List<StoredExpense> existing = const [],
    List<FillUpMatchCandidate> fillUps = const [],
    String? documentSha256,
  }) {
    final arithmetic = checkArithmetic(candidate.confirmed);
    final duplicate = findDuplicate(existing,
        candidate: candidate, documentSha256: documentSha256);
    if (duplicate != null) {
      return ExpenseIntakeResult(
        // The new document is adopted only when the kept expense had
        // none; an existing document is never replaced behind the
        // employee's back.
        expense: duplicate.documentId == null && candidate.documentId != null
            ? duplicate.copyWith(documentId: candidate.documentId)
            : duplicate,
        outcome: ExpenseIntakeOutcome.duplicate,
        arithmetic: arithmetic,
      );
    }
    final status = statusForIntake(candidate.confirmed);
    final match = findFillUpMatch(candidate.confirmed, fillUps);
    if (match != null) {
      return ExpenseIntakeResult(
        expense: candidate.copyWith(fillUpId: match.id, status: status),
        outcome: ExpenseIntakeOutcome.attachedToFillUp,
        arithmetic: arithmetic,
      );
    }
    return ExpenseIntakeResult(
      expense: candidate.copyWith(status: status),
      outcome: ExpenseIntakeOutcome.created,
      arithmetic: arithmetic,
    );
  }

  /// Two field sets describe the same purchase: same day, same litres
  /// to the printed decimal, same total to the currency's unit.
  bool _samePurchase(ExtractedReceiptFields a, ExtractedReceiptFields b) {
    final at = a.occurredAt;
    final bt = b.occurredAt;
    if (at == null || bt == null) return false;
    if (at.toUtc().difference(bt.toUtc()).abs() > fillUpDateWindow) {
      return false;
    }
    final al = a.litres;
    final bl = b.litres;
    if (al == null || bl == null || (al - bl).abs() > 0.011) return false;
    final atotal = a.total;
    final btotal = b.total;
    if (atotal == null || btotal == null) return false;
    if (atotal.currency.toUpperCase() != btotal.currency.toUpperCase()) {
      return false;
    }
    return (atotal.amount - btotal.amount).abs() <=
        atotal.minorUnit + _floatSlack;
  }

  /// Station names corroborate when both are known; an unknown one on
  /// either side is not evidence against the match.
  bool _stationsAgree(String? a, String? b) {
    final left = _normaliseStation(a);
    final right = _normaliseStation(b);
    if (left == null || right == null) return true;
    return left.contains(right) || right.contains(left);
  }

  String? _normaliseStation(String? raw) {
    if (raw == null) return null;
    final folded =
        raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return folded.isEmpty ? null : folded;
  }
}
