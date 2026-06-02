<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Opening Hours

Tankstellen renders a Google-/Apple-Maps-grade weekly opening-hours block on
the station-detail screen (Epic #2707). This guide records how a country's
hours flow from its provider to the UI, and — importantly — the deferral
status of the countries that do **not** expose opening hours yet.

## Pipeline

```
provider payload
  → per-country OpeningHoursAdapter.parse(...)        (lib/features/station_services/<c>/<c>_opening_hours_adapter.dart)
  → StationDetail.openingHours : WeeklyOpeningHours   (the common model)
  → OpeningHoursView(hours: detail.openingHours ?? legacyOpeningHoursBridge(detail))
```

- The common model is `WeeklyOpeningHours`
  (`lib/features/station_detail/domain/opening_hours.dart`).
- Every adapter implements `OpeningHoursAdapter`
  (`lib/features/station_services/opening_hours/opening_hours_adapter.dart`):
  **pure, never throws, never returns `null`** — on missing/unparseable input
  it returns `WeeklyOpeningHours.notAvailable`.
- Countries with no adapter yet keep `StationDetail.openingHours == null`.
  The display layer resolves them through
  `legacyOpeningHoursBridge(detail)`
  (`lib/features/station_detail/domain/legacy_opening_hours_bridge.dart`),
  which maps the legacy `Station.is24h` / `StationDetail.openingTimes` fields
  to a schedule, or — when those are empty too — to
  `WeeklyOpeningHours.notAvailable`.
- `WeeklyOpeningHours.notAvailable` renders as a single muted "Opening hours
  not available" line (the `openingHoursNotAvailable` ARB key) and is elided
  entirely from the station-detail section (`station_info_section.dart`).
  Never a fabricated table or status hero.

## Country coverage

### Adapter shipped (structured hours)

| Country | Code | Source |
| --- | --- | --- |
| France | FR | Prix Carburants `opening_hours` |
| Austria | AT | E-Control |
| Germany | DE | Tankerkönig `openingTimes` |
| Spain | ES | MITECO `Horario` |
| Chile | CL | CNE `horario_atencion` |
| Portugal | PT | DGEG (#2714) |

### Deferred — no opening-hours data today (11 countries, #2716)

These providers do **not** expose opening hours in the feed we consume, so
their stations route through `legacyOpeningHoursBridge` → `notAvailable` and
gracefully show "Opening hours not available". This is verified end-to-end by
`test/features/station_detail/presentation/widgets/opening_hours_no_data_test.dart`.

| Country | Code | When to revisit |
| --- | --- | --- |
| United Kingdom | GB | **Needs a direct fuel-finder API recheck** — the public price-transparency feed did not confirm an `opening_hours` field. Re-evaluate against a brand/fuel-finder API. |
| Italy | IT | Revisit when the MISE feed exposes hours. |
| Denmark | DK | Revisit when the provider exposes hours. |
| Greece | GR | Revisit when the provider exposes hours. |
| Romania | RO | Revisit when the provider exposes hours. |
| Slovenia | SI | Revisit when the provider exposes hours. |
| Luxembourg | LU | Revisit when the provider exposes hours. |
| Australia | AU | Revisit when the provider exposes hours. |
| Mexico | MX | Revisit when the CRE feed exposes hours. |
| Argentina | AR | Revisit when the provider exposes hours. |
| South Korea | KR | Revisit when the Opinet feed exposes hours. |

**Revisit trigger:** add an `OpeningHoursAdapter` (and the matching adapter
test) for a country only once its provider actually exposes a usable
opening-hours field. Until then the bridge keeps the no-data state graceful —
there is nothing to fix, and nothing should fabricate hours.
