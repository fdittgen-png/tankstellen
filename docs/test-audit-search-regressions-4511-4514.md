<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Search regression evidence, 31 October 2026

Audited against `966d774cefe2a24edbc85ecef74c63f54c500c76`, using
Flutter 3.44.9 / Dart 3.12.2. Synthetic automated fixtures and the live
geocoder observation below are separate evidence.

## Vehicle fuel, #4513

A manual new-vehicle form seeded `e10` before a fuel was selected.
`buildProfile` persisted it; `syncActiveProfile` made the vehicle the default
and copied its fuel into the country profile; `effectiveFuelTypeProvider`
then selected E10 over an explicit Diesel preference. The regression invokes
that whole form → saved profile → effective-fuel chain and failed with
E10 instead of Diesel before the fix.

New manual forms now leave the fuel unset. Existing vehicle choices and
declared catalog mappings are preserved. An unrecognized catalog fuel also
stays unset instead of inventing E10; its regression failed before the fix.
No previously saved vehicle or profile is migrated or guessed from location.

## Denied location, #4514

The normal search error panel already provides location and postcode guidance.
The results screen's refresh action instead replaced every acquisition error
with the generic search-failed snackbar. Tests tap that real action with the
real `LocationService` and a fake platform returning denied/deniedForever.
Both message assertions failed before the fix.

Permission failures now carry a specific flag through `LocationException`.
The existing localizer selects the existing translated permission/postcode
message; disabled services and unavailable fixes retain their distinct
location error. A failed acquisition preserves the last valid position.
No localization keys or consent rules change.

## Postcode and map, #4511 and #4512: not reproduced

The current exact Nominatim request (`country=es`, `postalcode=28013`,
`format=json`, `limit=1`) returned `40.4187507, -3.7070555`, identified by
the provider as Centro, Madrid. A deterministic provider test pins the country
and postcode request and that response fixture. A map test checks the actual
camera's first viewport contains both Madrid fixture stations despite a
distant persisted device position. Existing camera lifecycle tests remain.

These observations do **not** explain the reported Galaxy S20 / F-Droid 6.0.5
result near Valdemoro or the country-center viewport. Nominatim-first lookup
and result-centroid framing came from `50402c45a4` (20 April 2026), and the
current first-layout camera fit traces to `43306bd00c` (13 June 2026). Both
already existed at the F-Droid 6.0.5 pin `506fcf502` (10 August 2026; also
documented in ADR 0028). They cannot be presented as later fixes for this
report. No speculative geocoder or map timing change is included here.

Keep #4511/#4512 pending an exact APK identity and a reproduction that records
the active country, accepted geocoder/cache result and displayed station
coordinates. An on-device replay of that reported installation remains
unverified; a live query succeeding today is not that replay.
