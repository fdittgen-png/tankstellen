// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../core/country/country_config.dart';
import '../../../core/domain/money.dart';

/// European currencies a driver can plausibly pay a forecourt in without
/// the app supporting that country's price feed (#4428 scope note) —
/// CHF at a Swiss border station is the case that started this.
const List<String> _kEuropeanCurrencyCodes = [
  'BGN', 'CHF', 'CZK', 'DKK', 'EUR', 'GBP', 'HUF', 'ISK', 'NOK', 'PLN',
  'RON', 'RSD', 'SEK', 'TRY', 'UAH',
];

/// Every ISO code a user may pick when stating which currency a fill was
/// paid in (#4437 settle sheet, #4406 bulk backfill), sorted.
///
/// A picker offers these with NO preselection: the answer is an explicit
/// statement by the driver, never a default taken from the active
/// country or the profile.
List<String> selectableCurrencyCodes() {
  final codes = <String>{
    ..._kEuropeanCurrencyCodes,
    ...kCurrencyMinorUnits.keys,
    for (final c in Countries.all) c.currency,
  };
  return codes.toList()..sort();
}
