// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../receipt_parser.dart';
import 'ereceipt_locale_profiles.dart';

/// Pure-Dart parser for **digital fuel receipt text** — the body of a
/// forwarded e-receipt e-mail, a copied SMS confirmation, or the text layer
/// extracted from a shared PDF (#2838, phase 1 of Epic #2687).
///
/// This is a thin, focused entry point over the shipped [ReceiptParser]: it
/// reuses every receipt primitive (brand detection, the per-brand layouts,
/// the currency-aware field extractors, and cross-field reconciliation) so an
/// e-receipt and a camera-OCR'd photo extract the SAME five fields — litres,
/// price-per-litre, fuel grade, total, and station/brand — with one parsing
/// implementation. The difference is purely the input shape:
///
///   * **No camera / no asset I/O.** The text arrives as a `String`, so this
///     parser is synchronous and runs in a plain unit test (and in the
///     share-intent handler) without a Flutter binding or an `AssetBundle`.
///     The country → currency profile is resolved from the pure-Dart
///     [EReceiptLocaleProfiles] table, not the bundled OCR-config JSON.
///   * **Cleaner text → light normalisation.** Digital receipt text comes
///     with CRLF / CR line endings, no-break spaces (` `, common in
///     EUR-formatted amounts), and zero-width characters from HTML e-mail
///     bodies. [_normalise] folds those to the `\n` + ASCII-space shape the
///     line-oriented [ReceiptParser] already expects, so its regexes match
///     without per-source special-casing.
///
/// The result is always non-null; callers check [ReceiptParseResult.hasData]
/// to know whether anything actionable was extracted, exactly as with the
/// camera path. Feeds the inbound share-intent prefill (#2735).
class EReceiptTextParser {
  final ReceiptParser _parser;

  /// [parser] defaults to a plain [ReceiptParser] (no override registry — an
  /// e-receipt has no `stationId` to key per-station overrides on). Inject a
  /// configured parser only in tests that want to assert delegation.
  const EReceiptTextParser({ReceiptParser parser = const ReceiptParser()})
      : _parser = parser;

  /// Parse the [text] of a shared / pasted e-receipt into the fuel field set.
  ///
  /// [countryCode] is an optional ISO 3166-1 alpha-2 code (`IT`, `DE`, `GB`,
  /// …). When supplied and mapped in [EReceiptLocaleProfiles], the
  /// currency-aware extractors read totals / prices in that market's currency
  /// and per-litre band; otherwise the parser defaults to EUR — unchanged
  /// from passing no profile. Returns an empty (`hasData == false`) result
  /// for blank input rather than throwing, so the share-intent handler can
  /// treat "nothing parseable" and "no text shared" identically.
  ReceiptParseResult parse(String text, {String? countryCode}) {
    final normalised = _normalise(text);
    if (normalised.isEmpty) return const ReceiptParseResult();
    return _parser.parse(
      normalised,
      profile: EReceiptLocaleProfiles.forCountry(countryCode),
    );
  }

  /// `true` when [text] looks like a fuel receipt worth routing to the
  /// prefill form — it parsed at least a volume or a total. A convenience
  /// over `parse(text).hasData` for the share-intent gate.
  bool looksLikeReceipt(String text, {String? countryCode}) =>
      parse(text, countryCode: countryCode).hasData;

  /// Folds digital-text quirks down to the `\n` + ASCII-space layout the
  /// line-oriented [ReceiptParser] expects:
  ///
  ///   * CRLF / lone-CR line endings → `\n` (Windows mail clients, PDF text
  ///     layers);
  ///   * no-break / narrow-no-break / thin spaces (` ` ` `
  ///     ` `) → a regular space — EUR amounts are routinely printed as
  ///     `1 234,56 €` with a NBSP that otherwise splits the number;
  ///   * zero-width / BOM characters (`​`-`‍`, `﻿`) stripped —
  ///     they leak in from HTML e-mail bodies and break `\b` word boundaries.
  ///
  /// Pure + side-effect-free so it can be unit-tested in isolation.
  static String _normalise(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[   ]'), ' ')
        .replaceAll(RegExp(r'[​-‍﻿]'), '')
        .trim();
  }
}
