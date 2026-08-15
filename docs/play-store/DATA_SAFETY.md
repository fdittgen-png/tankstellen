<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Play Store Data Safety Form Responses

> Reference document mirroring the Google Play Console Data Safety section.
> Last updated: 15 August 2026 — matches the corrected declaration sent for
> review on 14 August 2026 (#3712). The April 2026 version of this file
> declared "no data collection", which stopped being true when TankSync grew
> accounts and server-side sync — do NOT re-import the old answers.

## Overview

- **App collects or shares user data?** Yes
- **All data encrypted in transit?** Yes (all network calls use HTTPS/TLS)
- **Users can request data deletion?** Yes (local: Settings > Delete all data;
  account + server data: TankSync > Data Transparency > Delete account —
  wipes every owned row AND deletes the auth identity via the `delete_user`
  RPC, schema v6)
- **Account/data deletion URL (Console field):** https://fdittgen-png.github.io/tankstellen/privacy-policy/
- **Privacy policy URL:** https://fdittgen-png.github.io/tankstellen/privacy-policy/
  (NOT the GitHub repo URL — that was the pre-2026-08-14 mistake)

All collected types below share these answers: **optional / user-controlled**
(TankSync is off by default), **encrypted in transit**, **no third-party
sharing**, **not processed ephemerally** (synced data persists server-side
until the user deletes it).

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

---

## Data NOT collected

Name, phone number, physical address, health info, messages, photos/videos
(camera is only used for on-device receipt scanning the user initiates —
images never leave the device), audio, files, calendar, contacts, web
browsing history, installed apps, advertising ID, crash logs / performance
diagnostics (no Sentry or analytics SDK is active in shipped builds).

---

## Third-party services (query traffic, not "data sharing" in Play's sense)

Search coordinates are sent as query parameters to the fuel-price /
charging / geocoding APIs (Tankerkönig, Prix Carburants, national fuel
APIs, OpenChargeMap, Nominatim, OSM tiles) to answer the user's own
search. Nothing is sold or shared for advertising/analytics. TankSync data
goes only to the **user's chosen Supabase backend** (the developer-hosted
default or their own self-hosted project).

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
**Settings > Delete all data** removes profiles, favorites, API keys,
cached prices, trips and settings from the device.

### Account + server data (TankSync)
**TankSync > Data Transparency > Delete account** performs, in order:
1. Row wipe of every owned table (`UserDataSync.deleteAll` — favorites,
   alerts, push tokens, price reports, vehicles, fill-ups, itineraries,
   OBD2 baselines, ratings, tombstones, trips).
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
6. Everything else → **Not collected**
7. Encrypted in transit → Yes; deletion mechanism → Yes
8. Privacy policy URL: `https://fdittgen-png.github.io/tankstellen/privacy-policy/`
