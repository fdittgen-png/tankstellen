<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Play Store Data Safety Form Responses

> Reference document mirroring the Google Play Console Data Safety section.
> Last updated: 29 August 2026 — reconciled with privacy policy **v3**
> (29 August 2026, Epic #3865) and the machine-readable inventory
> `docs/privacy/data_inventory.json`, which is the source of truth for the
> collected types below. The 15 August 2026 revision matched the corrected
> declaration sent for review on 14 August 2026 (#3712). The April 2026
> version of this file declared "no data collection", which stopped being
> true when TankSync grew accounts and server-side sync — do NOT re-import
> the old answers.

## Overview

- **App collects or shares user data?** Yes
- **All data encrypted in transit?** Yes (all network calls use HTTPS/TLS)
- **Users can request data deletion?** Yes (local: Settings > Privacy
  Dashboard > Delete all data; account + server data: TankSync > Data
  Transparency > Delete account — wipes every owned row in one transaction
  AND deletes the auth identity, including any linked e-mail)
- **Account/data deletion URL (Console field):** https://fdittgen-png.github.io/tankstellen/privacy-policy/
- **Privacy policy URL:** https://fdittgen-png.github.io/tankstellen/privacy-policy/
  (NOT the GitHub repo URL — that was the pre-2026-08-14 mistake)

All collected types below share these answers: **optional / user-controlled**
(TankSync and Error reporting are off by default), **encrypted in transit**,
**no third-party sharing** in Play's sense (Supabase and Sentry act as
processors on the developer's behalf), **not processed ephemerally** (synced
data persists server-side until the user deletes it; Sentry keeps crash
reports 90 days).

Collected types, exactly as the inventory lists them: **Email address**,
**User IDs**, **Precise location**, **Purchase history** (fill-ups), **Other
user-generated content**, **Crash logs**, **Diagnostics**.

---

## Data types declared as COLLECTED

### Personal info

| Question | Answer |
|----------|--------|
| **Email address** | Yes — Supabase auth; the anonymous account can be upgraded to an e-mail login for cross-device sync |
| **User IDs** | Yes — Supabase auth UUID (anonymous by default) |
| **Shared with third parties?** | No |
| **Required or optional?** | Optional (TankSync only; e-mail only if the user links one) |
| **Purpose** | App functionality (cloud sync, cross-device account) |

### Location

| Question | Answer |
|----------|--------|
| **Approximate or precise?** | **Precise** (FINE permission + `LocationAccuracy.high` GPS trip recording; routes sync to `trip_summaries`/`trip_details`) |
| **Shared with third parties?** | No (search coordinates go to fuel-price APIs as query parameters, but recorded trip locations are never shared) |
| **Required or optional?** | Optional (trip recording and TankSync are both opt-in) |
| **Purpose** | App functionality (trip recording/statistics, nearby-station search) |

### Financial info

| Question | Answer |
|----------|--------|
| **Purchase history** | Yes — `fill_ups` sync carries cost, litres and odometer |
| **Shared with third parties?** | No |
| **Required or optional?** | Optional (TankSync only) |
| **Purpose** | App functionality (fuel-cost tracking across devices) |

### App activity

| Question | Answer |
|----------|--------|
| **Other user-generated content** | Yes — `price_reports` free text (readable by all authenticated users of the same TankSync backend), `station_ratings`, trip shares |
| **Shared with third parties?** | No |
| **Required or optional?** | Optional |
| **Purpose** | App functionality (community price reports, ratings, sharing) |

### App info and performance

| Question | Answer |
|----------|--------|
| **Crash logs** | Yes — opt-in via the **Error reporting** consent (off by default), sent to Sentry |
| **Diagnostics** | Yes — opt-in performance traces via the same consent, sent to Sentry |
| **Linked to the user's identity?** | No — traces are scrubbed of e-mail addresses, coordinates and tokens before they are stored or sent; no user ID is attached |
| **Shared with third parties?** | No (Sentry is a processor; EU/US under the EU-US Data Privacy Framework) |
| **Required or optional?** | Optional (Error reporting consent; revocable under Settings > Privacy & data) |
| **Purpose** | Analytics in Play's taxonomy (crash diagnostics — fixing bugs) |

The Sentry SDK ships in the Play and iOS builds and stays dormant until the
user opts in; the F-Droid flavor has it compiled out entirely.

---

## Data NOT collected

Name, phone number, physical address, health info, messages, photos/videos
(camera is only used for on-device receipt scanning the user initiates —
images never leave the device), audio, files, calendar, contacts, web
browsing history, installed apps, advertising ID.

---

## Third-party services (query traffic, not "data sharing" in Play's sense)

Search coordinates are sent as query parameters to the fuel-price /
charging / geocoding APIs (Tankerkönig, Prix Carburants, national fuel
APIs, OpenChargeMap, Nominatim, OSM tiles — by default through the
Sparkilo tile proxy on the same EU Supabase project, which the user can
switch off under Settings > Privacy) to answer the user's own search.
Nothing is sold or shared for advertising/analytics. TankSync data goes
only to the **user's chosen Supabase backend** (the developer-hosted
Sparkilo Community project in the EU, AWS eu-central-1, or their own
self-hosted project).

---

## Security practices

| Practice | Status |
|----------|--------|
| Data encrypted in transit | Yes (HTTPS/TLS for all API calls) |
| Data encrypted at rest | API keys in Android Keystore / iOS Keychain; server data under Supabase RLS (`user_id = auth.uid()` on every synced table) |
| User can request deletion | Yes — in-app, no support ticket needed |
| Committed to Play Families Policy | No (app is not targeted at children) |
| Independent security review | No |

---

## Data deletion

### Local data
**Settings > Privacy Dashboard > Delete all data** removes every database
the app keeps on the device — profiles, favorites, alerts, price history,
cached prices, vehicles, fill-ups, recorded trips and their GPS samples,
OBD2 baselines, service reminders, error traces, API keys, tokens and the
widget data — and returns the app to its first-launch state.

### Export
**Settings > Privacy Dashboard > Export all my data** writes one ZIP with a
machine-readable JSON per category, one GPX per trip, the consent record and
a JSON export of every server table (Art. 20 GDPR portability).

### Account + server data (TankSync)
**TankSync > Data Transparency > Delete account** performs, in order:
1. Row wipe of every owned table in one transaction (favorites, alerts,
   ignored stations, price reports, content reports, vehicles, fill-ups,
   itineraries, OBD2 baselines, ratings, trips, trip shares given or
   received, wait-time pings, sync settings, deletion tombstones and the
   `users` row). If a table could not be erased the app names it instead of
   claiming success.
2. **Auth identity deletion** via the `delete_user` SECURITY DEFINER RPC
   (schema v6, #3712) — removes the `auth.users` row, including any
   linked e-mail. Self-hosted schemas older than v6 are flagged by the
   schema-version verifier.
3. Sign-out and local sync-state reset.

After deletion the account cannot be recovered.

---

## Notes for Play Console submission

1. "Does your app collect or share any of the required user data types?" → **Yes**
2. **Personal info** → Email address + User IDs: collected, optional, app functionality, not shared
3. **Location** → **Precise location**: collected, optional, app functionality, not shared, not ephemeral
4. **Financial info** → Purchase history: collected, optional, app functionality, not shared
5. **App activity** → Other user-generated content: collected, optional, app functionality, not shared
6. **App info and performance** → Crash logs + Diagnostics: collected, optional (Error reporting consent), analytics, not shared, not linked to identity
7. Everything else → **Not collected**
8. Encrypted in transit → Yes; deletion mechanism → Yes
9. Privacy policy URL: `https://fdittgen-png.github.io/tankstellen/privacy-policy/` (policy v3, 29 August 2026)
