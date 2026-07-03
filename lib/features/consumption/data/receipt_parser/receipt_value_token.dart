// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../_pump_display_helpers.dart';
import '../ocr/recognized_text_block.dart';

/// Value-side tokenizing for the spatial receipt parser (#3458):
/// unit-suffix and currency-aware parsing of a numeric receipt block.
///
/// The field evidence showed two value-side defects in the old
/// tokenizer:
///
///  1. `€ 0,899/?` — the thermal printer's `/ℓ` unit suffix OCRs as
///     `/?`, `/l`, `/1`, `/L`, `/|`, `/i`, `/t`, or a bare `/`. The old
///     regex dropped the whole token; here the mangled suffix is the
///     STRONGEST signal the value is a per-litre price, regardless of
///     magnitude.
///  2. Currency was EUR-hardcoded unless a locale profile happened to be
///     threaded. Here the printed symbol/code (€, Kč, Ft, zł, CHF, £,
///     kr, $) is detected on the token itself and drives per-currency
///     plausibility ranges.
///
/// All symbols are DATA (what the paper prints), never user-facing ARB
/// strings.

/// Per-currency plausibility ranges for the three receipt fields, in the
/// currency's major unit. `kr` is shared by DKK/SEK/NOK (same band).
@immutable
class ReceiptCurrencyRange {
  /// ISO-ish code for diagnostics (i18n-ignore: data, not UI).
  final String code;
  final double priceMin;
  final double priceMax;
  final double totalMax;

  const ReceiptCurrencyRange({
    required this.code,
    required this.priceMin,
    required this.priceMax,
    required this.totalMax,
  });

  bool priceInRange(double v) => v >= priceMin && v <= priceMax;
  bool totalInRange(double v) => v > 0 && v <= totalMax;
}

/// Passenger-car fill volume band in litres — currency-independent.
const double kReceiptVolumeMin = 0.5;
const double kReceiptVolumeMax = 200.0;

bool receiptVolumeInRange(double v) =>
    v >= kReceiptVolumeMin && v <= kReceiptVolumeMax;

/// The EUR default — used when neither a locale profile nor a printed
/// symbol identifies the currency (historical behaviour).
const ReceiptCurrencyRange kEuroRange = ReceiptCurrencyRange(
  code: 'EUR',
  priceMin: 0.5,
  priceMax: 4.0,
  totalMax: 500.0,
);

/// Symbol/code → plausibility band. Order matters: multi-char codes are
/// matched before single-char symbols so `CZK` never half-matches.
const Map<String, ReceiptCurrencyRange> kReceiptCurrencyRanges = {
  'EUR': kEuroRange,
  'GBP': ReceiptCurrencyRange(
      code: 'GBP', priceMin: 0.8, priceMax: 3.0, totalMax: 400.0),
  'USD': ReceiptCurrencyRange(
      code: 'USD', priceMin: 0.5, priceMax: 4.0, totalMax: 500.0),
  'CHF': ReceiptCurrencyRange(
      code: 'CHF', priceMin: 1.0, priceMax: 4.0, totalMax: 500.0),
  'CZK': ReceiptCurrencyRange(
      code: 'CZK', priceMin: 15.0, priceMax: 70.0, totalMax: 12000.0),
  'HUF': ReceiptCurrencyRange(
      code: 'HUF', priceMin: 300.0, priceMax: 1500.0, totalMax: 150000.0),
  'PLN': ReceiptCurrencyRange(
      code: 'PLN', priceMin: 3.0, priceMax: 12.0, totalMax: 2000.0),
  // Scandinavian kroner — DKK/SEK/NOK share the printed `kr`.
  'KR': ReceiptCurrencyRange(
      code: 'KR', priceMin: 5.0, priceMax: 40.0, totalMax: 5000.0),
};

/// Printed marker → range-table key. Checked longest-first.
const List<(String, String)> _currencyMarkers = [
  ('EUR', 'EUR'), ('€', 'EUR'),
  ('CZK', 'CZK'), ('KČ', 'CZK'), ('KC', 'CZK'),
  ('HUF', 'HUF'), ('FT', 'HUF'),
  ('PLN', 'PLN'), ('ZŁ', 'PLN'), ('ZL', 'PLN'),
  ('CHF', 'CHF'),
  ('GBP', 'GBP'), ('£', 'GBP'),
  ('USD', 'USD'), ('\$', 'USD'),
  ('DKK', 'KR'), ('SEK', 'KR'), ('NOK', 'KR'), ('KR', 'KR'),
];

/// Looks up the plausibility band for a detected currency [code] (a
/// range-table key), falling back to EUR.
ReceiptCurrencyRange receiptCurrencyRangeFor(String? code) =>
    kReceiptCurrencyRanges[code ?? 'EUR'] ?? kEuroRange;

/// A numeric receipt block, tokenized with its unit/currency signals.
@immutable
class ReceiptValueToken {
  final RecognizedTextBlock block;
  final double value;
  final int decimals;

  /// Range-table key of the currency marker printed ON this token
  /// (`EUR`, `CZK`, `KR`, …); null when the number is bare.
  final String? currencyCode;

  /// `true` when the token carries a per-litre unit suffix (`/ℓ`
  /// including its OCR mangles) — the strongest per-litre price signal.
  final bool perLiter;

  const ReceiptValueToken({
    required this.block,
    required this.value,
    required this.decimals,
    this.currencyCode,
    this.perLiter = false,
  });
}

/// The `/ℓ` unit suffix and every observed OCR mangle of it: `/l`, `/L`,
/// `/1`, `/?`, `/|`, `/i`, `/t`, `/j`, or a bare trailing `/` — anchored
/// AFTER a digit so a date's `02/07` never fires. Currency markers are
/// stripped before this runs, so `34,90 Kč/l` exposes its suffix too.
final RegExp _perLiterSuffix =
    RegExp(r'\d\s*/\s*(?:[lL1ℓ?|itj](?![A-Za-z0-9])|$)');

/// The clean decimal the token must reduce to once markers are stripped:
/// optional space/NBSP thousands groups + a 1-3 digit decimal part.
final RegExp _decimalCore =
    RegExp('^(\\d{1,4}(?:[  ]\\d{3})*[.,]\\d{1,3})\$');

/// Trailing OCR noise a thermal print leaves on a value (`30.96 !`).
final RegExp _trailingNoise = RegExp(r'[!|;:*°"º\s]+$');

/// Tokenizes [block] as a numeric receipt value, or null when the block
/// is not a clean number-with-markers (labels, dates, IDs, prose and
/// percentage lines — `20,00 %` is a VAT rate, never a candidate — all
/// return null).
ReceiptValueToken? parseReceiptValueToken(RecognizedTextBlock block) {
  var text = normaliseDigits(block.text).trim();
  if (text.isEmpty) return null;

  // A percentage is a VAT rate — never a transaction value.
  if (RegExp(r'\d\s*%').hasMatch(text)) return null;

  // Currency marker FIRST — detect (longest-first), then strip, so a
  // `34,90 Kč/l` still exposes its digit-adjacent `/l` suffix below. The
  // marker must sit at a word edge so `Ft` never eats into prose; the
  // final clean-decimal check rejects anything still carrying letters.
  String? currencyCode;
  for (final (marker, code) in _currencyMarkers) {
    final pattern = RegExp(
      '(?<![A-Za-z0-9])${RegExp.escape(marker)}(?![A-Za-z0-9])',
      caseSensitive: false,
    );
    if (pattern.hasMatch(text)) {
      currencyCode = code;
      text = text.replaceAll(pattern, ' ');
      break;
    }
  }

  // Per-litre unit suffix (incl. mangles) — detect, then strip.
  final perLiter = _perLiterSuffix.hasMatch(text);
  if (perLiter) {
    text = text.replaceFirst(RegExp(r'/\s*[lL1ℓ?|itj]?\s*'), ' ');
  }

  // A trailing litre unit on a volume value ("41.39 L", "41.39 ℓ").
  text = text.replaceFirst(RegExp(r'(?<=\d)\s*[lLℓ]$'), '');

  // Trailing print/OCR noise, then leading residue (a stripped symbol
  // leaves spaces; anything else — letters, a second number — rejects).
  text = text.replaceAll(_trailingNoise, '').trim();
  text = text.replaceFirst(RegExp(r'^[\s.,]+'), '');

  final m = _decimalCore.firstMatch(text);
  if (m == null) return null;
  final raw = m.group(1)!.replaceAll(RegExp('[  ]'), '');
  final value = parseDecimalFromOcr(raw);
  if (value == null) return null;
  final decimals = raw.split(RegExp(r'[.,]')).last.length;
  return ReceiptValueToken(
    block: block,
    value: value,
    decimals: decimals,
    currencyCode: currencyCode,
    perLiter: perLiter,
  );
}
