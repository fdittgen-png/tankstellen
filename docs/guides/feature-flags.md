# Feature flags — registry, gating, profile bundles

Single source of truth for every `Feature` enum value the app ships:
what it does, what it depends on, what user-facing code actually
respects it, and which preset profile turns it on.

Generated from `lib/features/feature_management/domain/feature.dart`
+ `feature_manifest.dart` + `app_profile.dart` plus a grep audit of
`lib/`. Keep in sync when adding or removing a flag.

## Profile bundles

The first-run wizard asks the user to pick one of three presets. The
selector is also visible in Settings → Consumption section, so the
user can switch later. Picking a preset is **exhaustive** — every
flag listed below is enabled, every other flag is disabled
(`applyProfile()` semantics in `app_profile_provider.dart`).

| Flag | Basic | Medium | Full |
| --- | :-: | :-: | :-: |
| `showFuel` | ✓ | ✓ | ✓ |
| `showElectric` | ✓ | ✓ | ✓ |
| `priceAlerts` | ✓ | ✓ | ✓ |
| `priceHistory` | ✓ | ✓ | ✓ |
| `routePlanning` | ✓ | ✓ | ✓ |
| `evCharging` | ✓ | ✓ | ✓ |
| `tankSync` | ✓ | ✓ | ✓ |
| `baselineSync` | ✓ | ✓ | ✓ |
| `manualConsumption` | — | ✓ | ✓ |
| `obd2TripRecording` | — | — | ✓ |
| `autoRecord` | — | — | ✓ |
| `consumptionAnalytics` | — | — | ✓ |
| `gamification` | — | — | ✓ |
| `showConsumptionTab` | — | — | ✓ |
| `loyaltyCards` | — | — | ✓ |
| `hapticEcoCoach` | — | — | ✓ |
| `glideCoach` | — | — | ✓ |
| `gpsTripPath` | — | — | ✓ |
| `unifiedSearchResults` | — | — | — |
| `tflitePricePrediction` | — | — | — |

`Custom` is a sentinel — appears in the Settings selector once the
user toggles any individual flag away from a preset.

## Requires graph (parent → child)

A flag with a `requires:` parent is *effectively* disabled when the
parent is off, even if its own bit is on (per
`isEffectivelyEnabled`). Lazy cascade — children don't lose their
stored preference, they just stop surfacing until the parent comes
back on.

```
priceHistory
└─ tflitePricePrediction         (default-off, model artifact off-band)

tankSync
└─ baselineSync                  (driving-baseline cross-device)

obd2TripRecording                (root of the OBD2 family)
├─ autoRecord                    (master gate for hands-free record)
├─ gamification                  (scores + badges)
├─ hapticEcoCoach                (real-time haptic feedback)
├─ consumptionAnalytics          (fill-up + trip analysis tab)
├─ glideCoach                    (future hypermiling guide)
├─ gpsTripPath                   (GPS path persistence per trip)
└─ showConsumptionTab            (bottom-nav Conso tab)
```

Eight flags have **no** parent: `obd2TripRecording`, `tankSync`,
`unifiedSearchResults`, `priceAlerts`, `priceHistory`,
`routePlanning`, `evCharging`, `showFuel`, `showElectric`,
`manualConsumption`, `loyaltyCards`.

## Per-flag registry

For each flag below: description, default state from the manifest,
parent (if any), the Settings tile that owns the toggle, and the
runtime code path that actually gates the user-facing behavior.

### `obd2TripRecording`
- **Description**: OBD2-driven trip capture — the foundation for the
  rest of the consumption / driving family.
- **Default**: off (requires user opt-in for OBD2 hardware).
- **Requires**: none.
- **Settings tile**: Consumption → "OBD2 trip recording".
- **Runtime gates**: `consumption_screen.dart` — the Trajets tab is
  hidden when this is effectively off (`#conso-coherence`).

### `gamification`
- **Description**: Driving scores + earned badges surfaces.
- **Default**: off.
- **Requires**: `obd2TripRecording`.
- **Settings tile**: Consumption → "Gamification".
- **Runtime gates**: `gamificationEnabledProvider` reads
  `isEffectivelyEnabled(Feature.gamification, …)`. Consumers
  (BadgeShelf, achievements screen) listen to that provider.

### `hapticEcoCoach`
- **Description**: Real-time haptic feedback during an active trip.
- **Default**: off.
- **Requires**: `obd2TripRecording`.
- **Settings tile**: Consumption → "Haptic eco-coach".
- **Runtime gates**: `hapticEcoCoachEnabledProvider` →
  `isEffectivelyEnabled(…)`. The haptic-pulse code in the trip
  recorder watches that provider.

### `tankSync`
- **Description**: Cross-device sync via Supabase (favorites, fill-ups,
  trips, baselines, etc.).
- **Default**: off.
- **Requires**: none.
- **Settings tile**: TankSync section in Settings (visible when this
  flag is effectively on).
- **Runtime gates**: `profile_screen.dart` — the TankSync settings
  section is hidden when off.

### `consumptionAnalytics`
- **Description**: Fill-up + trip analysis tab.
- **Default**: off.
- **Requires**: `obd2TripRecording`.
- **Settings tile**: Consumption → "Consumption analytics".
- **Runtime gates**: ⚠️ **GAP** — currently only the Settings toggle
  exists; the analytics card on the Conso screen renders regardless.
  Tracking: see "Known gating gaps" below.

### `baselineSync`
- **Description**: Sync driving baselines (η_v calibration) via
  TankSync.
- **Default**: off.
- **Requires**: `tankSync`.
- **Settings tile**: Consumption → "Baseline sync".
- **Runtime gates**: `baselineSyncEnabledProvider` →
  `isEffectivelyEnabled(…)`. The baseline-upload path in
  `vehicle_baseline_repository` checks the provider before pushing.

### `unifiedSearchResults`
- **Description**: Single result list combining fuel + EV stations
  (vs the default separated views).
- **Default**: off.
- **Requires**: none.
- **Settings tile**: Search → "Unified results".
- **Runtime gates**: `unifiedSearchResultsEnabledProvider` →
  `isEffectivelyEnabled(…)`. Search screen reads this to choose the
  list shape.

### `priceAlerts`
- **Description**: Threshold-based price-drop notifications (radius
  alerts, station alerts).
- **Default**: on.
- **Requires**: none.
- **Settings tile**: Consumption → "Price alerts".
- **Runtime gates**: ⚠️ **GAP** — toggle present but the alerts
  pipeline runs regardless. Background scanner + UI surfaces don't
  check this flag.

### `priceHistory`
- **Description**: 30-day price charts on station detail.
- **Default**: on.
- **Requires**: none.
- **Settings tile**: Consumption → "Price history".
- **Runtime gates**: ⚠️ **GAP** — the price-history chart renders
  regardless on station detail. The `priceHistoryRepository` still
  records snapshots whether this is on or off.

### `routePlanning`
- **Description**: Cheapest stop along the user's planned route.
- **Default**: on.
- **Requires**: none (cross-feature dependency via the search
  criteria UI surfaces is not modelled as a requires edge).
- **Settings tile**: Consumption → "Route planning".
- **Runtime gates**: `search_criteria_screen.dart` — the "Along
  route" search mode chip is hidden when this is off.

### `evCharging`
- **Description**: EV charging stations via OpenChargeMap (data
  pipeline, separate from `showElectric` which is the search/map
  visibility filter).
- **Default**: on.
- **Requires**: none.
- **Settings tile**: Consumption → "EV charging".
- **Runtime gates**: ⚠️ **GAP** — the OCM fetch path runs whether
  this is on or off. The `showElectric` flag is what actually hides
  EV results today; this one is decorative.

### `glideCoach`
- **Description**: Hypermiling guidance using OSM traffic signals
  (future, not yet implemented).
- **Default**: off.
- **Requires**: `obd2TripRecording`.
- **Settings tile**: Consumption → "Glide coach".
- **Runtime gates**: none yet — the feature implementation is
  pending; the flag is reserved.

### `gpsTripPath`
- **Description**: Persist GPS path samples alongside each trip.
- **Default**: off.
- **Requires**: `obd2TripRecording`.
- **Settings tile**: Consumption → "GPS trip path".
- **Runtime gates**: `trip_recording_provider.dart` — `flags.isEnabled(…)`
  check at line 870 controls whether GPS samples are appended to the
  in-flight trip buffer.

### `autoRecord`
- **Description**: Master gate for hands-free auto-record (overrides
  the per-vehicle `autoRecord` bool when off).
- **Default**: on.
- **Requires**: `obd2TripRecording`.
- **Settings tile**: Consumption → "Auto-record".
- **Runtime gates**: `auto_record_orchestrator.dart` —
  `isEffectivelyEnabled(…)` short-circuits coordinator startup when
  off.

### `showFuel`
- **Description**: Display fuel stations in search results + on the
  map.
- **Default**: on.
- **Requires**: none.
- **Settings tile**: Search → "Show fuel stations".
- **Runtime gates**: `showFuelEnabledProvider` →
  `isEffectivelyEnabled(…)`. Search + map widgets watch the provider.

### `showElectric`
- **Description**: Display EV charging stations in search + map.
- **Default**: on.
- **Requires**: none.
- **Settings tile**: Search → "Show charging stations".
- **Runtime gates**: `showElectricEnabledProvider` →
  `isEffectivelyEnabled(…)`. Same widget pattern as `showFuel`.

### `showConsumptionTab`
- **Description**: Consumption tab in the bottom navigation.
- **Default**: on (with `obd2TripRecording` parent).
- **Requires**: `obd2TripRecording`.
- **Settings tile**: Consumption → "Consumption tab".
- **Runtime gates**: `consumption_tab_visibility.dart` —
  `isConsumptionTabReachable(manifest, enabled)` ORs this with
  `manualConsumption` so Medium users still see the tab without OBD2.

### `manualConsumption`
- **Description**: Manual fuel fill-ups + EV charging logs (no OBD2
  required).
- **Default**: off.
- **Requires**: none.
- **Settings tile**: Consumption → "Manual consumption logging".
- **Runtime gates**: `consumption_tab_visibility.dart` — OR'd with
  OBD2 trip recording to keep the Conso tab reachable for Medium-
  use-mode users.

### `loyaltyCards`
- **Description**: Fuel-club / loyalty discount cards with per-litre
  savings.
- **Default**: off.
- **Requires**: none.
- **Settings tile**: Consumption → "Loyalty cards".
- **Runtime gates**: `driving_settings_section.dart` — the loyalty
  section in Settings → Consumption is hidden when off.

### `tflitePricePrediction`
- **Description**: On-device TFLite price-prediction model.
- **Default**: off.
- **Requires**: `priceHistory`.
- **Settings tile**: Consumption → "TFLite price prediction".
- **Runtime gates**: `price_prediction_provider.dart` — triple-gated
  via the manifest flag, the compile-time `kTflitePredictorEnabled`
  const, and the static confidence band on the inference output.

## Known gating gaps

Four flags have a Settings toggle + Profile-bundle membership but
their user-facing behavior runs **regardless** of the flag's state.
The Settings tile is currently decorative for these. Tracking
follow-ups separately because each one is its own integration
problem.

| Flag | What's missing |
| --- | --- |
| `consumptionAnalytics` | Toggle visible in Settings; the analytics card on the Conso screen renders for any user who reaches the screen. Should gate the stats card / monthly-insights card. |
| `priceAlerts` | The radius-alerts background scanner + the alerts tab in Favorites surface regardless. Should gate both. |
| `priceHistory` | The 30-day chart on station detail renders for everyone. `priceHistoryRepository` also records snapshots regardless. Should gate the chart widget + the snapshot writer. |
| `evCharging` | The OCM fetch pipeline runs whether this is on or off. `showElectric` happens to be the de-facto kill switch today; `evCharging` is currently decorative. |

`glideCoach` is also ungated, but unlike the four above it has **no
implementation yet** — the flag is reserved for the future
hypermiling feature. Listed for completeness only.

## Adding a new flag

Checklist when introducing a `Feature.x`:

1. Add the enum value to `feature.dart` with a one-line dartdoc.
2. Add the `FeatureManifestEntry` to `feature_manifest.dart`
   (`defaultEnabled`, `requires`, `displayName`, `description`).
3. Add a Settings tile case to
   `feature_management_section.dart` (`_featureLabel`,
   `_featureDescription`, `_blockedEnableMessage`).
4. Add ARB keys (`featureLabel_<name>`, `featureDescription_<name>`,
   `featureBlockedEnable_<name>` if it has a parent) to the
   `_base_{en,de}.arb` fragments.
5. **Gate it at the user-visible code path** — either an
   `isEffectivelyEnabled(Feature.<name>, …)` call or a dedicated
   `<name>EnabledProvider`. Without this, the toggle is decorative
   (see "Known gating gaps" above).
6. Update `appProfileBundles` if the flag should land on / off for
   any preset profile.
7. Bump the feature-toggle-count test in
   `profile_screen_feature_mgmt_test.dart`.
8. Add tests covering the new gate (enabled → behavior on, disabled
   → behavior off).
