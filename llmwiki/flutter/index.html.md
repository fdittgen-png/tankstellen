**LLM Wiki**

# Building Flutter applications

> A reference for building, testing, hardening and shipping cross-platform Flutter apps — derived from two production applications that ship to Google Play, the Apple App Store, F-Droid, macOS, Windows and the web. Every rule here traces to a specific failure that cost a CI round-trip, a store rejection, or a user-visible outage.

**Updated** 2026-08-01 **Pages** 29 **Flutter** 3.41 / Dart 3.11 **Machine index** [llms.txt](llms.txt)

<!-- chunk: index.what-this-is | tags: overview,scope -->

## What this is, and what it is not

This wiki is **derived documentation**. It consolidates the working practice of two real Flutter codebases into one reference. It is not a Flutter tutorial, not an API reference, and not a survey of alternatives — it is one coherent, opinionated way to build a Flutter application that survives contact with app stores, real devices and real users.

The two source projects:

| Project | Domain | What it proves out |
| --- | --- | --- |
| `sparkilo` | Fuel & EV price comparison across 17 countries, 23 languages, with OBD-II trip recording | Service-chain fallbacks over 17 unreliable third-party APIs · BLE + classic Bluetooth · a sharded CI with codified required checks · a genuinely libre F-Droid build accepted against a dex-level audit · 26 repo-specific lint tests · ~15 000 tests |
| `deskilo` | Coworking desk booking plus a community money ledger | Supabase with 73 immutable migrations and a default-deny RLS matrix · OAuth without a vendor SDK · NFC/RFID kiosk · barcode/QR · notarised macOS DMG · WiX MSI on Windows · a web target · an owner-validated product specification |

Where they disagree, the disagreement is recorded rather than smoothed over — see [Two projects compared](24-two-projects-compared.html), which audits what each does better and what each is missing.

<!-- chunk: index.reading-paths | tags: navigation,onboarding -->

## Reading paths

Four entry points, depending on why you are here.

| If you are… | Read, in order |
| --- | --- |
| **Starting a new app** | 01 Foundations → 02 Specification → 03 TDD → 18 GitHub → 13/14 Android & iOS |
| **Hardening an app that already exists** | 04 Robustness → 05 Traceability → 03 TDD → 27 Recurring bugs → 09 Confidentiality → 06 Caching |
| **Making it fast and world-ready** | 25 Performance → 26 Localisation, time & accessibility → 03 TDD |
| **Trying to ship it** | 19 Go-live → 13–17 the platform pages for your targets → 20 Testers |
| **Building a recording, map or always-on feature** | 21 Background & always-visible UI → 22 Maps → 10 Bluetooth → 06 Caching |
| **Setting up how a team works** | 23 GitHub craft → 18 GitHub CI → 02 Specification → 03 TDD |
| **An AI agent working in one of these codebases** | 00 How to use this wiki → then fetch only the pages named by [llms.txt](llms.txt) for your task |

<!-- chunk: index.contents | tags: navigation,toc -->

## All pages

#### Start here

- [**00 · How to use this wiki**Document model, callout taxonomy, provenance pills, and how to chunk these pages for retrieval.](00-how-to-use-this-wiki.html)
- [**01 · Foundations & architecture**Stack, feature-first layering, lint-enforced boundaries, Riverpod codegen, the service-chain pattern.](01-foundations-architecture.html)

#### Method

- [**02 · Specification-driven development**An implementation-free spec, resolving contradictions before code, and the amendment discipline.](02-specification-driven-development.html)
- [**03 · TDD & the test pyramid**70/20/10, the eight-step bug-fix protocol, twin-bug audits, false-green failure modes.](03-tdd-and-testing.html)
- [**04 · Robustness & error handling**Never-silent catches, guarded mutations, honest degradation, episode gating.](04-robustness.html)
- [**05 · Traceability & observability**Issue-first work, the trace ring buffer, crash forensics, build-to-commit mapping.](05-traceability.html)
- [**27 · Recurring bugs & regressions**The seven-step protocol, the nine-fix cautionary tale, detector blind spots, cycle-time fingerprinting, no-trace forensics.](27-recurring-bugs.html)

#### Data & backend

- [**06 · Caching**Fresh/stale/miss tiers, TTL constants, key design, schema-versioned invalidation.](06-caching.html)
- [**07 · Supabase backend**Immutable migrations, default-deny RLS, SECURITY DEFINER RPCs, client/server parity.](07-supabase.html)
- [**08 · Authentication & Google sign-in**OAuth without a vendor SDK, anonymous upgrade, deep-link redirects, linked identities.](08-authentication.html)
- [**09 · Confidentiality & security**What never leaves the device, secret hygiene, store privacy declarations.](09-confidentiality.html)

#### Device capabilities

- [**10 · Bluetooth & BLE**Permission matrices, the RFCOMM reconnect hang, dual reconnect authorities, background limits.](10-bluetooth.html)
- [**11 · Barcode & QR**The libre scanner swap, generating codes, the injectable scanner seam, 7-segment OCR.](11-barcode-qr.html)
- [**12 · NFC & RFID**Three-state availability, kiosk session lifecycle, UID normalisation as a contract.](12-nfc-rfid.html)

#### Platform targets

- [**13 · Android**Flavors, signing that never falls back to debug, R8, foreground services, per-ABI codes.](13-android.html)
- [**14 · iOS / iPhone**match, the keychain hang, API-key limits, extensions, the review-rejection playbook.](14-ios.html)
- [**15 · macOS**Sandbox and keychain, Developer ID vs App Store, notarisation, honest degradation.](15-macos.html)
- [**16 · Windows**WiX MSI authoring, the absolute-path harvest trap, the permanent upgrade code.](16-windows.html)
- [**17 · F-Droid**Two channels, making a build libre, the three-layer audit, the reproducible recipe.](17-fdroid.html)

#### Shipping

- [**18 · GitHub: repo, CI & process**Workflow topology, sharding, green-tree skips, required checks as data, the matrix-skip trap.](18-github.html)
- [**19 · Go-live runbook**The ordered checklist across five channels, what only a human can do, staged rollout.](19-go-live.html)
- [**20 · Testers & Google Groups**Play testers via a Google Group, TestFlight internal vs external, invitation mechanics.](20-testers-google-groups.html)

#### Runtime surfaces

- [**21 · Background & always-visible UI**Recording without the app in front, foreground services, Doze and OEM killers, screen pinning, PiP tiles, Live Activities, widgets.](21-background-and-pinning.html)
- [**22 · Maps with OpenStreetMap**Tile policy and a caching proxy, the four grey-tile causes, markers, your own data layers, and contributing back to OSM.](22-maps-openstreetmap.html)

#### Quality

- [**25 · Performance**Frame budgets, rebuild discipline, painter repaint contracts, Impeller, isolates, image memory, startup as a CI budget, app size.](25-performance.html)
- [**26 · Localisation, time & accessibility**The ARB pipeline and its gates, two locale strategies, expansion survival, the two-clock doctrine, the injectable clock, accessibility as tests.](26-l10n-time-a11y.html)

#### Collaboration

- [**23 · GitHub craft**Issues, labels, Projects, commits, pull requests, review, merge strategy, running CI, the README, the wiki and release notes.](23-github-craft.html)
- [**28 · Working with AI agents**Division of labor, worktree fan-out, file affinity, the verify loop, generated-file merge rules, serial merge trains, verification traps.](28-ai-agents.html)

#### Appendix

- [**24 · Two projects compared**A candid audit: what each source project does better, what each is missing, which to adopt.](24-two-projects-compared.html)

<!-- chunk: index.the-short-version | tags: summary,principles -->

## The short version

If you read nothing else, these are the ten practices that produced the largest difference between the two projects' good months and their bad ones.

1. **Write the specification before the code, and keep it honest.** An implementation-free spec that names its own resolved contradictions is worth more than a backlog of tickets. [→ 02](02-specification-driven-development.html)
1. **Every change traces to an issue; every shipped build traces to a commit.** A version number that cannot be mapped back to a commit makes every user report unanswerable. [→ 05](05-traceability.html)
1. **Bug fixes start with a test that fails for the same reason the app fails.** Then grep for the same pattern elsewhere before closing. [→ 03](03-tdd-and-testing.html)
1. **Never swallow an error, and never degrade silently.** A fallback that renders indistinguishably from real data hides outages for months. [→ 04](04-robustness.html)
1. **Generated code is committed, so regenerate from clean before every push.** Incremental codegen keeps stale hashes that only a clean CI run catches. [→ 18](18-github.html#codegen)
1. **Put the boundary in a test, not in a convention.** Layering rules, string externalisation and file budgets that are not machine-checked decay within weeks. [→ 01](01-foundations-architecture.html#boundaries)
1. **Default-deny at the database, not in the client.** Row-level security is the only boundary that survives a modified client. [→ 07](07-supabase.html#rls)
1. **Make the CI prove the artifact runs, not just that it compiles.** A release build can pass every unit test and crash before the first frame. [→ 13](13-android.html#r8)
1. **Codify required checks and secrets as data you can diff.** Branch protection documented in prose but absent on the server protects nothing. [→ 18](18-github.html#protection)
1. **Record the failure next to the rule.** A rule whose rationale is lost gets deleted by the next person who finds it inconvenient. [→ 00](00-how-to-use-this-wiki.html#callouts)

#### Provenance

Derived on 2026-08-01 from the working state of two repositories, their CI configurations, their store metadata, and their post-mortem notes. Where this wiki states a version, a threshold or a workflow name, it was read from the repository rather than recalled. Where a claim is an inference or a recommendation rather than an observed fact, it says so.

The structure follows the [llms.txt](https://llmstxt.org/) convention for machine indexes, plus semantic-HTML and per-section chunk metadata as described in [page 00](00-how-to-use-this-wiki.html).
