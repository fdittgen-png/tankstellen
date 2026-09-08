# Sparkilo — a cheaper kilometre

**A free, open-source companion app for cutting the running cost of your car** — 17 countries, 23 languages, privacy-first, GDPR-compliant, no ads, no trackers.

> *Pay less per litre. Burn fewer of them per kilometre. See exactly what you spent.*

A car loses you money in three places: at the pump, on the road, and in everything you forgot to track. Sparkilo attacks all three.

<sub>The repo, bundle id (`de.tankstellen.fuelprices`), and internal package name remain `tankstellen` — that's the project's technical identity. **Sparkilo** is the public-facing brand on the App Store, Play Store, and the app's home-screen tile.</sub>

<p>
  <a href="https://play.google.com/store/apps/details?id=de.tankstellen.fuelprices">
    <img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="64"/>
  </a>
  &nbsp;
  <a href="https://apps.apple.com/app/id6766543414">
    <img alt="Download on the App Store" src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" height="64"/>
  </a>
  &nbsp;
  <a href="https://fdittgen-png.github.io/tankstellen/fdroid/repo">
    <img alt="Get it on F-Droid" src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png" height="64"/>
  </a>
</p>

> **Google Play** is the public **production** release. Already a beta tester? Open Testing keeps serving beta builds (shown with a *(beta)* tag) — leave the programme and reinstall to switch to production, or stay in beta to get new features first. **F-Droid:** add `https://fdittgen-png.github.io/tankstellen/fdroid/repo` for the Google-free build. **iPhone:** in TestFlight beta until Apple's first-build review clears. See [Getting Started](User-en-Getting-Started) for the full install guide.

---

## The objective: a cheaper kilometre

Every feature in the app ladders up to the same goal — **reduce what your car costs you, per kilometre driven** — through three layers, in priority order:

| Layer | What it does | Pays out |
|---|---|---|
| **1. Buy cheaper** | Live cross-country price + EV-charging comparison; one central **Search** button (raised in the bottom-bar notch) owns search across every tab; route-aware "best stops" planning with partial-results streaming; per-station **and** radius drop alerts with stats; a fuel-cost calculator; 30-day price history with a "best time to fill" model. | Every fill-up |
| **2. Burn less** | OBD-II + GPS-only trip recording (adapter optional), per-trip driving score, eco-coaching (wasteful-behaviour breakdown, throttle/RPM histograms), GPS diagnostics. The PiP overlay's **approach mode** flips to a huge-price layout when you cross a station's radius — testable in-app from Settings → Developer tools. | Every kilometre |
| **3. See what you spent** | Fill-up log (manual / pump-OCR / receipt-OCR), consumption + cost stats, the Trips logbook, the **Carbon dashboard** (cost + CO₂ by trip length and speed band). | Every month |

Cheap fuel is the easiest win. Lean driving pays out forever. Transparency is what stops you fooling yourself.

---

## 📘 User Guide

Pick your language:

| Language | Covers countries |
|---|---|
| 🇬🇧 [English](User-en-Home) | UK, Australia (default) |
| 🇩🇪 [Deutsch](User-de-Home) | Germany, Austria |
| 🇫🇷 [Français](User-fr-Home) | France |
| 🇮🇹 [Italiano](User-it-Home) | Italy |
| 🇪🇸 [Español](User-es-Home) | Spain, Argentina, Mexico |
| 🇵🇹 [Português](User-pt-Home) | Portugal |
| 🇩🇰 [Dansk](User-da-Home) | Denmark |

Every language version carries the same **14 pages**, in the same order, illustrated with the same screenshots:

**Start here**

1. **Home** — what the app does and the three savings layers
2. **Getting Started** — install, first-launch consent, country and language, use mode, first search
3. **How Sparkilo Works** — the concepts: profiles, use-mode presets, one data source per country, where your data lives, and how a litre becomes a number

**Finding cheap fuel**

4. **Finding Stations** — the criteria sheet, reading a station card, freshness, station detail, the map, the Fuel Station Radar
5. **Route Planning** — cheapest stops along a corridor, cross-border sources, the four strategies
6. **Favourites & Alerts** — saved stations, station and zone alerts, how the background check really behaves
7. **EV Charging** — OpenChargeMap, connectors, power filters
8. **Price History & Predictions** — the local 30-day history and what the algorithm deliberately does *not* do

**Burning less, and knowing what it cost**

9. **Vehicles & OBD2** — tank capacity, flex-fuel, adapter pairing, baseline calibration, auto-record
10. **Fuel Log & Consumption** — fill-ups, tank level, the tank report, accuracy levels, cost per km by fuel
11. **Trips & Eco-Coaching** — GPS or OBD2 recording, the trip detail, driving score, carbon dashboard

**Reference**

12. **Settings Reference** — every screen of the two-level settings tree, with each switch's operational impact
13. **Privacy, Data & Sync** — consents, the Privacy & data topics, TankSync, backup, GDPR rights
14. **Troubleshooting & FAQ** — nothing found, adapter won't connect, stale widget, wrong consumption figure

> The guide explains **the mechanism, not just the click path** — why the pump is the only trustworthy consumption figure, what a use-mode preset actually flips, and what each setting costs in battery, data or privacy.

---

## 🛠️ Developer Guide *(English only)*

- **Architecture** — [Overview](Dev-Architecture-Overview) · [Project Structure](Dev-Project-Structure) · [Flutter & Platform Independence](Dev-Flutter-Platform-Independence)
- **Code patterns** — [Dart Best Practices](Dev-Dart-Best-Practices) · [State Management (Riverpod)](Dev-State-Management-Riverpod) · [Service Layer & Fallback](Dev-Service-Layer-Fallback) · [Caching Strategy](Dev-Caching-Strategy) · [Storage & Sync](Dev-Storage-Hive-Sync)
- **Quality** — [Testing & TDD](Dev-Testing-TDD-Pyramid) · [Error Reporting & Tracing](Dev-Error-Reporting-Tracing)
- **Deep dives** — [OBD2 Implementation](Dev-OBD2-Implementation) · [Fuzzy Logic Price Predictions](Dev-Fuzzy-Logic-Price-Predictions) · [Localization (ARB)](Dev-Localization-ARB)
- **Workflow** — [CI/CD Pipeline](Dev-CI-CD-Pipeline) · [GitHub Workflow](Dev-GitHub-Workflow) · [Creating Issues](Dev-Creating-Issues) · [Contributing](Dev-Contributing) · [Adding a Country](Dev-Adding-A-Country)
- **Reference** — [Official Docs & SDKs](Dev-Official-Docs-SDKs) — every external API, SDK, and country data source we use

---

## Quick facts

- **Framework:** Flutter 3.41 / Dart 3.11
- **State:** Riverpod 3 (code-gen)
- **Storage:** Hive (encrypted, local-first) + optional Supabase (TankSync cloud)
- **Maps:** flutter_map + OpenStreetMap
- **OBD-II:** any ELM327-compatible adapter (BLE classic + dual-mode) — optional; GPS-only trajets work without an adapter
- **Countries:** DE, FR, AT, ES, IT, DK, PT, LU, SI, UK, AR, AU, MX, KR, CL, GR, RO
- **Languages:** 23 (BG, CS, DA, DE, EL, EN, ES, ET, FI, FR, HR, HU, IT, LT, LV, NB, NL, PL, PT, RO, SK, SL, SV)
- **Privacy:** No Firebase, no Google Play Services, no Apple analytics SDKs, no tracking, no ads
- **Platforms:** iOS (TestFlight today, App Store soon) and Android (Google Play). iOS and Android share the same Dart codebase; platform-specific surfaces (BLE OBD2, background tasks, widgets) live behind plugin interfaces.
- **License:** MIT

## Links

- **Source:** [github.com/fdittgen-png/tankstellen](https://github.com/fdittgen-png/tankstellen)
- **Issues:** [GitHub Issues](https://github.com/fdittgen-png/tankstellen/issues)
- **Releases:** [GitHub Releases](https://github.com/fdittgen-png/tankstellen/releases)
