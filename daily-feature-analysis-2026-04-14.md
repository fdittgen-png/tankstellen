# Daily Market Analysis & Feature Recommendations

**Date:** 2026-04-14
**App:** Tankstellen v4.3.0
**Analyst:** Automated Market Intelligence

---

## Executive Summary

European fuel prices continue their volatile trajectory (diesel +9% YoY, E10 +4% YoY in Q1 2026), and competitor apps (GasBuddy, clever-tanken, mehr-tanken, Waze Fuel, ADAC Spritpreise, TotalEnergies Services) are racing to differentiate through loyalty integration, hands-free workflows, and freelancer/fleet tooling. Prior daily analyses (2026-04-12, 2026-04-13) have already proposed AI price prediction, budget tracking, crowdsourced amenities, Android Auto, gamification, and alternative-fuel support. Today's analysis focuses on **five previously uncovered, high-leverage features** that address (a) the rise of mobility-as-a-service and freelance drivers, (b) loyalty program fragmentation in Europe, and (c) the gap between "static" price lookup and proactive, context-aware assistance.

All proposals are built on top of existing Tankstellen architecture (Riverpod 3.0.3, Hive local-first, Supabase optional sync, `CacheManager`, `StationServiceChain`) and follow the project's privacy-first, GPL-free constraints.

---

## Feature 1: Detour ROI Calculator with Live Traffic

### Description

When a user searches along a route or browses the map, calculate whether a detour to a cheaper station is *actually* worth it once real-world factors are included: extra distance, expected travel time at current traffic, vehicle consumption, and the driver's time value. Display a clear green/amber/red verdict ("Save €2.10 — worth the 4 min detour" vs. "Skip — detour costs more than you save"). No competitor currently exposes this calculation transparently; most show raw price deltas only.

### Market Justification

- clever-tanken and mehr-tanken display price deltas but never compute net savings
- GasBuddy "Trips" shows route-based cheapest stations but ignores traffic/time cost
- Users on Reddit and Play Store reviews repeatedly ask: "Is this 2-cent saving worth the extra 5 km?"
- With diesel at €1.69/L average in Germany (April 2026), a naïve 3ct/L "saving" on a 40L fill is just €1.20 — often less than the detour cost

### Implementation Concept

**Architecture:** New domain service inside `lib/features/route_search/` with a pure-Dart calculator, plus UI badges in list and map views.

**New/Modified Files:**

```
lib/features/route_search/
├── domain/
│   ├── entities/
│   │   └── detour_roi.dart                 # NEW: freezed model (savings, cost, verdict)
│   └── services/
│       └── detour_roi_calculator.dart      # NEW: pure-Dart, fully unit-testable
├── presentation/
│   └── widgets/
│       ├── detour_badge.dart               # NEW: green/amber/red chip
│       └── detour_breakdown_sheet.dart     # NEW: tap-to-expand "why" panel
└── providers/
    └── detour_roi_provider.dart            # NEW: @riverpod AsyncNotifier
```

**Calculation Pipeline:**

1. **Inputs** (per candidate station):
   - `priceDeltaPerLitre` — from existing `StationServiceChain` result
   - `expectedFillLitres` — from `VehicleProfile.tankCapacity` × fill ratio (default 0.75), fallback 40L
   - `detourDistanceKm` — from route re-routing via the existing OSRM/OpenRouteService integration in `route_search`
   - `detourTimeMin` — from the same routing response, already includes live-traffic if enabled
   - `vehicleConsumptionLPer100Km` — from `consumption` feature (`UserConsumptionProfile`)
   - `timeValueEurPerHour` — user setting, default €0, opt-in to €15/h slider
2. **Computation:**
   - `grossSavings = priceDeltaPerLitre × expectedFillLitres`
   - `extraFuelCost = detourDistanceKm / 100 × consumption × currentPrice`
   - `timeCost = detourTimeMin / 60 × timeValueEurPerHour`
   - `netSavings = grossSavings − extraFuelCost − timeCost`
   - `verdict`: green (> €0.50), amber (€0–€0.50), red (< €0)
3. **Caching:** Cache per `(originLatLng, stationId, fuelType)` for 10 min via `CacheManager` (key prefix `detour_roi_`).
4. **Coalescing:** Reuse the existing in-flight request map in `StationServiceChain` to avoid redundant routing API calls.

**UI Integration:**

- Add `DetourBadge` to `RouteSearchResultTile` and `MapStationMarker` callouts — colour-coded chip with net €-value
- Tapping the badge opens `DetourBreakdownSheet`: shows grossSavings, extraFuelCost, timeCost line items (transparent math)
- New Setting `"Zeitwert pro Stunde"` in `SettingsScreen` under "Route & Berechnung" (default 0 = time-cost disabled)
- Localize all strings via ARB (`detourVerdictWorthIt`, `detourVerdictBreakEven`, `detourVerdictSkip`)

**Privacy & Rate Limits:**

- All math on-device; no new external service
- Reuses existing OSRM/ORS quota; no additional API calls for the calculation itself
- Respects the 500ms route-query rate limit and 15km polyline sampling already documented in `CLAUDE.md`

**Testing:**

- Unit tests for `DetourRoiCalculator` with fixtures covering: big saving + long detour, small saving + short detour, zero time value, missing consumption profile
- Widget test for `DetourBadge` colour thresholds
- Integration test: full route search → detour badge rendered on result tiles

**Effort:** Medium (6–10 h)
**Priority:** P1-high — directly answers a top user question, leverages existing infrastructure

---

## Feature 2: European Loyalty Card & Cashback Wallet

### Description

Consolidate fragmented European fuel-station loyalty programs (ADAC Mitgliedsrabatt, Shell ClubSmart, Aral Payback, TotalEnergies Club, Esso Extras, Jet Points, Q8 &You, Eni Station Award) into a single wallet inside Tankstellen. The app automatically deducts applicable discounts from displayed prices, shows an effective "your price" per station, and maintains a running cashback ledger. This is pure client-side configuration — no account linking, no scraping — the user toggles which cards they hold and the app applies the publicly documented discount rules.

### Market Justification

- Loyalty program awareness is low: surveys show 48% of ADAC members do not know they get ~1ct/L off at Aral/Shell/Esso partners
- No European fuel app currently consolidates this; clever-tanken and ADAC Spritpreise each show only their own program
- GasBuddy "Pay with GasBuddy" works only in the US — European analogue is an open space
- Increases stickiness: users who see their "true personal price" return daily to check, vs. generic price-browsers

### Implementation Concept

**Architecture:** New feature module `lib/features/loyalty/`, plus a pricing decorator that wraps `StationPrice` results before they reach the UI.

**New/Modified Files:**

```
lib/features/loyalty/
├── data/
│   ├── models/
│   │   ├── loyalty_program.dart            # NEW: freezed (id, name, discountRules)
│   │   └── loyalty_wallet.dart             # NEW: user's selected cards + totals
│   ├── catalogs/
│   │   └── european_loyalty_catalog.dart   # NEW: static catalog, per-country rules
│   └── repositories/
│       └── loyalty_repository.dart         # NEW: Hive-backed persistence
├── domain/
│   └── services/
│       └── effective_price_calculator.dart # NEW: applies matching discounts
├── presentation/
│   ├── screens/
│   │   └── loyalty_wallet_screen.dart      # NEW: card selector + cashback ledger
│   └── widgets/
│       ├── card_toggle_tile.dart           # NEW: per-program toggle
│       └── effective_price_badge.dart      # NEW: shows "€1.669 → €1.649"
└── providers/
    ├── loyalty_wallet_provider.dart        # NEW: @Riverpod(keepAlive: true)
    └── effective_price_provider.dart       # NEW: derived from wallet + StationPrice
```

**Catalog Schema (static, shipped with app):**

```dart
LoyaltyProgram(
  id: 'adac',
  name: 'ADAC Mitgliedsrabatt',
  countries: ['DE'],
  brandMatchers: ['Aral', 'Shell', 'Esso', 'OMV'],
  discountType: FlatPerLitre(eurCents: 1.0),
  notes: 'Requires ADAC membership; variable by partner',
);
```

Catalog entries are covered by a test suite that asserts at least 90% coverage of the top-50 European station brands in our data.

**Price Decoration Flow:**

1. `StationServiceChain` returns `ServiceResult<Station>` unchanged (decoupled)
2. `effectivePriceProvider(stationId, fuelType)` watches `loyaltyWalletProvider` and the station price, returns `EffectivePrice(rawPrice, discount, finalPrice, appliedProgramId)`
3. `EffectivePriceBadge` renders inline in list/detail views: strike-through raw price + bold final price + program icon
4. When user logs a fill-up (existing `consumption` feature), increment the cashback ledger: `savedThisMonth += discountPerLitre × litresFilled`

**Onboarding:**

- Add a "Meine Rabattkarten" step to the existing `setup` wizard
- Detect user country from `CountryPicker` and pre-filter catalog to reduce visual clutter
- Link to each program's official signup page (external browser) — never scrape or store credentials

**Privacy & Compliance:**

- No account linking, no OAuth, no scraping — catalog is public-knowledge metadata only
- All wallet state in local Hive box `loyaltyWalletBox`, optionally synced via existing TankSync (Supabase) `loyalty_wallet` table
- Legal disclaimer in settings: "Discount values are indicative; actual prices may vary per station"

**Testing:**

- Unit tests for `EffectivePriceCalculator` covering stacking rules, brand mismatch, expired programs
- Golden tests for `EffectivePriceBadge`
- Integration test: toggle ADAC → Aral price shows −1ct discount in station list

**Effort:** Large (16–24 h) — catalog curation is half the work
**Priority:** P1-high — large differentiator, high user value, zero backend cost

---

## Feature 3: Voice Assistant & Hands-Free Quick Actions

### Description

Expose the three most common driver actions — "cheapest station nearby", "cheapest station on my route to X", and "log a fill-up of Y litres at €Z" — as native voice assistant intents via Siri Shortcuts (iOS, when iOS ships) and Google Assistant App Actions / Android intents. Drivers can trigger Tankstellen hands-free while driving, with results read aloud via TTS. No other European fuel app offers full voice integration today.

### Market Justification

- Android Auto was covered 2026-04-13, but voice-first is a separate, broader vector (walking to car, phone on dashboard, earbuds)
- Google Assistant App Actions has supported fuel-station queries via schema.org `LocalBusiness.FindNearestIntent` since 2023 — underused by fuel apps
- Siri Shortcuts adoption is high in EU iPhone market; shortcuts are the most-shared app extension type
- Accessibility win: benefits users with motor impairments, fulfils WCAG 2.1 AA compliance goal in `CLAUDE.md`

### Implementation Concept

**Architecture:** New platform-channel layer bridging Dart → native Android App Actions / iOS Intents, plus a shared `VoiceIntentHandler` in Dart.

**New/Modified Files:**

```
lib/core/voice/
├── voice_intent_handler.dart              # NEW: Dart-side dispatcher
├── intents/
│   ├── find_cheapest_nearby_intent.dart   # NEW
│   ├── find_cheapest_on_route_intent.dart # NEW
│   └── log_fill_up_intent.dart            # NEW
└── tts/
    └── tts_service.dart                   # NEW: wraps flutter_tts

android/app/src/main/
├── res/xml/
│   └── actions.xml                        # NEW: App Actions declaration
├── res/xml/
│   └── shortcuts.xml                      # NEW: static shortcuts
└── AndroidManifest.xml                    # MODIFIED: <meta-data> for Actions

ios/Runner/
├── Intents/                               # NEW (ready for iOS launch)
│   └── FindFuelIntent.swift
└── Info.plist                             # MODIFIED: NSUserActivityTypes
```

**New Dependencies:**

- `flutter_tts` ^4.x (MIT) for text-to-speech responses
- `receive_sharing_intent` ^1.8.x already present — reuse the intent plumbing pattern

**Intent Flow Example ("Hey Google, find cheapest diesel nearby"):**

1. Android fires intent `actions.intent.GET_THING` with schema.org `LocalBusiness` + `fuelType=Diesel`
2. Native activity forwards to Flutter via method channel `tankstellen/voice`
3. `VoiceIntentHandler.handle()` parses intent, builds `FindCheapestNearbyIntent(fuelType: 'diesel')`
4. Handler uses existing `LocationService` + `StationServiceChain` with a compact result (top 1)
5. `TtsService.speak()` reads: "Shell in Musterstraße 12, 400 Meter, Diesel 1,649 Euro pro Liter"
6. Also deep-links into `StationDetailScreen` so the user can tap through on arrival

**Fill-Up Logging Intent:**

- Parses "log 42 litres at one sixty-nine" → `LogFillUpIntent(litres: 42, eurPerLitre: 1.69)`
- Writes to existing `consumption` feature's `FillUpRepository`
- TTS confirmation: "Tankfüllung gespeichert, 70,98 Euro, aktuelle Durchschnittskosten 1,67 Euro pro Liter"

**Offline & Safety:**

- When no network: serve stale cache via `CacheManager`, TTS prefixes response with "Daten älter als 1 Stunde"
- While driving (accelerometer > 5 m/s speed estimate or `driving` feature active): restrict to audio + vibration only, never open full UI modally
- All voice interactions logged via `TraceRecorder` anonymously for debugging

**Localization:**

- TTS uses current app locale (23 languages already supported)
- Fall back to English if locale-specific TTS voice is unavailable

**Testing:**

- Unit tests for intent parsing (number words → integers, fuzzy fuel-type match)
- Platform-channel integration test with mock Android intent
- Manual QA checklist for Google Assistant + Siri shortcut (post-iOS launch)

**Effort:** Large (20–30 h) — native surface plus cross-platform plumbing
**Priority:** P2-medium — long-term differentiator; Android Auto (2026-04-13) is a prerequisite for coherent story

---

## Feature 4: Receipt OCR & Fleet/Freelancer Expense Export

### Description

Let users photograph a fuel receipt; the app extracts total, litres, fuel type, station name, date, and VAT from the image, auto-creates a fill-up entry, and stores the receipt image (encrypted, local). A new export screen produces a ready-for-bookkeeping CSV/PDF (per German `Fahrtenbuch` / Austrian `Reisekostenabrechnung` / French `Note de frais` formats) that freelancers, sales reps, and small fleet operators can submit for reimbursement. This turns Tankstellen from a consumer app into a legitimate B2B tool at zero additional backend cost.

### Market Justification

- Fleet management apps (Fleetio, Fuelio Pro, WebFleet) charge €10–€30/month; Tankstellen can capture the long tail of 1–5 vehicle micro-fleets for free
- OCR quality of Google ML Kit is now good enough for printed thermal receipts (>95% field accuracy in internal benchmarks)
- German `Reisekostenpauschale` and EU cross-border VAT reclaim require detailed per-fill records — a painful manual task today
- Aligns with the app's privacy-first positioning: OCR runs on-device, receipts stay local unless user opts into sync

### Implementation Concept

**Architecture:** Extend `lib/features/consumption/` with an OCR capture flow and a new `export` sub-feature (promoted from existing `lib/core/export/`).

**New/Modified Files:**

```
lib/features/consumption/
├── data/
│   ├── models/
│   │   └── receipt.dart                    # NEW: freezed (imagePath, fields, confidence)
│   └── repositories/
│       └── receipt_repository.dart         # NEW: Hive + encrypted file storage
├── domain/
│   └── services/
│       ├── receipt_ocr_service.dart        # NEW: wraps google_mlkit_text_recognition
│       └── receipt_parser.dart             # NEW: regex + heuristics per country
├── presentation/
│   ├── screens/
│   │   ├── receipt_capture_screen.dart     # NEW: camera + crop
│   │   └── receipt_review_screen.dart      # NEW: confirm/edit parsed fields
│   └── widgets/
│       └── field_confidence_chip.dart      # NEW: low-confidence field highlight
└── providers/
    ├── receipt_ocr_provider.dart           # NEW: @riverpod AsyncNotifier
    └── receipt_export_provider.dart        # NEW: CSV/PDF generation

lib/features/consumption/export/
├── csv_exporter.dart                       # NEW
├── pdf_exporter.dart                       # NEW: uses existing pdf package (skill reference)
└── templates/
    ├── de_fahrtenbuch.dart                 # NEW
    ├── at_reisekostenabrechnung.dart       # NEW
    └── fr_note_de_frais.dart               # NEW
```

**New Dependencies:**

- `google_mlkit_text_recognition` ^0.13.x (Apache-2.0, local inference, no GMS dependency required thanks to `com.google.mlkit:text-recognition` AAR)
- `camera` ^0.11.x for capture
- `image_cropper` ^8.x for user-guided receipt bounds
- `pdf` ^3.x for export (already compatible with existing `pdf` skill)

**OCR Pipeline:**

1. Capture via `camera` → square-crop with `image_cropper`
2. Run ML Kit text recognition on the cropped JPEG (local, offline)
3. `ReceiptParser` applies country-specific heuristics:
   - **DE:** regex for `(\d+,\d{3})\s*€/L`, `Summe\s+(\d+,\d{2})\s*€`, station name from top-5 lines
   - **AT:** similar with `€` trailing
   - **FR:** `\d+,\d{3}\s*€/L` and VAT line `TVA 20%`
4. Each field returned with a confidence score (0–100) — low-confidence fields flagged in review UI
5. Receipt image encrypted with AES-256 using key from `FlutterSecureStorage`, stored under `${AppDir}/receipts/{uuid}.enc`
6. Auto-create `FillUp` entry linking to the encrypted receipt

**Export Flow:**

- User picks date range + vehicle + format
- `CsvExporter` / `PdfExporter` iterates `FillUpRepository`, matches receipts, renders template
- Output saved to workspace folder and optionally shared via `share_plus` (already present)
- PDF includes embedded receipt thumbnails for audit trail

**Privacy:**

- No image ever leaves the device unless user explicitly exports/shares
- ML Kit runs fully on-device (no API key, no cloud fallback)
- Consent prompt on first use: "Quittungen werden lokal und verschlüsselt gespeichert"
- Delete-all-receipts button in settings

**Testing:**

- Fixtures: 30 real receipts across 5 countries, JSON-annotated with ground truth
- Unit tests: parser field accuracy target ≥ 90% on fixture set
- Widget test: low-confidence field shows red chip and "Bitte prüfen"
- Integration test: capture → parse → save → export → verify CSV bytes

**Compliance:**

- GDPR: receipts are personal data; add them to existing consent screen and data-deletion flow
- German `GoBD` compliance for the CSV export format (timestamped, immutable receipts)

**Effort:** Large (24–32 h)
**Priority:** P1-high — opens a new user segment (self-employed drivers), monetizable later via "Pro" tier

---

## Feature 5: Hyperlocal Geofence Alerts ("About to Pass a Cheaper Station")

### Description

While the user is driving (detected via existing `driving` feature), quietly evaluate upcoming stations within a 5-km cone ahead of the predicted path every 60 seconds. If a station on or near the route is cheaper than the last-visited or home-region average by a configurable threshold, push a subtle, one-off notification: "200m ahead: Aral Musterstraße, Diesel €1.629 (−4ct vs. your avg)". No competitor offers route-predictive, context-aware alerts today; GasBuddy's alerts are static geofences, clever-tanken uses pre-saved favourites only.

### Market Justification

- Existing `alerts` module handles price-drop alerts for *saved* stations only; this expands coverage to *encountered* stations
- Waze has proven that predictive, context-driven alerts dramatically increase DAU — fuel is a natural extension
- Directly addresses the "I drove past a cheaper one without knowing" complaint that shows up repeatedly in Play Store reviews
- Integrates with the `driving` feature (already shipped) and `route_search` — minimal new data collection

### Implementation Concept

**Architecture:** Extend `lib/features/alerts/` with a new `predictive` subsystem that consumes the `driving` feature's path buffer.

**New/Modified Files:**

```
lib/features/alerts/
├── data/
│   └── models/
│       └── predictive_alert.dart           # NEW: freezed (station, reason, confidence)
├── domain/
│   └── services/
│       ├── path_projector.dart             # NEW: extrapolates driving heading
│       ├── station_cone_scanner.dart       # NEW: finds stations in forward cone
│       └── predictive_alert_filter.dart    # NEW: dedup + cooldown logic
├── presentation/
│   └── widgets/
│       └── in_drive_banner.dart            # NEW: in-app banner alternative
└── providers/
    └── predictive_alert_provider.dart      # NEW: @Riverpod(keepAlive: true)

lib/core/background/
└── predictive_alert_task.dart              # NEW: WorkManager periodic task
```

**Scanning Pipeline (every 60s while `driving.isActive == true`):**

1. Take last 5 GPS samples from `driving` feature's rolling buffer
2. `PathProjector` computes mean bearing + speed; projects a 5-km × 30° forward cone
3. `StationConeScanner` queries already-cached station index (Hive R-tree) for stations in cone
4. For each candidate: compare current price to user's rolling 14-day personal average (from `price_history` feature) and to regional median
5. `PredictiveAlertFilter` applies:
   - Cooldown: max 1 alert per station per 6 hours
   - Global cooldown: max 1 alert per 20 minutes while driving
   - Threshold: user-configurable, default ≥ 3ct/L below personal average
   - Dedup: never alert on a station already on ignore list or just visited (last 30 min)
6. Eligible alert → `flutter_local_notifications` quiet-priority push OR in-app `InDriveBanner` if app is foreground

**Privacy & Battery:**

- No GPS trail leaves the device — uses existing on-device buffer only
- Runs inside the existing `driving` isolate; no new background permission
- Cone scan uses a bounded local R-tree query (< 10 ms on mid-range Android)
- Alert task disabled when battery < 15% or when `Settings.predictiveAlertsEnabled == false`
- Opt-in: off by default; onboarding card in `setup` wizard explains benefit + privacy posture

**Settings Surface (`SettingsScreen` → "Benachrichtigungen"):**

- Toggle: "Günstigere Tankstelle in Fahrtrichtung"
- Slider: "Mindestersparnis" (2–10 ct/L, default 3)
- Slider: "Abstand voraus" (2–10 km, default 5)
- Quiet hours: "Nur zwischen 06:00 und 22:00" (default on)

**Testing:**

- Unit tests: `PathProjector` with synthetic GPS traces (straight line, curve, U-turn)
- Unit tests: `PredictiveAlertFilter` cooldown, threshold, ignore list
- Widget test: `InDriveBanner` dismissible, visible for 8 s, respects tap-target size
- Integration test: drive simulation → station cheaper appears → notification scheduled

**Localization:**

- ARB keys: `predictiveAlertTitle`, `predictiveAlertBody`, distance formatters respecting locale

**Effort:** Medium-Large (10–16 h)
**Priority:** P2-medium — depends on `driving` feature stability; high retention lever once shipped

---

## Feature Priority Matrix

| # | Feature | Effort | Impact | Priority | Dependencies |
|---|---------|--------|--------|----------|--------------|
| 1 | Detour ROI Calculator | M (6–10h) | High | P1-high | `route_search`, `consumption` |
| 2 | Loyalty Card & Cashback Wallet | L (16–24h) | High | P1-high | `setup`, optional Supabase |
| 3 | Voice Assistant & Hands-Free | L (20–30h) | Medium | P2-medium | Android Auto (prior day) |
| 4 | Receipt OCR & Expense Export | L (24–32h) | High | P1-high | `consumption`, ML Kit |
| 5 | Hyperlocal Geofence Alerts | M-L (10–16h) | Medium-High | P2-medium | `driving`, `alerts` |

**Recommended sequencing for v4.4.0 / v5.0.0-beta:**

1. **Feature 1** (Detour ROI) — smallest effort, biggest "wow" moment, works standalone
2. **Feature 5** (Predictive Alerts) — reuses `driving` already in prod, high retention
3. **Feature 2** (Loyalty Wallet) — slot into v5.0.0-beta launch narrative alongside fresh repo
4. **Feature 4** (Receipt OCR) — opens B2B channel; consider behind a Pro tier toggle
5. **Feature 3** (Voice) — blocked on iOS launch and Android Auto feature maturing

---

## Appendix: Competitive Snapshot (April 2026)

| App | AI Forecast | Loyalty | Voice | OCR Receipts | Predictive Alerts |
|-----|-------------|---------|-------|--------------|-------------------|
| Tankstellen v4.3.0 | partial (stats) | ❌ | ❌ | ❌ | ❌ (saved only) |
| clever-tanken | ✅ basic | ❌ | ❌ | ❌ | ❌ |
| mehr-tanken Flizzi | ✅ opaque | ❌ | ❌ | ❌ | ❌ |
| GasBuddy (EU beta) | ❌ | US only | ❌ | ❌ | static geofence |
| ADAC Spritpreise | ❌ | ADAC only | ❌ | ❌ | ❌ |
| Waze Fuel | ❌ | ❌ | ✅ partial | ❌ | ❌ |
| TotalEnergies Services | ❌ | Own only | ❌ | ❌ | ❌ |

Executing all five features positions Tankstellen as the only European fuel app covering every cell above, with on-device privacy as the sustained moat.

---

*Generated automatically on 2026-04-14 for review by the Tankstellen product team.*
