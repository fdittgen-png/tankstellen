# Feature × Parameter Visibility Map (#1575)

Snapshot of every value in the `Feature` enum and the parameter
surfaces that exist for it today. The point of this map is to
keep the use-mode/profile work (#1517, #1570) honest: every
enabled feature should have *somewhere* the user can configure
or interact with it. A feature that turns on but offers no
companion UI is an **orphan** and should get a follow-up issue.

The audit was run on 2026-05-14 against
`lib/features/feature_management/domain/feature.dart`.

## Conventions

- **Settings entry-point** — where the user can flip the toggle.
  Every `Feature` is exposed as a `SwitchListTile` in
  `FeatureManagementSection` (Settings → *Feature management*).
  The column below names any *additional* surface (foldable
  card, sub-section, dedicated screen) beyond that universal
  toggle.
- **User-visible tab/screen** — where the user *encounters* the
  feature when it is enabled (search results, a bottom-nav
  tab, a sheet on station-detail, etc).
- **Parameter UI when ON** — what the user can configure once
  the feature is on, *besides* re-toggling it. "Toggle only"
  means the on/off bool is the full configuration surface.
- **Orphan?** — A feature is flagged as an orphan when:
  - It enables UX whose semantics plausibly invite per-user
    parameters (radius, threshold, default selection, schedule),
    AND
  - No such parameter UI exists in the current source tree.
  Features whose on/off bool *is* the natural parameter
  ("Show fuel stations") are **not** orphans.

## The map

| Feature | Settings entry-point | User-visible surface | Parameter UI when ON | Orphan? |
| --- | --- | --- | --- | --- |
| `obd2TripRecording` | Conso card → segmented control (Off / Fuel / Fuel+Trips) | *Conso* bottom-nav tab → Trajets sub-tab | OBD2 adapter pairing (Settings → OBD2); Trajets-tier dependents below | No |
| `gamification` | Conso card (Trajets tier) + dedicated gamification settings tile | Driving / gamification screens | `gamification_settings_tile.dart` (display preferences) | No |
| `hapticEcoCoach` | Conso card (Trajets tier) | In-trip haptic feedback | `driving_settings_section.dart` (sensitivity) | No |
| `tankSync` | Profile screen → TankSync section | Profile auth area | `tank_sync_section.dart` (auth, account, sync state) | No |
| `consumptionAnalytics` | Conso card (Trajets tier) | *Conso* tab → analytics view | View-only; aggregates persisted trip data | No |
| `baselineSync` | Sub-toggle inside TankSync (`requires: tankSync`) | Background — no user-facing view | Toggle only | No (binary by design) |
| `unifiedSearchResults` | Feature management toggle | Search results list | Toggle only — flips single-list vs split-list rendering | No (binary by design) |
| `priceAlerts` | Feature management toggle | *Alerts* tab / radius alert create sheet | Per-alert thresholds in `radius_alert_create_sheet.dart` | No |
| `priceHistory` | Feature management toggle | Station detail → 30-day chart | View-only; charts derived from price-history collection | No (binary by design) |
| `routePlanning` | Feature management toggle + Edit-profile → *Route planning* section | Search → "along the route" mode in `search_criteria_screen.dart` | Route-segment spacing + detour budget (`UserProfile.routeDetourBudgetKm`, #1602) + minimum-saving filter (`UserProfile.minRouteSavingPerLiter`, #1872) | No (richer parameter UI) |
| `evCharging` | Feature management toggle | Map / search EV results | Toggle only — paired with `showElectric` for filter UI | No |
| `glideCoach` | Conso card (Trajets tier) | In-trip glide guidance | `driving_settings_section.dart` (sensitivity / opt-in) | No |
| `gpsTripPath` | Conso card (Trajets tier) | Trip detail → map path | Toggle only — sample rate / accuracy hard-coded | No (binary by design) |
| `autoRecord` | Conso card (Trajets tier) | Trip-recording flow | `VehicleProfile.autoRecord` per-vehicle bool | No |
| `showFuel` | Feature management toggle | Map + search filters | `fuel_type_selector.dart` per-fuel preferences | No |
| `showElectric` | Feature management toggle | Map + search filters | Paired with `evCharging`; connector filters in EV search | No |
| `showConsumptionTab` | Derived from Conso mode (not a user toggle) | Bottom-nav *Conso* tab visibility | Implicit — flipped by `ConsoMode` segmented control | No (derived) |
| `manualConsumption` | Conso card (set by Fuel / Fuel+Trips) | *Conso* tab → Fuel + Charging logs | Vehicle list + fill-up sheet inside Conso settings | No |
| `loyaltyCards` | Settings → *Fuel club cards* section | Per-station discount application | `loyalty_settings_screen.dart` (card management) | No |
| `tflitePricePrediction` | Feature management toggle (compile-time gated) | Station detail → prediction chip | None yet — model artifact off-band (#1543) | **Tracked in #1543** |
| `fuelCalculator` | Feature management toggle | Search results header → calculator affordance → `/calculator` | View-only; `calculator_screen.dart` (inputs are in-screen, not settings) | No (#1613 — was orphan; entry point added) |
| `carbonDashboard` | Feature management toggle | Conso tab → AppBar eco action → `/carbon` | View-only; `carbon_dashboard_screen.dart` aggregates trip data | No (#1613 — brought under the Feature enum) |

## Cross-references

- Profile bundle → ConsoMode lock: `test/features/feature_management/app_profile_test.dart` (#1574).
- Conso surface invariants: same test file — `obd2TripRecording` implies `manualConsumption + showConsumptionTab`, Trajets-tier opt-ins require `obd2TripRecording`.
- Feature dependency graph: `lib/features/feature_management/domain/feature_manifest.dart` (manifest with `requires:` edges).

## Follow-ups

- **#1575-orphan-routePlanning** — resolved. #1602 added the *Route planning* section with a **detour-budget** slider (`UserProfile.routeDetourBudgetKm`) feeding `searchAlongRoute`'s corridor; #1872 added the **minimum-saving** slider (`UserProfile.minRouteSavingPerLiter`) — `0.0` = off, a positive value drops fuel stations not priced within that band of the route's cheapest.

- `tflitePricePrediction` is intentionally parameterless until a trained `.tflite` artifact ships (#1543). Not refiled here.

No other orphans found in this pass.
