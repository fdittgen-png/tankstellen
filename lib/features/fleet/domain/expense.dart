// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/fleet/claim_class.dart';
import 'expense_fields.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

/// Where an expense stands (#4215, ADR 0025 "reimbursement / accounting
/// state boundary").
///
/// Five things are kept apart and none implies the next: a source
/// document exists, a value was extracted, the employee confirmed it,
/// the company approved it, accounting exported it. A receipt being
/// authentic says nothing about reimbursement — which is why a scan can
/// only ever produce [draft] or [needsReview], and why `draft →
/// approved` is not a transition [ExpenseStateMachine] will make.
enum ExpenseStatus {
  /// Extracted and self-consistent; waiting for the employee.
  draft,

  /// Something does not add up, or a required field is missing. The
  /// employee must look before this can move.
  needsReview,

  /// The employee confirmed the values and handed it to the company.
  submitted,

  /// The company accepted it. Still not an accounting record.
  approved,

  /// The company refused it; it can go back to [needsReview].
  rejected,

  /// Handed to the accounting system.
  exported,

  /// Closed; kept for the retention period only.
  archived,
}

/// How the document behind an expense reached the app (#4215).
///
/// This exists because a photographed receipt and an authoritative
/// electronic invoice are NOT equivalent, and the difference must
/// survive in the data rather than being flattened at the UI. France's
/// e-invoicing reform makes structured invoices a routine input from
/// 1 September 2026; the app models the source and lets
/// [Expense.authoritative] say what it is worth.
enum ExpenseImportSource {
  /// A photograph of a paper receipt, read by the on-device OCR.
  ocrPhoto,

  /// A PDF rasterised and read by the same on-device OCR.
  ocrPdf,

  /// The text of a digital receipt (e-mail body, SMS, PDF text layer).
  eReceiptText,

  /// A structured electronic invoice — fields, not pixels.
  structuredInvoice,
}

/// Whether an import source can carry an authoritative document.
extension ExpenseImportSourceRules on ExpenseImportSource {
  /// Only a structured invoice CAN be authoritative; a photograph
  /// never is, however confident the read. [Expense.authoritative]
  /// still has to be set — being structured is necessary, not
  /// sufficient (the sender and the channel decide the rest).
  bool get mayBeAuthoritative => this == ExpenseImportSource.structuredInvoice;
}

/// One recorded move between two [ExpenseStatus] values (#4215).
///
/// Who and when, from the injected clock — an expense's history is the
/// audit trail an approval workflow is judged on, so it may not depend
/// on the wall clock of whichever device happened to run the code.
@freezed
abstract class ExpenseTransition with _$ExpenseTransition {
  const factory ExpenseTransition({
    required ExpenseStatus from,
    required ExpenseStatus to,

    /// UTC, from the injected `AppClock`.
    required DateTime at,

    /// The user who caused the move.
    required String byUserId,

    /// Free-form machine-readable reason (a rejection code, say).
    /// Never user-facing text — the UI renders its own from ARB.
    String? reason,
  }) = _ExpenseTransition;

  factory ExpenseTransition.fromJson(Map<String, dynamic> json) =>
      _$ExpenseTransitionFromJson(json);
}

/// Which company vehicle an expense was booked against, frozen at the
/// moment it was captured (#4215, ADR 0025 D7).
///
/// Assignments are effective-dated and people swap cars. Resolving the
/// vehicle at READ time would silently rewrite last quarter's expenses
/// the day somebody is reassigned — so the answer is copied here once
/// and never recomputed.
@freezed
abstract class FleetAttribution with _$FleetAttribution {
  const factory FleetAttribution({
    required String orgId,
    required String fleetVehicleId,

    /// The `vehicle_assignments` row that justified it, when one did.
    String? assignmentId,

    /// When the attribution was decided — UTC, injected clock.
    required DateTime capturedAt,
  }) = _FleetAttribution;

  factory FleetAttribution.fromJson(Map<String, dynamic> json) =>
      _$FleetAttributionFromJson(json);
}

/// A fuel purchase on its way to becoming an accounting record — and
/// not one yet (#4215, ADR 0025 claim class 4).
///
/// The invariants this type exists to hold:
///
///  * **[extracted] is never overwritten.** The machine's read stays
///    readable next to [confirmed] for the whole life of the expense,
///    and every difference between the two is itemised in
///    [corrections]. "The OCR said 4218 L" must remain answerable.
///  * **[claim] is [ClaimClass.accountingCandidate], always.** Class 4
///    requires a human AND a company before the number means anything;
///    nothing in this slice can promote it.
///  * **[authoritative] is a property of the DOCUMENT, not of the
///    read.** A perfectly parsed photograph is still not an
///    authoritative invoice.
///  * **[fleetAttribution] is a snapshot** — see [FleetAttribution].
///  * **No image bytes.** The document lives in private storage; this
///    object carries [documentId] and nothing else about it, so an
///    expense can be logged, exported and synced without a receipt
///    photo riding along.
@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    required String id,

    /// The organisation the expense belongs to — the tenancy key.
    required String orgId,

    /// The employee who submitted it.
    required String userId,

    /// The fill-up this expense is the receipt FOR, when one matched.
    /// Set by the reconciler's attach path; an expense never creates a
    /// second fill-up for a purchase the user already logged.
    String? fillUpId,

    /// The company vehicle, frozen at capture time.
    FleetAttribution? fleetAttribution,

    /// What the machine read. Immutable for the life of the expense.
    required ExtractedReceiptFields extracted,

    /// What the employee stands behind. Starts equal to [extracted].
    required ExtractedReceiptFields confirmed,

    /// Every difference between [extracted] and [confirmed], in order.
    @Default(<FieldCorrection>[]) List<FieldCorrection> corrections,

    /// The `fleet_documents` row holding the source document. Null for
    /// an expense typed by hand.
    String? documentId,

    /// How the document arrived.
    required ExpenseImportSource importSource,

    /// `true` only for a document the deployment treats as an
    /// authoritative record (a received e-invoice). A scan is never
    /// authoritative, whatever its confidence.
    @Default(false) bool authoritative,

    /// Where it stands. A scan can only produce [ExpenseStatus.draft]
    /// or [ExpenseStatus.needsReview].
    @Default(ExpenseStatus.draft) ExpenseStatus status,

    /// Every state move, with who and when.
    @Default(<ExpenseTransition>[]) List<ExpenseTransition> history,

    /// Claim class 4 — fixed. Present as a field so a persisted row
    /// states it rather than leaving a reader to assume it.
    @Default(ClaimClass.accountingCandidate) ClaimClass claim,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}

/// The questions callers ask an [Expense] without reaching into it.
extension ExpenseX on Expense {
  /// Class 4 always needs a human and a company; spelled out here so a
  /// UI never has to know the claim taxonomy to get the gate right.
  bool get requiresConfirmation => claim.requiresConfirmation;

  /// The employee has changed at least one machine-read field.
  bool get wasCorrected => corrections.isNotEmpty;

  /// Already tied to a logged fill-up — the anti-duplicate signal.
  bool get isAttachedToFillUp => fillUpId != null;

  /// Past the employee's hands. Below this, nothing is owed to anyone.
  bool get isSubmitted =>
      status != ExpenseStatus.draft && status != ExpenseStatus.needsReview;
}
