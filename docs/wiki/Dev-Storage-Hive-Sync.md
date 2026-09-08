# Storage & Sync

Local-first persistence with optional Supabase-based cloud sync (TankSync).

## Hive boxes

`lib/core/storage/hive_boxes.dart`

Eight boxes total. Six are AES-encrypted with a key derived from FlutterSecureStorage; two non-PII boxes are unencrypted.

| Box | Encrypted | Contents | Access class |
|---|:-:|---|---|
| `settings` | ✅ | App config, locale, units, setup state, secure-storage migration flags | `SettingsHiveStore` |
| `profiles` | ✅ | User profiles (country, fuel preference, radius, landing, vehicle ref) | `ProfilesHiveStore` |
| `favorites` | ✅ | Favorite IDs + cached station data + EV favorites | `FavoritesHiveStore` |
| `cache` | ✅ | API response cache, itineraries | `CacheHiveStore` |
| `priceHistory` | ✅ | 30-day price records per station | `PriceHistoryHiveStore` |
| `alerts` | ✅ | Price alert rules | `AlertsHiveStore` |
| `obd2Baselines` | — | Per-vehicle consumption baselines (#769) | — |
| `obd2TripHistory` | — | OBD2 trip logs (#726) | — |

### Storage keys pattern

`lib/core/storage/storage_keys.dart` holds every string key as a constant: `StorageKeys.favoriteStationIds`, `StorageKeys.activeProfileId`, `StorageKeys.supabaseAnonKey`, etc. A pinning test (`test/core/storage/storage_keys_uniqueness_test.dart`) guarantees uniqueness and snake_case.

### Serialisation gotcha

Hive round-trips nested maps as `Map<dynamic, dynamic>`, but freezed's generated `fromJson` expects `Map<String, dynamic>`. Solution: `HiveBoxes.toStringDynamicMap()` deep-converts at every read (`hive_boxes.dart:152–177`). Every `*HiveStore` applies this before calling `fromJson`.

### Migrations

Three migrations live in `HiveBoxes._migrate*`:

1. **Encrypt-in-place** — on first init, unencrypted boxes are copied to encrypted and the plaintext box is deleted (`hive_boxes.dart:57–84`).
2. **Legacy landing screen enum** — rewrites `'search'` → `'nearest'` for profiles saved before v4.2.0 (`profile_repository.dart:40–46`).
3. **Supabase anon key** — moves the legacy plain-Hive key to secure storage on first TankSync load (`settings_hive_store.dart:98–112`).

Migrations are idempotent and log via `debugPrint`.

## Secure storage

`lib/core/storage/secure_storage.dart`

Wraps FlutterSecureStorage:

- Android → Android Keystore (hardware-backed where available)
- iOS → Keychain (not yet shipped)
- Windows → DPAPI

Stored here: Germany API key, OpenChargeMap API key, Supabase URL, Supabase anon key. Never logged, never sent to remote, never written to Hive plain.

## Profiles

`lib/features/profile/data/repositories/profile_repository.dart`

CRUD: `createProfile`, `updateProfile`, `deleteProfile`, `getActiveProfile`, `getAllProfiles`, `setActiveProfile`. First profile is auto-activated; deleting the active profile reassigns to the first remaining one.

`UserProfile` (freezed, `lib/features/profile/data/models/user_profile.dart:32–78`):

- **Core**: `id`, `name`, `preferredFuelType`
- **Search**: `defaultSearchRadius`, `homeZipCode`, `countryCode`, `languageCode`
- **UI**: `landingScreen` (enum: favorites/map/cheapest/nearest), `routeSegmentKm`, `avoidHighways`
- **Fuel/EV**: `showFuel`, `showElectric`, `hybridFuelChoice`, `defaultVehicleId`
- **Rating**: `ratingMode` (`local` / `private` / `shared`)
- **Filtering**: `preferredAmenities`
- **Consumption**: `showConsumptionTab`

`activeProfileProvider` is `keepAlive: true`; changes cascade to every feature that watches it.

## TankSync

`lib/core/sync/supabase_client.dart`, `lib/core/sync/sync_service.dart`

Optional. Disabled by default. When enabled:

### Auth

- Anonymous — UUID-only session, no email. Ensures `public.users` row exists (FK compliance).
- Email — optional, for multi-device linking.

### Initialisation

`TankSyncClient.init(url, anonKey)`:

1. Sanitises URL (trim, strip trailing slash).
2. Validates format.
3. Idempotent (safe to call on every app start).
4. Stores the anon key in secure storage.

### What syncs

| Object | Provider | Conflict strategy |
|---|---|---|
| Favorites | `syncFavorites()` | Union: upload local-only, return server ∪ local |
| Ignored stations | `syncIgnoredStations()` | Union |
| Ratings | `syncRating(rating)` | Upsert; `shared` flag controls row visibility |
| Alerts | `syncAlerts()` | Union |
| Profiles | via `syncProfiles()` | Last-write-wins per profile |
| Trajets (OBD2 + GPS) | `itineraries_sync.dart` | **Opt-in even after TankSync is enabled**; off by default. Settings → TankSync → Sync trajets. New trips sync from the moment the toggle is on; a manual **Backfill** action pushes pre-existing trips. **Forget all synced trajets** scrubs just the trip rows server-side without disabling sync (#2055-era). |

### Conflict resolution

**Local-first always**. The server never silently overwrites local data. Only an explicit user delete triggers a server delete (see `SyncAfterChangeMixin`).

### Triggers

- Initial sync after `TankSyncClient.init()` succeeds (non-blocking).
- `SyncAfterChangeMixin` triggers a sync after any favorite/alert mutation.
- Manual sync button in Settings → TankSync.
- No periodic sync — it's event-driven.

### Anon key provisioning

- **Community instance** — pre-configured in `CommunityConfig`; user taps Enable.
- **Self-hosted** — user pastes URL + key from QR or text.

### Row-level security

All tables enforce `user_id = auth.uid()` in RLS policies. The Supabase schema + RLS is in `supabase/migrations/*.sql`.

## Background tasks

`lib/core/background/`

`AndroidBackgroundPriceFetcher` registers two WorkManager periodic tasks:

```
priceRefreshTask          — frequency 1 h
  constraints: NetworkType.connected, requiresBatteryNotLow: true

priceRefreshChargingTask  — frequency 30 min
  constraints: NetworkType.connected, requiresCharging: true
```

### What runs

1. Fetch live prices for all favorite + alert stations (batch API).
2. Record into `PriceHistoryHiveStore` with 60-min dedup + 30-day retention trim.
3. Update cached station data.
4. Evaluate alert thresholds → `LocalNotificationService.show()` if matched.

### Isolate safety

Background tasks run in a **separate Dart isolate**:

- No Riverpod (provider tree lives in the main isolate only).
- Dio initialised inline.
- `HiveStorage.initInIsolate()` re-opens the same encrypted boxes.
- `HiveIsolateLock` is a file-based lock that prevents concurrent Hive access with the main isolate.
- Boxes closed at task end via `HiveBoxes.closeIsolateBoxes()`.

## Related

- [Caching Strategy](Dev-Caching-Strategy) — the cache box is one of the Hive stores
- [Fuzzy Logic Price Predictions](Dev-Fuzzy-Logic-Price-Predictions) — how PriceHistoryHiveStore feeds predictions
