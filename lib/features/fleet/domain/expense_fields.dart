// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:freezed_annotation/freezed_annotation.dart';

import 'money.dart';

part 'expense_fields.freezed.dart';
part 'expense_fields.g.dart';

/// One reading of a fuel purchase — whatever produced it (#4215).
///
/// The SAME shape carries the machine's read and the human's answer: an
/// [Expense] holds one instance as `extracted` (what OCR or a structured
/// invoice said) and one as `confirmed` (what the employee stands
/// behind). Keeping them in one type is what makes "the employee
/// corrected the litres" a diffable fact rather than a lost edit.
///
/// Every field is nullable because every source is partial: a
/// photographed receipt may carry no VAT line, a structured invoice may
/// carry no odometer. A missing field stays missing — nothing here is
/// derived, and the reconciler decides what an absence means.
///
/// Money is [Money], never a bare double: an expense crosses borders.
/// The fuel grade travels as its `FuelType.apiValue` string rather than
/// a converted object, so the JSON is readable in an export and a grade
/// this build does not know does not break decoding.
@freezed
abstract class ExtractedReceiptFields with _$ExtractedReceiptFields {
  const factory ExtractedReceiptFields({
    /// Station / retailer name as printed.
    String? stationName,

    /// When the purchase happened, per the document.
    DateTime? occurredAt,

    /// `FuelType.apiValue` of the grade, when one was recognised.
    String? fuelApiValue,

    /// Volume dispensed, in litres.
    double? litres,

    /// Unit price per litre in the major unit of [total]'s currency.
    double? pricePerLitre,

    /// Total charged.
    Money? total,

    /// VAT amount as printed — a separate field from [total] and from
    /// any reimbursement figure. ADR 0025: three fields, never one.
    Money? vat,

    /// VAT rate in percent as printed (`20.0`).
    double? vatRate,

    /// Masked payment / fuel-card reference. Never a full card number —
    /// the masking happens in the extractor, not here.
    String? paymentReference,

    /// Odometer in kilometres, when the forecourt printed one.
    double? odometerKm,
  }) = _ExtractedReceiptFields;

  factory ExtractedReceiptFields.fromJson(Map<String, dynamic> json) =>
      _$ExtractedReceiptFieldsFromJson(json);
}

/// What [ExtractedReceiptFields] can be checked and compared on.
extension ExtractedReceiptFieldsX on ExtractedReceiptFields {
  /// The three numbers the arithmetic check needs are all present.
  bool get hasArithmeticInputs =>
      litres != null && pricePerLitre != null && total != null;

  /// `litres × pricePerLitre` in [total]'s currency, or null when an
  /// input is missing. Never written back into [total] — a computed
  /// figure is not what the paper says.
  Money? get predictedTotal {
    final l = litres;
    final p = pricePerLitre;
    final t = total;
    if (l == null || p == null || t == null) return null;
    return Money(amount: l * p, currency: t.currency);
  }

  /// The ISO code the amounts are in, when any amount is known.
  String? get currency => total?.currency ?? vat?.currency;
}

/// One field an employee changed after the machine read it (#4215).
///
/// The correction history is kept ALONGSIDE the extraction, never
/// instead of it: #4215 requires that provenance stays visible, so a
/// later reviewer can see that the litres on the expense are the
/// employee's `42.18` and not the OCR's `4218`. Values are rendered as
/// strings so one uniform, exportable shape covers every field type.
@freezed
abstract class FieldCorrection with _$FieldCorrection {
  const factory FieldCorrection({
    /// The [ExtractedReceiptFields] field name that changed.
    required String field,

    /// The machine's value, as it was rendered. Null when the machine
    /// read nothing and the employee supplied the field.
    String? before,

    /// The employee's value. Null when they cleared the field.
    String? after,

    /// When the correction was made — from the injected clock, in UTC.
    required DateTime correctedAt,

    /// Who made it.
    required String correctedBy,
  }) = _FieldCorrection;

  factory FieldCorrection.fromJson(Map<String, dynamic> json) =>
      _$FieldCorrectionFromJson(json);
}
