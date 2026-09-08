# Developer Guide

Technical documentation for contributing to or customising the app. All developer docs are in English — the user-facing wiki is translated per language.

> The repo, bundle id (`de.tankstellen.fuelprices`) and internal package name stay **`tankstellen`** — the project's technical identity. **Sparkilo** is the public brand on the stores and the home-screen tile. These docs use *tankstellen* when referring to code/repo and *Sparkilo* for the product.

> **Platform parity (since 2026-05-08):** features default to **both iOS and Android**. Single-platform features must follow the loosely-coupled plugin pattern documented in [ADR 0009](https://github.com/fdittgen-png/tankstellen/blob/master/docs/decisions/0009-cross-platform-default-and-plugin-pattern.md). iOS code-signing setup lives in [docs/guides/ios-codesigning.md](https://github.com/fdittgen-png/tankstellen/blob/master/docs/guides/ios-codesigning.md). Android releases ship via `daily-beta.yml`; iOS TestFlight via `ios-testflight.yml` — both must stay green on every PR.

## Why this app exists (one paragraph)

Tankstellen (publicly **Sparkilo**) targets the running cost of a car through three layers: cheaper fuel at the pump (Layer 1 — 17 country open-data APIs + Open Charge Map for EV, route search with "best stops", per-station + radius alerts, the fuel-cost calculator, 30-day predictions), less consumption per kilometre (Layer 2 — OBD-II + GPS-only trip recording, driving-style score, eco-coaching with throttle/RPM histograms and a wasteful-behaviour breakdown, the approach overlay), and full transparency over what was actually spent (Layer 3 — fill-up log with pump/receipt OCR, consumption stats, the Trips logbook, the Carbon dashboard for cost + CO₂). When in doubt, ask: *"Which layer does this feature serve?"* — if the answer is "none," it doesn't ship.

## Start here

- **New to the codebase?** → [Architecture Overview](Dev-Architecture-Overview) → [Project Structure](Dev-Project-Structure)
- **Want to add a feature?** → [Contributing](Dev-Contributing) → [GitHub Workflow](Dev-GitHub-Workflow)
- **Want to add a country?** → [Adding a Country](Dev-Adding-A-Country)
- **Want to understand the prediction math?** → [Fuzzy Logic Price Predictions](Dev-Fuzzy-Logic-Price-Predictions)
- **Want to wire an OBD2 adapter?** → [OBD2 Implementation](Dev-OBD2-Implementation)

## Index

### Architecture
- [Architecture Overview](Dev-Architecture-Overview) — App shell, feature-first layout, layered core
- [Project Structure](Dev-Project-Structure) — Folder-by-folder walkthrough
- [Flutter & Platform Independence](Dev-Flutter-Platform-Independence) — What Flutter buys us and the platform-specific bits

### Code patterns
- [Dart Best Practices](Dev-Dart-Best-Practices) — Freezed, null safety, async, extensions
- [State Management (Riverpod)](Dev-State-Management-Riverpod) — `@riverpod`, `keepAlive`, AsyncNotifier, watch vs read
- [Service Layer & Fallback](Dev-Service-Layer-Fallback) — `StationServiceChain`, `ServiceResult<T>`, request coalescing, rate limiting
- [Caching Strategy](Dev-Caching-Strategy) — `CacheManager`, TTLs, key design, eviction
- [Storage & Sync](Dev-Storage-Hive-Sync) — Hive boxes, profiles, TankSync over Supabase, background tasks

### Quality
- [Testing & TDD](Dev-Testing-TDD-Pyramid) — 70/20/10 pyramid, fakes over mocks, mandatory pre-fix test protocol
- [Error Reporting & Tracing](Dev-Error-Reporting-Tracing) — `TraceRecorder`, error classification, global handlers, consent-gated reports

### Deep dives
- [OBD2 Implementation](Dev-OBD2-Implementation) — transport abstraction, adapter registry, PID parsing, permissions, auto-record state machine
- [Fuzzy Logic Price Predictions](Dev-Fuzzy-Logic-Price-Predictions) — the "best time to fill" recommendation engine, learning phase, limitations
- [Localization (ARB)](Dev-Localization-ARB) — 23 locales, key-parity test, gen-l10n, **ARB fragment pattern** in `lib/l10n/_fragments/`

### Workflow
- [CI/CD Pipeline](Dev-CI-CD-Pipeline) — GitHub Actions, artefacts, release tagging, daily 18:00 Paris open-testing release
- [GitHub Workflow](Dev-GitHub-Workflow) — Git flow, conventional commits, squash-merge, PR rules
- [Creating Issues](Dev-Creating-Issues) — Templates, labels, milestones, triage
- [Contributing](Dev-Contributing) — Fork, branch, submit, customise for personal use
- [Adding a Country](Dev-Adding-A-Country) — Step-by-step playbook for a new country API

### Reference
- [Official Docs & SDKs](Dev-Official-Docs-SDKs) — every external API, package, and country data source with links

---

## Core facts for contributors

| | |
|---|---|
| **Language** | Dart 3.11 |
| **Framework** | Flutter 3.41 (stable channel) |
| **Lint** | `flutter_lints` + custom rules (see `analysis_options.yaml`); plain `flutter analyze` must pass with zero warnings (CI fails on info-level too) |
| **State** | Riverpod 3 with `@riverpod` / `@Riverpod(keepAlive: true)` code-gen |
| **Models** | Freezed + json_serializable |
| **Storage** | Hive (encrypted boxes, AES from FlutterSecureStorage) |
| **HTTP** | Dio with `RateLimitInterceptor` |
| **Background** | WorkManager |
| **Testing** | `flutter_test`, `mocktail`, coverage via `flutter test --coverage`; gate currently 40 % (was 45 %, see CHANGELOG 5.0.0) |
| **Policy** | Zero `flutter analyze` warnings before commit; tests required for every change; new i18n keys go in `lib/l10n/_fragments/<feature>_<locale>.arb` (NOT in the aggregated `app_*.arb` files); features must serve at least one of the three savings layers |
