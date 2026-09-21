// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../ocr/pump_ocr_config.dart';
import 'receipt_field_extractors.dart';
import 'receipt_spatial_lexicon.dart';

/// The FISCAL half of a fuel receipt (#4215, F5): VAT, the ISO currency
/// the amounts are denominated in, the payment/fuel-card reference and
/// the odometer reading — everything an expense needs that the
/// consumption path never asked for.
///
/// Read from the SAME text the shipped parsers already read; no second
/// OCR engine, no second pass over pixels. The VAT line is found with
/// the existing multi-language, edit-distance-1 label lexicon
/// ([classifySpatialLabel] — `TVA` / `MwSt` / `IVA` / `VAT` / `DPH` /
/// `MVA` / `MOMS`), which is also what keeps a VAT row out of the
/// transaction fields in the spatial parser. One lexicon, one meaning.
///
/// Three rules are deliberate and tested:
///
///  * **The currency is an ISO 4217 code, never a symbol.** `€` on the
///    paper becomes `EUR`; an expense that stores `€` cannot be summed
///    with one that stores `EUR`, and `kr` alone does not say which of
///    DKK / SEK / NOK it is (it resolves from the threaded profile or
///    stays null).
///  * **A payment reference is minimised on the way in.** A full card
///    number is never returned: any 12-19 digit run and any masked form
///    collapse to the last four digits behind `****` before the value
///    leaves this file (GDPR data minimisation, ADR 0025 D9).
///  * **Nothing is derived.** A field that is not printed stays null;
///    the reconciler decides what a missing field means.
class ReceiptFiscalFields {
  const ReceiptFiscalFields({
    this.vatAmount,
    this.vatRate,
    this.currency,
    this.paymentReference,
    this.odometerKm,
  });

  /// Nothing fiscal was printed (or nothing was read).
  static const ReceiptFiscalFields none = ReceiptFiscalFields();

  /// VAT amount in the major unit of [currency], as printed.
  final double? vatAmount;

  /// VAT rate in percent (`20.0` for `TVA 20,00 %`), as printed.
  final double? vatRate;

  /// ISO 4217 code (`EUR`, `GBP`, …) — never a symbol.
  final String? currency;

  /// Masked payment / fuel-card reference (`****1234`) or the printed
  /// document reference (`0042-115`). Never a full card number.
  final String? paymentReference;

  /// Odometer reading in kilometres when the forecourt printed one.
  final double? odometerKm;

  /// `true` when at least one fiscal field was read.
  bool get hasData =>
      vatAmount != null ||
      vatRate != null ||
      currency != null ||
      paymentReference != null ||
      odometerKm != null;
}

/// Reads the fiscal fields off the receipt [lines] (already trimmed by
/// the caller). [profile] supplies the active country's currency when
/// the paper prints an ambiguous symbol or none at all.
ReceiptFiscalFields extractReceiptFiscalFields(
  List<String> lines, {
  OcrLocaleProfile? profile,
}) {
  final text = lines.join('\n');
  final vat = _extractVat(lines);
  return ReceiptFiscalFields(
    vatAmount: vat.amount,
    vatRate: vat.rate,
    currency: extractReceiptCurrency(text, profile: profile),
    paymentReference: extractPaymentReference(lines),
    odometerKm: extractOdometerKm(text),
  );
}

/// The VAT amount and rate read off whichever line the lexicon
/// classifies as the VAT row. A rate with no amount (`MwSt 19,00 %
/// enthalten`) is a legitimate outcome and is NOT completed by
/// arithmetic — the printed paper is the only source here.
({double? amount, double? rate}) _extractVat(List<String> lines) {
  double? amount;
  double? rate;
  for (final line in lines) {
    if (line.isEmpty) continue;
    if (classifySpatialLabel(line) != ReceiptLabelKind.vat) continue;
    final lineRate = _percentIn(line);
    if (lineRate != null && rate == null) rate = lineRate;
    final lineAmount = _moneyIn(line, skip: lineRate);
    if (lineAmount != null && amount == null) amount = lineAmount;
    if (amount != null && rate != null) break;
  }
  return (amount: amount, rate: rate);
}

/// The first plausible percentage in [line] (`20,00 %` → `20.0`).
double? _percentIn(String line) {
  for (final m in _percentPattern.allMatches(line)) {
    final value = parseDecimal(m.group(1)!);
    if (value != null && value > 0 && value < 100) return value;
  }
  return null;
}

/// The first two-decimal money amount in [line], ignoring the token
/// that produced [skip] (the rate) so `MwSt 19,00 % 12,38 EUR` yields
/// `12.38` and not `19.00`.
double? _moneyIn(String line, {double? skip}) {
  final withoutPercent = line.replaceAll(_percentPattern, ' ');
  for (final m in _moneyPattern.allMatches(withoutPercent)) {
    final value = parseDecimal(m.group(1)!.replaceAll(' ', ''));
    if (value == null || value < 0 || value > _vatAmountMax) continue;
    if (skip != null && (value - skip).abs() < 0.0005) continue;
    return value;
  }
  return null;
}

/// The ISO 4217 code the amounts on [text] are denominated in, or null
/// when the paper says nothing and no [profile] is threaded.
///
/// Explicit codes win over symbols (a receipt printing `EUR` says so
/// unambiguously); an ambiguous `kr` resolves only from [profile],
/// because DKK, SEK and NOK all print it.
String? extractReceiptCurrency(String text, {OcrLocaleProfile? profile}) {
  final upper = text.toUpperCase();
  for (final code in _isoCodes) {
    if (RegExp('(?<![A-Z])$code(?![A-Z])').hasMatch(upper)) return code;
  }
  for (final entry in _symbolToIso.entries) {
    if (text.contains(entry.key)) return entry.value;
  }
  final fallback = profile?.currency.toUpperCase();
  if (fallback != null && fallback.length == 3) return fallback;
  return null;
}

/// A masked payment reference, or the printed document reference.
///
/// The masking is not cosmetic: a fuel receipt can print a full PAN,
/// and this is the boundary where it stops. Any run of 12-19 digits is
/// reduced to its last four before it is returned, so no caller — no
/// store, no export, no trace — ever sees the rest.
String? extractPaymentReference(List<String> lines) {
  for (final line in lines) {
    final masked = _maskedCardPattern.firstMatch(line);
    if (masked != null) return '****${masked.group(1)}';
    final pan = _panPattern.firstMatch(line);
    if (pan != null) {
      final digits = pan.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
      return '****${digits.substring(digits.length - 4)}';
    }
  }
  for (final line in lines) {
    final ref = _documentRefPattern.firstMatch(line);
    final value = ref?.group(1);
    if (value != null && _isReferenceLike(value)) return value;
  }
  return null;
}

/// A reference carries at least one digit and is not the receipt's own
/// date — `Recu 22/05/2026` names the day, not the transaction.
bool _isReferenceLike(String value) =>
    RegExp(r'[0-9]').hasMatch(value) &&
    !RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(value);

/// The odometer reading in kilometres, when the forecourt printed one
/// (fleet pumps routinely ask the driver to key it in).
double? extractOdometerKm(String text) {
  for (final pattern in _odometerPatterns) {
    for (final m in pattern.allMatches(text)) {
      final raw = m.group(1)!.replaceAll(RegExp(r'[\s.]'), '');
      final value = double.tryParse(raw);
      if (value != null && value > 0 && value <= _odometerMax) return value;
    }
  }
  return null;
}

/// A VAT amount above this is a misread, not a tax line.
const double _vatAmountMax = 10000;

/// Beyond this a "km" number is a phone number or a postcode.
const double _odometerMax = 3000000;

final RegExp _percentPattern =
    RegExp(r'(\d{1,2}(?:[.,]\d{1,2})?)\s*%');

final RegExp _moneyPattern =
    RegExp(r'(\d{1,3}(?: \d{3})*(?:[.,]\d{2})|\d+[.,]\d{2})');

/// Codes are matched before symbols; `EUR` on the paper is unambiguous.
const List<String> _isoCodes = [
  'EUR', 'GBP', 'USD', 'CHF', 'DKK', 'SEK', 'NOK', 'PLN', 'CZK', 'HUF',
];

/// Unambiguous symbols only. `kr` is deliberately absent — it is three
/// currencies, and guessing one is how a fleet total silently mixes them.
const Map<String, String> _symbolToIso = {
  '€': 'EUR',
  '£': 'GBP',
  r'$': 'USD',
  'zł': 'PLN',
  'Kč': 'CZK',
};

/// `**** 1234`, `XXXX1234`, `#### 1234` — the printed masked card.
final RegExp _maskedCardPattern =
    RegExp(r'(?:[*xX#]{2,}[\s-]*){1,4}(\d{4})(?!\d)');

/// A full or near-full card number as printed; reduced to its last four.
final RegExp _panPattern =
    RegExp(r'(?<!\d)((?:\d[ -]?){12,19})(?![\d-])');

/// `Beleg-Nr. 0042-115`, `Ticket: A12/9`, `Transaction 55231`. Only
/// genuine reference LABELS are listed — document-type words such as
/// `Recu` or `Ricevuta` are followed by a date, not a reference.
final RegExp _documentRefPattern = RegExp(
  r'\b(?:Beleg\s*-?\s*Nr|Bon\s*-?\s*Nr|Ticket|Transaktion|Transaction|'
  r'Ref|Reference|R[ée]f[ée]rence|Autorisation|Authorisation)\b'
  r'\.?\s*[:#n°]*\s*([A-Z0-9][A-Z0-9/-]{2,19})',
  caseSensitive: false,
);

final List<RegExp> _odometerPatterns = [
  RegExp(
    r'\b(?:Kilometerstand|Km\s*-?\s*Stand|Odometer|Compteur|Kilom[ée]trage|'
    r'Kilometraggio|Cuentakil[óo]metros|Mileage)\b\s*[:=]?\s*'
    r'([\d][\d\s.]{0,9}\d|\d)',
    caseSensitive: false,
  ),
  RegExp(r'(?<![\d,.])([\d][\d\s.]{0,9}\d|\d)\s*km\b', caseSensitive: false),
];
