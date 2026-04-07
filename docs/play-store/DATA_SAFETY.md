# Play Store Data Safety Form Responses

> Reference document for completing the Google Play Console Data Safety section.
> Last updated: 7 April 2026

## Overview

- **App collects or shares user data?** Yes
- **All data encrypted in transit?** Yes (all network calls use HTTPS/TLS)
- **Users can request data deletion?** Yes (local: Settings > Delete all data; server: TankSync > Data Transparency > Delete everything)
- **Privacy policy URL:** https://fdittgen-png.github.io/tankstellen/

---

## Data types

### Location

| Question | Answer |
|----------|--------|
| **Is location data collected?** | Yes |
| **Approximate or precise?** | Approximate |
| **Is it shared with third parties?** | Yes (sent to fuel price APIs as search parameter) |
| **Is it processed ephemerally?** | Yes (not stored on any server; used only for the current search request) |
| **Is collection required or optional?** | Optional (user can search by postal code instead) |
| **Purpose** | App functionality (finding nearby fuel stations) |

### Device or other IDs

| Question | Answer |
|----------|--------|
| **Are device IDs collected?** | No |
| **Are other identifiers collected?** | Yes (anonymous UUID if TankSync is enabled) |
| **Is it shared with third parties?** | No |
| **Is collection required or optional?** | Optional (only if TankSync is enabled) |
| **Purpose** | App functionality (cloud sync of favorites and alerts) |

---

## Data NOT collected

The following data types are NOT collected, stored, or shared:

| Data type | Collected? |
|-----------|-----------|
| Name | No |
| Email address | No |
| Phone number | No |
| Address | No |
| Financial info (payment, purchase history) | No |
| Health info | No |
| Messages | No |
| Photos or videos | No |
| Audio | No |
| Files and docs | No |
| Calendar | No |
| Contacts | No |
| App activity (page views, taps) | No |
| Web browsing history | No |
| Search history (on device only, never transmitted) | No |
| Installed apps | No |
| Crash logs | No (Sentry is not active; if enabled in future, it will be opt-in only) |
| Performance diagnostics | No |
| Advertising ID | No |

---

## Third-party data sharing

| Third party | Data shared | Purpose |
|------------|-------------|---------|
| Tankerkoenig (creativecommons.tankerkoenig.de) | Search coordinates, user API key | Fuel price lookup (Germany) |
| Prix Carburants (data.economie.gouv.fr) | Search coordinates | Fuel price lookup (France) |
| Italian fuel API (osservaprezzi.mise.gov.it) | Search coordinates | Fuel price lookup (Italy) |
| Spanish fuel API (sedeaplicaciones.minetur.gob.es) | Search coordinates | Fuel price lookup (Spain) |
| Austrian fuel API (spritpreisrechner.at) | Search coordinates | Fuel price lookup (Austria) |
| Belgian fuel API (fuelwatch.be) | Search coordinates | Fuel price lookup (Belgium) |
| Luxembourg fuel API (data.public.lu) | Search coordinates | Fuel price lookup (Luxembourg) |
| OpenChargeMap (api.openchargemap.io) | Search coordinates | EV charging station lookup |
| Nominatim / OpenStreetMap | Search text or coordinates | Geocoding / reverse geocoding |
| OpenStreetMap tile servers | Map viewport coordinates | Map tile rendering |
| Supabase (optional, TankSync only) | Anonymous UUID, favorite IDs, alert configs, price reports | Cloud sync |

---

## Security practices

| Practice | Status |
|----------|--------|
| Data encrypted in transit | Yes (HTTPS/TLS for all API calls) |
| Data encrypted at rest | Yes (API keys in Android Keystore; local DB on device storage) |
| User can request data deletion | Yes |
| Committed to Play Families Policy | No (app is not targeted at children) |
| Independent security review | No |

---

## Data deletion

### Local data
Users can delete all local data from **Settings > Delete all data**. This removes:
- All search profiles and fuel preferences
- All favorite stations
- API keys
- All cached search results and prices
- All app settings

### Server data (TankSync)
If TankSync is enabled, users can delete all server-side data from
**TankSync > Data Transparency > Delete everything**. This performs a cascade delete of:
- User record
- Synced favorites
- Price alerts and push tokens
- Community price reports

After deletion, the anonymous account is removed and cannot be recovered.

---

## Notes for Play Console submission

1. Select **"Yes"** for "Does your app collect or share any of the required user data types?"
2. Under **Location**: select "Approximate location", mark as "Collected", purpose "App functionality", shared with third parties (API providers), processed ephemerally
3. Under **Device or other IDs**: select "Other identifiers" (anonymous UUID), mark as "Collected" only if TankSync is enabled, purpose "App functionality", not shared
4. All other data categories: select **"Not collected"**
5. Confirm data is encrypted in transit
6. Confirm users can request deletion
7. Provide privacy policy URL: `https://fdittgen-png.github.io/tankstellen/`
