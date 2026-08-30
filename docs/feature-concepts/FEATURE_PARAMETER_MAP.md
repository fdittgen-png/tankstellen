<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Feature × Parameter Visibility Map (#1575, refreshed #3884)

Snapshot of every value in the `Feature` enum and the parameter
surfaces that exist for it today. The point of this map is to
keep the use-mode/profile work (#1517, #1570) honest: every
enabled feature should have *somewhere* the user can configure
or interact with it. A feature that turns on but offers no
companion UI is an **orphan** and should get a follow-up issue.

The audit was first run on 2026-05-14 and refreshed on 2026-08-30
(#3884, Epic #3881 — Settings information architecture, ADR 0019)
against `lib/features/feature_management/domain/feature.dart`
(33 values).

## The Settings tree (#3884)

Settings is a **two-level** tree: a root of twelve topic tiles with a
search field, each opening one screen that hosts the section widgets
expanded. "Settings entry-point" below names the topic screen.

| Topic tile | Route | Hosts |
| --- | --- | --- |
| Profiles & region | `/settings/profiles` | profile list → edit sheet (identity, radius, route planning incl. criterion + top-N, avoid highways, ratings, start screen, radar, default vehicle + hybrid fuel, region, home) |
| Vehicles & OBD2 | `/settings/vehicles` | vehicles tile, per-vehicle OBD2 adapter tile *(This vehicle)* |
| Driving & consumption | `/settings/driving` | #3883 slot (live consumption readout), Fuel Station Radar tile *(This profile)* → `/settings/driving/radar` (radius, price mode, min poll, auto-pin *(All profiles)*), `DrivingSettingsSection` (vehicles link, coaching, rewards, troubleshooting) |
| Prices & alerts | `/settings/prices` | alerts list tile → `/alerts`, voice announcements (toggle + 3 sliders), switches for `priceHistory`, `tflitePricePrediction`, `communityPriceReports`, `paymentQrScan` |
| Units & display | `/settings/units` | Theme tile → `/theme-settings`, read-only distance unit (from the active profile's country), home-screen widget colour + variant *(This profile)* |
| Features & use mode | `/settings/features` | use-mode presets (Basic / Medium / Full / Custom) + every feature switch (`FeatureManagementSection`) |
| Data sources & location | `/settings/data-sources` | API keys, GPS position, auto-update, auto-switch profile |
| Sync & account *(only with `tankSync`)* | `/settings/sync` | `TankSyncSection` (status, account, view data, link device, delete server data, share, disconnect, delete account) + cross-link to Privacy & data |
| Privacy & data | `/settings/privacy` | the five consents (location, error reporting, cloud sync, VIN online decode, **sync trip recordings**), privacy controls, Privacy Dashboard tile (owns deletion), Storage & cache (no Delete-all) |
| Backup & restore | `/settings/backup` | export backup, restore backup (shared `BackupExportFlow` / `BackupRestoreFlow`) |
| Advanced & developer *(only with PAT / debug flag)* | `/settings/advanced` | bad-scan PAT section, Developer tools tile → `/developer-tools` |
| About | `/settings/about` | `AboutSection` |

Every `Feature` is also a `SwitchListTile` under **Features & use mode**
(the universal toggle); the column below names any *additional* surface.

## Conventions

- **Settings entry-point** — where the user can flip the toggle or
  reach the feature's parameters, beyond the universal switch.
- **User-visible tab/screen** — where the user *encounters* the
  feature when it is enabled.
- **Parameter UI when ON** — what the user can configure once the
  feature is on, *besides* re-toggling it. "Toggle only" means the
  on/off bool is the full configuration surface.
- **Scope** — where the parameters persist: *app* (global), *profile*
  (`UserProfile`), *vehicle* (`VehicleProfile`). Non-global scopes carry
  a `ScopeBadge` in the UI.
- **Orphan?** — flagged when the feature plausibly invites per-user
  parameters and no such UI exists.

## The map

| Feature | Settings entry-point | User-visible surface | Parameter UI when ON | Scope | Orphan? |
| --- | --- | --- | --- | --- | --- |
| `obd2TripRecording` | Features & use mode → Conso card (Off / Fuel / Fuel+Trips) | *Conso* tab → Trajets | OBD2 adapter pairing per vehicle (Vehicles & OBD2 → vehicle) | vehicle | No |
| `gamification` | Features & use mode (Trajets tier); Driving & consumption → Rewards | Driving / achievements screens | `gamification_settings_tile.dart` | app | No |
| `hapticEcoCoach` | Driving & consumption → Coaching | In-trip haptic feedback | Toggle (dependency-gated) | app | No |
| `tankSync` | Sync & account | Profile auth area | `tank_sync_section.dart` (auth, account, data, danger zone) | app | No |
| `consumptionAnalytics` | Features & use mode (Trajets tier) | *Conso* tab → analytics | View-only | — | No |
| `baselineSync` | Features & use mode (sub-toggle of tankSync) | Background | Toggle only | app | No (binary) |
| `priceAlerts` | Prices & alerts → alerts tile | *Alerts* screen | Per-alert thresholds in `radius_alert_create_sheet.dart` | app | No |
| `priceHistory` | Prices & alerts → Price features | Station detail → 30-day chart | Toggle only | app | No (binary) |
| `routePlanning` | Features & use mode; Profiles & region → edit sheet → Route planning | Search → "along the route" | segment spacing, detour budget (#1602), min saving (#1872), **criterion cheapest/nearest + candidates per sample point (#3884)** | profile | No |
| `evCharging` | Features & use mode | Map / search EV results | Toggle only (paired with `showElectric`) | app | No |
| `glideCoach` | Driving & consumption → Coaching (when flag on) | In-trip glide guidance | `glideCoachSettingsProvider` enable | app | No |
| `gpsTripPath` | Features & use mode (Trajets tier) | Trip detail → map path | Toggle only | app | No (binary) |
| `autoRecord` | Features & use mode (Trajets tier); per vehicle in Edit vehicle | Trip-recording flow | `VehicleProfile.autoRecord` | vehicle | No |
| `showFuel` | Features & use mode (**single home since #3884**; the profile sheet links there) | Map + search filters | `fuel_type_selector.dart` | app | No |
| `showElectric` | Features & use mode (single home since #3884) | Map + search filters | EV connector filters | app | No |
| `showConsumptionTab` | Derived from the Conso mode control | Bottom-nav *Conso* tab | Implicit | app | No (derived) |
| `manualConsumption` | Features & use mode → Conso card (Fuel / Fuel+Trips); label localised in #3884 | *Conso* tab → Fuel + Charging logs | Vehicle list + fill-up form | app | No |
| `loyaltyCards` | Driving & consumption → Rewards → Fuel club cards; label localised in #3884 | Per-station discount application | `loyalty_settings_screen.dart` | app | No |
| `tflitePricePrediction` | Prices & alerts → Price features | Station detail → best-time guidance | Toggle only (requires `priceHistory`) | app | No (#1543 heuristic) |
| `fuelCalculator` | Features & use mode (**kept on by every preset since #3884**) | Search header → `/calculator` | In-screen inputs | app | No |
| `carbonDashboard` | Features & use mode (kept on by Medium/Full since #3884) | Conso overflow → `/carbon` | View-only | app | No |
| `experimentalOemPids` | Features & use mode (Trajets tier) | Trip recording fuel sampler | Toggle only | app | No (binary) |
| `paymentQrScan` | Prices & alerts → Price features (kept on by every preset since #3884) | Station detail → Scan payment QR | Toggle only | app | No (binary) |
| `communityPriceReports` | Prices & alerts → Price features (kept on by every preset since #3884) | Station detail → Report price | Toggle only | app | No (binary) |
| `obd2Optional` | Features & use mode → Conso card row | Trip start (adapter picker vs GPS-only) | Toggle only | app | No (binary) |
| `addFillUpOcrReceipt` | Features & use mode (kept on by Medium/Full since #3884) | Add fill-up → receipt scan | Toggle only | app | No (binary) |
| `addFillUpShareIntentReceipt` | Features & use mode | OS share sheet → Add fill-up | Toggle only | app | No (binary) |
| `developerPatToken` | Features & use mode; Advanced & developer → PAT section | Bad-scan reporter | `feedback_token_section.dart` (token entry) | app | No |
| `debugMode` | Features & use mode; Advanced & developer → Developer tools | `/developer-tools` | Diagnostics screens | app | No |
| `approachOverlay` | Features & use mode; Driving & consumption → Fuel Station Radar | In-trip radar / PiP tile | radius, price mode, min poll (profile); auto-pin (app) — **proper home since #3884** | profile + app | No |
| `voiceAnnouncements` | Prices & alerts → Voice announcements (**moved from the driving section in #3884**) | Spoken cheap-fuel announcements while driving | enable, proximity radius, cooldown, price limit | app | No |
| `voiceFeedback` | Features & use mode (master TTS switch); Driving & consumption → voice coaching toggle | All spoken output | Voice coaching mute | app | No |
| `startupTrace` | Features & use mode; label localised in #3884 | Developer tools → startup waterfall | Toggle only | app | No (dev tool) |

## Profile parameters without a Feature flag

Persisted on `UserProfile` and edited from Profiles & region → edit
sheet unless noted: name, preferred fuel, default radius, landing screen,
country, language, home postal code, rating mode, default vehicle,
`hybridFuelChoice` (**UI added in #3884**, Vehicle card, hybrids only),
`widgetColorScheme` / `widgetVariant` (Units & display → widget section,
labelled *This profile* since #3884), `autoUpdatePosition` (Data sources
& location). App-wide, outside any flag: theme, auto-switch profile,
API keys, the five consents, privacy controls, radar auto-pin.

## Cross-references

- Settings IA decision: `docs/decisions/0019-settings-information-architecture.md`.
- Topic screens: `lib/features/profile/presentation/screens/settings/`;
  routes: `lib/app/routes/profile_routes.dart` + `RoutePaths.settings*`.
- Profile bundle → ConsoMode lock + #3884 default-on invariants:
  `test/features/feature_management/app_profile_test.dart`.
- Pinned canonical preset sets:
  `test/features/profile/presentation/widgets/feature_management_section_categories_test.dart`.
- Feature dependency graph: `lib/features/feature_management/domain/feature_manifest.dart`.

## Follow-ups

- **#3883** — the "Live consumption readout" tile (slot marked at the
  top of `driving_consumption_screen.dart`) and the consumption-unit row
  under Units & display.
- Wiki settings pages (7 languages) still describe the pre-#3884 tree.

No orphans found in this pass.
