// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Which currency a fill-up is recorded in, decided from the fill's own
/// evidence rather than from wherever the profile happens to point
/// (#4428).
///
/// ## The defect this replaces
///
/// `FillUpRepository.save` used to stamp the ACTIVE COUNTRY's currency
/// on every record that arrived without one. A driver with an EUR
/// profile who refuels in Switzerland and pays CHF 51,73 by card had
/// that stored as **EUR 51,73** — ~6-7 % understated, and invisible to
/// the currency segregation of #4364 because the row asserts it is EUR.
/// Every downstream figure (€/L, €/km, monthly spend, savings) then
/// inherits the error with full confidence.
///
/// A missing label costs the driver a withheld total, which #4364
/// already handles and #4406 explains. A WRONG label costs them a wrong
/// number they cannot see. So the rule here is: **record unknown rather
/// than a confident wrong label.**
///
/// ## The order of evidence
///
/// 1. **What the record already says wins, always.** A restored backup,
///    a synced row, or a receipt scan that read `CHF` off the paper has
///    already stated its currency; re-labelling it with today's is the
///    very bug this file exists to stop.
/// 2. **The station's country.** Every supported country emits
///    country-prefixed station ids (`uk-`, `ok-`, `de-`, …), so a fill
///    logged at a British station is GBP whatever the profile says.
/// 3. **Where the driver actually is.** When the device's detected
///    country is not the profile's and the two do not share a currency,
///    the profile's currency is not evidence of anything — the record
///    goes in as *unknown*. Note what this deliberately does NOT do: it
///    never claims the observed country's currency either. A driver
///    logging a forgotten home fill-up from a hotel abroad would get
///    that claim wrong, and a wrong claim is worse than a blank.
/// 4. **Otherwise the profile's currency**, which is the overwhelmingly
///    common, domestic case and stays exactly as it was.
///
/// Pure Dart: no Flutter, no providers, no clock, no network. Every
/// input is supplied by the caller so the rule can be replayed in a
/// unit test.
library;

import '../../../core/country/country_config.dart';

/// The ISO 4217 code to store on a fill-up, or `null` for *unknown*.
///
/// `null` is a first-class answer, not a failure: `FillUp.currency`
/// documents null as unknown and [MoneyTally] keeps it in its own
/// bucket rather than folding it into a named currency.
///
/// [recordedCurrency] is whatever the record already carries (receipt
/// scan, restore, sync). [stationId] is the fill's station, whose
/// prefix names the country it belongs to. [observedCountryCode] is
/// where the device believes it is *right now* — pass null wherever
/// that is not evidence about this record (an import, a merge, a
/// re-save of an old row). [profileCountryCode] / [profileCurrency]
/// describe the active profile.
String? resolveFillUpCurrency({
  required String? recordedCurrency,
  required String? stationId,
  required String? observedCountryCode,
  required String profileCountryCode,
  required String profileCurrency,
}) {
  final recorded = recordedCurrency?.trim();
  if (recorded != null && recorded.isNotEmpty) return recorded.toUpperCase();

  final stationCountry = Countries.countryCodeForStationId(stationId);
  if (stationCountry != null) {
    // A station id whose prefix names a country the registry no longer
    // configures leaves the record unknown rather than profile-stamped.
    return Countries.byCode(stationCountry)?.currency;
  }

  final observed = observedCountryCode?.trim().toUpperCase();
  if (observed == null || observed.isEmpty) return profileCurrency;
  if (observed == profileCountryCode.trim().toUpperCase()) {
    return profileCurrency;
  }
  // Abroad, but in a country whose currency matches the profile's
  // (FR → DE, both EUR): no contradiction, so the stamp still holds.
  if (Countries.byCode(observed)?.currency == profileCurrency) {
    return profileCurrency;
  }
  // Abroad in a currency this record gives us no way to name — the
  // Switzerland case, where the country is not even in the registry.
  return null;
}
