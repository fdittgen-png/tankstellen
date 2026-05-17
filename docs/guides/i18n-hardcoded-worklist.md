# Hard-coded user-facing text — remediation worklist

Tracks the output of the hard-coded-text detector
(`test/lint/no_hardcoded_ui_strings_test.dart`, built in #1659) against
HARD RULE #1. The detector's `_baseline` may only ever decrease; this
file is the classified plan for driving it to **0** (epic #1657).

## Method

The original triage for #1659 estimated ~86 candidates from a *crude*
multi-sink grep that also caught the intentional `?? 'fallback'` pattern,
interpolation and OBD2 PID data-map keys. The precise detector — which
anchors the literal directly to its UI sink — surfaces **16 genuine
candidates**:

| Classification          | Count | Action                                    |
|-------------------------|-------|-------------------------------------------|
| Brand / acronym exempt  | 5     | `// i18n-ignore:` — **done in #1659**     |
| Translatable UI text    | 11    | ARB key — **done in #1660 / #1661 / #1662** |
| Exception messages      | 0     | not a UI sink — separate audit, #1663     |
| False positives         | 0     | detector is precise — none flagged        |

**Status:** clusters A–C below are all localized; the detector baseline
is **0** and now a hard gate (#1664). Only #1663 (data-layer exception
messages) remains under epic #1657.

## Resolved in #1659 — `// i18n-ignore:` exemptions (5)

| File | Literal | Reason |
|------|---------|--------|
| `profile/.../about_section.dart` | `GitHub` | brand / proper noun |
| `profile/.../about_section.dart` | `PayPal` | brand / proper noun |
| `profile/.../about_section.dart` | `Revolut` | brand / proper noun |
| `payment/.../scan_payment_dispatcher.dart` | `IBAN` | standardized banking acronym, language-neutral |
| `setup/.../profile_choice_step.dart` | `Sparkilo` | brand wordmark / proper noun |

## Translatable UI text — localized (baseline 0)

Four of the eleven reused an existing key (no new translation tail):
`Rating` → `sortRating`, `Back` → `tooltipBack`, `Email` →
`authEmailLabel`, `Password` → `authPasswordLabel`. The other seven got
new keys (`mapUnavailable`, `routeNameHintExample`, `priceStatsCurrent`,
`tankerkoenigApiKeyLabel`, `openChargeMapApiKeyLabel`,
`tapToUpdateGpsPosition`, `nameLabel`), translated into all 24 locales.

### Cluster A → #1660 (profile + setup + sync surfaces) — 7

| File:line | Literal | Target fragment |
|-----------|---------|-----------------|
| `profile/.../api_key_section.dart:166` | `Tankerkoenig API Key` | `_base` (profile keys) |
| `profile/.../api_key_section.dart:204` | `OpenChargeMap API Key` | `_base` (profile keys) |
| `profile/.../location_section_widget.dart:81` | `Tap to update GPS position` | `_base` (profile keys) |
| `profile/.../profile_list_section.dart:129` | `Name` | `_base` (profile keys) |
| `sync/.../sync_setup_screen.dart:145` | `Back` | `_base` (common) |
| `sync/.../wizard_auth_step.dart:79` | `Email` | `auth` |
| `sync/.../wizard_auth_step.dart:89` | `Password` | `auth` |

`Back` is a generic action label — check for an existing common key
before adding one.

### Cluster B → #1661 (search + map + station-detail surfaces) — 3

| File:line | Literal | Target fragment |
|-----------|---------|-----------------|
| `ev/.../ev_station_detail_screen.dart:222` | `Rating` | `_base` (station detail) |
| `map/.../inline_map.dart:69` | `Map unavailable` | `broken_map` |
| `map/.../route_map_view.dart:150` | `e.g. Paris → Lyon` | `eco_routing` |

The `Paris → Lyon` example hint is translatable prose; the city names
are illustrative and translators may localize the example.

### Cluster C → #1662 (remaining surfaces) — 1

| File:line | Literal | Target fragment |
|-----------|---------|-----------------|
| `price_history/.../price_stats_card.dart:118` | `Current` | `_base` (price history) |

## #1663 — data-layer exception messages

Out of scope for this detector by design — it scans **UI sinks** only
(`Text`, `hintText`, …), not `throw Exception('…')`. #1663 runs a
separate `throw`/`Exception(` audit over the data layer and localizes
the user-facing ones.

## #1664 — final ratchet (done)

Clusters A–C landed, so the detector baseline is **0**. With the test
running in CI as `test/lint/no_hardcoded_ui_strings_test.dart`, any new
hard-coded UI string now fails the build — the hard gate is in place.
