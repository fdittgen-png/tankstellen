// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/duration_formatter.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3993 — travel durations read through ARB, so the minute and hour
/// abbreviations are the reader's, not English pasted into 23 locales.
void main() {
  late AppLocalizations en;
  late AppLocalizations de;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    de = await AppLocalizations.delegate.load(const Locale('de'));
  });

  test('under an hour renders minutes only', () {
    expect(formatTravelDuration(en, 45), '45 min');
  });

  test('at an hour it splits into hours and minutes', () {
    expect(formatTravelDuration(en, 60), '1 h 0 min');
    expect(formatTravelDuration(en, 80), '1 h 20 min');
  });

  test('the abbreviations come from the locale, not from Dart', () {
    // The whole point: `\'${'$'}{m.round()} min\'` said "min" to a German
    // reader too.
    expect(formatTravelDuration(de, 45), '45 Min.');
    expect(formatTravelDuration(de, 80), '1 Std. 20 Min.');
  });

  test('rounds to the nearest minute', () {
    expect(formatTravelDuration(en, 44.6), '45 min');
  });

  test('degenerate inputs render as zero, never as an empty field', () {
    expect(formatTravelDuration(en, 0), '0 min');
    expect(formatTravelDuration(en, -5), '0 min');
    expect(formatTravelDuration(en, double.nan), '0 min');
    expect(formatTravelDuration(en, double.infinity), '0 min');
  });
}
