# Flutter & Platform Independence

## Why Flutter

Tankstellen needs:

- **One codebase**, many platforms (Android now, iOS planned, desktop possible)
- **Consistent UI** — the same interaction whether on a 5" Android or a tablet
- **No platform-specific forks** of business logic, price parsing, service chains

Flutter fits because:

1. **Rendering is owned by Flutter**, not the OS. Every country's station card looks identical, including non-Latin scripts (Greek, Cyrillic).
2. **Dart's async model** handles the 11-country API reality cleanly: no thread gymnastics, no green-thread debugging, just `async/await` and `Stream`.
3. **Material 3 + FlexColorScheme** provides a theme that respects both Material Android expectations and Cupertino iOS guidelines where it matters.
4. **Hot reload** shortens iteration cycles from 30 s (native Android) to <1 s.

## What's shared vs platform-specific

Roughly **97 %** of the codebase is shared Dart. Platform-specific code is isolated behind abstract interfaces.

### Shared (in `lib/`)

- All business logic
- All API integrations
- All UI widgets and screens
- All state management
- All caching and storage
- All price prediction / eco-score math
- All route search strategies
- All localisation (23 ARB files)

### Platform-specific (behind abstractions)

| Concern | Abstract interface | Android impl | Notes |
|---|---|---|---|
| Bluetooth | `BluetoothFacade` | `PluginBluetoothFacade` (flutter_blue_plus) | `obd2_permissions.dart` is platform-gated |
| Location | `LocationProvider` | `GeolocatorLocationProvider` | iOS impl would be identical via geolocator |
| Notifications | `LocalNotificationService` | `FlutterLocalNotificationsService` | Android 13+ needs `POST_NOTIFICATIONS` permission |
| Background | WorkManager | `AndroidBackgroundPriceFetcher` | iOS: BGTaskScheduler when porting |
| Secure storage | `SecureStorage` | `FlutterSecureStorage` (Keystore) | iOS: Keychain; Windows: DPAPI |
| Geocoding | `GeocodingProvider` | `NativeGeocodingProvider` + `NominatimGeocodingProvider` | Native falls through to Nominatim |
| Home-screen widget | `widget_platform.dart` (method channel) | Kotlin RemoteViews | iOS: WidgetKit when porting |

### Pure native only

- `android/app/src/main/kotlin/.../TankstellenWidgetProvider.kt` — the home widget. All state is passed from Dart via SharedPreferences bridging.
- `android/app/build.gradle` — signing, split-per-ABI, versioning (read from `pubspec.yaml`).
- `AndroidManifest.xml` — permissions (BLE split, no-foreground-service, `neverForLocation`).

## How Flutter helps each platform

### Android (shipping)

- **APK + AAB** built from CI, both in-repo scripts and the Play Console pipeline.
- **Min SDK 24** (Android 7) — 99 %+ of active devices.
- **Target SDK 36** — Android 15.
- **Split per ABI** — three APKs (armeabi-v7a, arm64-v8a, x86_64) keep install size ~20 MB each vs 60 MB fat AAB.

### iOS (planned)

The code compiles on iOS today. What's missing for ship-readiness:

- BLE permissions on iOS plist (`NSBluetoothAlwaysUsageDescription`, etc.)
- Replace `WorkManager` with `BGTaskScheduler`
- Home-widget replacement with WidgetKit
- App Store review process for OBD2 read access (requires entitlements)
- CI runner for iOS (currently Linux only)

### Desktop (not shipping)

- `windows/`, `linux/`, `macos/` directories exist but aren't tested.
- OBD2 would need a USB-serial transport (the BLE abstraction still works via flutter_blue_plus desktop).
- The layout already adapts: `NavigationRail` on ≥600 dp, which is desktop-sized.

### Web (dev only)

Used for quick UI review in the browser. Disabled in production because:

- Hive web is IndexedDB-backed — works, but data doesn't survive browser storage cleanup.
- Nominatim and OSM tiles have permissive CORS, but Tankerkoenig does not.
- No OBD2 (Web Bluetooth isn't universal enough).

## Flutter versions

- **Flutter 3.41.5** (stable channel, pinned in CI)
- **Dart 3.11.3**

Pinning avoids "works on my machine but CI fails" issues. Bumps happen via a dedicated `chore/bump-flutter` branch, tested against the full suite.

## The "no Google dependency" rule

The privacy policy commits to no Google Play Services and no Firebase. Flutter plugins are vetted before adoption:

- ❌ Any plugin that requires `com.google.gms:google-services`
- ❌ Any plugin that transitively pulls Firebase
- ✅ flutter_blue_plus (BLE, MIT, no GMS)
- ✅ geolocator (location, MIT, no GMS when fused provider isn't mandatory)
- ✅ workmanager (background, MIT, pure WorkManager)

Transitive deps are audited via `flutter pub deps --style=compact` on every `dependabot` PR.

## Related

- [Project Structure](Dev-Project-Structure) — where each platform sits on disk
- [OBD2 Implementation](Dev-OBD2-Implementation) — example of the facade pattern for platform isolation
