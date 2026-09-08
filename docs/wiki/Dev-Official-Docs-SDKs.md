# Official Documentation & SDKs

Quick-reference for every external piece we depend on. Arranged so you can find *"what's the API for X"* in under 30 seconds.

---

## Language & framework

| Resource | Link | Version / pinned |
|---|---|---|
| **Flutter** — main docs | https://docs.flutter.dev/ | 3.41.5 |
| **Flutter API reference** | https://api.flutter.dev/ | 3.41.5 |
| **Dart** — language tour | https://dart.dev/guides | 3.11 |
| **Dart API** | https://api.dart.dev/ | 3.11 |
| **Effective Dart** | https://dart.dev/effective-dart | style reference |
| **Dart pub.dev** | https://pub.dev/ | package index |

## State management

| Resource | Link | Notes |
|---|---|---|
| **Riverpod docs** | https://riverpod.dev/ | v3 generator-based API |
| **riverpod package** | https://pub.dev/packages/riverpod | 3.0.3 in pubspec |
| **riverpod_annotation** | https://pub.dev/packages/riverpod_annotation | `@riverpod` source-gen |
| **hooks_riverpod** | https://pub.dev/packages/hooks_riverpod | not used — we prefer plain `ConsumerWidget` |

## Persistence

| Resource | Link | Notes |
|---|---|---|
| **Hive** | https://docs.hivedb.dev/ | v2.2.3 — stay on v2, v4 is WIP |
| **hive_flutter** | https://pub.dev/packages/hive_flutter | integration helpers |
| **flutter_secure_storage** | https://pub.dev/packages/flutter_secure_storage | Android Keystore wrapper |
| **path_provider** | https://pub.dev/packages/path_provider | file system locations |

## HTTP / networking

| Resource | Link | Notes |
|---|---|---|
| **Dio** | https://pub.dev/packages/dio | 5.x |
| **Dio interceptors** | https://pub.dev/packages/dio#interceptors | pattern used by `RateLimitInterceptor` |
| **connectivity_plus** | https://pub.dev/packages/connectivity_plus | network-state detection |
| **http (dart:io)** | https://api.dart.dev/dart-io/HttpClient-class.html | low-level, used only in tests |

## Models / code generation

| Resource | Link | Notes |
|---|---|---|
| **freezed** | https://pub.dev/packages/freezed | immutable models + sealed unions |
| **json_serializable** | https://pub.dev/packages/json_serializable | JSON codec generation |
| **build_runner** | https://pub.dev/packages/build_runner | runs the generators |

Regenerate: `dart run build_runner build --delete-conflicting-outputs`

## Routing & navigation

| Resource | Link | Notes |
|---|---|---|
| **go_router** | https://pub.dev/packages/go_router | declarative routing |
| **go_router cookbook** | https://docs.flutter.dev/cookbook/navigation | common patterns |
| **StatefulShellRoute** | https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html | the shell used in `app/shell_screen.dart` |

## Maps

| Resource | Link | Notes |
|---|---|---|
| **flutter_map** | https://docs.fleaflet.dev/ | 7.x |
| **flutter_map_marker_cluster** | https://pub.dev/packages/flutter_map_marker_cluster | dense-area clustering |
| **OpenStreetMap wiki** | https://wiki.openstreetmap.org/ | tile server policies, attribution |
| **OSM tile usage policy** | https://operations.osmfoundation.org/policies/tiles/ | **read before adding features** |
| **Nominatim** | https://nominatim.org/release-docs/develop/api/Overview/ | geocoding API reference |
| **Nominatim usage policy** | https://operations.osmfoundation.org/policies/nominatim/ | ≤1 req/s, cache aggressively |

## Routing engines

| Resource | Link | Notes |
|---|---|---|
| **OSRM** | http://project-osrm.org/docs/v5.24.0/api/ | public routing service |
| **OSRM demo server policy** | https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server | fair use |

## Bluetooth / OBD2

| Resource | Link | Notes |
|---|---|---|
| **flutter_blue_plus** | https://pub.dev/packages/flutter_blue_plus | BLE library |
| **flutter_blue_plus source** | https://github.com/chipweinberger/flutter_blue_plus | for issue reports |
| **Android BLE permissions (12+)** | https://developer.android.com/develop/connectivity/bluetooth/bt-permissions | BLUETOOTH_SCAN / CONNECT model |
| **ELM327 datasheet** | https://www.elmelectronics.com/wp-content/uploads/2016/07/ELM327DS.pdf | AT command set |
| **OBD-II PIDs (Wikipedia)** | https://en.wikipedia.org/wiki/OBD-II_PIDs | canonical PID table |
| **SAE J1979 standard** | https://www.sae.org/standards/content/j1979_202202/ | paywalled, but referenced |

See our own [OBD2 Implementation](Dev-OBD2-Implementation) for the adapter registry and PID table we actually read.

## Background tasks

| Resource | Link | Notes |
|---|---|---|
| **workmanager (Flutter)** | https://pub.dev/packages/workmanager | wrapper we use |
| **Android WorkManager** | https://developer.android.com/topic/libraries/architecture/workmanager | underlying API |
| **Doze & App Standby** | https://developer.android.com/training/monitoring-device-state/doze-standby | what limits background frequency |

## Location

| Resource | Link | Notes |
|---|---|---|
| **geolocator** | https://pub.dev/packages/geolocator | GPS wrapper |
| **Android location permissions** | https://developer.android.com/training/location/permissions | precise / coarse / background |

## Notifications

| Resource | Link | Notes |
|---|---|---|
| **flutter_local_notifications** | https://pub.dev/packages/flutter_local_notifications | local only — no FCM |
| **Android 13+ POST_NOTIFICATIONS** | https://developer.android.com/develop/ui/views/notifications/notification-permission | runtime perm |

## UI & theming

| Resource | Link | Notes |
|---|---|---|
| **Material 3** | https://m3.material.io/ | spec we follow |
| **FlexColorScheme** | https://pub.dev/packages/flex_color_scheme | theme generation |
| **shimmer** | https://pub.dev/packages/shimmer | loading placeholders |
| **flutter_svg** | https://pub.dev/packages/flutter_svg | SVG icons |

## Internationalization

| Resource | Link | Notes |
|---|---|---|
| **Flutter i18n guide** | https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization | `gen-l10n` pipeline |
| **ARB spec** | https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification | ICU messages in `lib/l10n/app_*.arb` |
| **intl** | https://pub.dev/packages/intl | dates, numbers, plurals |
| **ICU MessageFormat** | https://unicode-org.github.io/icu/userguide/format_parse/messages/ | plural / select syntax |

## Cloud sync (optional)

| Resource | Link | Notes |
|---|---|---|
| **Supabase** | https://supabase.com/docs | backend we use for TankSync |
| **supabase_flutter SDK** | https://pub.dev/packages/supabase_flutter | Dart client |
| **Supabase Auth** | https://supabase.com/docs/guides/auth | anonymous + email |
| **Supabase RLS** | https://supabase.com/docs/guides/database/postgres/row-level-security | we enforce `user_id = auth.uid()` |
| **Supabase Edge Functions** | https://supabase.com/docs/guides/functions | planned for server-side alerts |
| **PostgREST** | https://postgrest.org/ | the query layer Supabase exposes |
| **Supabase CLI** | https://supabase.com/docs/guides/cli | `supabase start`, `db push`, `functions deploy` |

## Country data sources

The 11 live APIs and their official docs:

| Country | Provider | Docs / endpoint | API key |
|---|---|---|---|
| 🇩🇪 Germany | Tankerkoenig (creativecommons.tankerkoenig.de) | https://creativecommons.tankerkoenig.de/ | Yes, free |
| 🇫🇷 France | data.gouv.fr — Prix des carburants | https://www.data.gouv.fr/fr/datasets/prix-des-carburants-en-france-flux-quotidien/ | No |
| 🇦🇹 Austria | E-Control Spritpreisrechner | https://www.e-control.at/marktteilnehmer/sprit-preis-rechner | No (rate limited) |
| 🇪🇸 Spain | MITECO (Ministerio) | https://sedeaplicaciones.mineco.gob.es/ServiciosWEB/API.aspx | No |
| 🇮🇹 Italy | MISE / MIMIT Carburanti | https://www.mimit.gov.it/it/mercato-e-consumatori/osservatorio-prezzi-e-tariffe/carburanti | No |
| 🇩🇰 Denmark | OK / Shell DK scraped + open data | (per-provider — see station_service impl) | No |
| 🇵🇹 Portugal | DGEG — Preçosonline | https://precos.dgeg.gov.pt/ | No |
| 🇬🇧 United Kingdom | UK Govt. Fuel Price Transparency | https://www.gov.uk/government/publications/fuel-price-transparency-data-collection | No |
| 🇦🇷 Argentina | Energía Argentina — precios de combustibles | https://datos.energia.gob.ar/dataset/precios-en-surtidor | No (HTTPS enforced — #731) |
| 🇦🇺 Australia | Per-state govt APIs | varies | No |
| 🇲🇽 Mexico | CRE — Precios | https://datos.gob.mx/busca/dataset/precios-vigentes-de-gasolinas-y-diesel | No |

## EV charging

| Resource | Link | Notes |
|---|---|---|
| **OpenChargeMap API** | https://openchargemap.org/site/develop/api | reference used by `EVChargingService` |
| **OCM data model** | https://openchargemap.org/site/develop/reference | connector types, power levels |
| **Register for a key** | https://openchargemap.org/ → My Profile → My Apps | optional; raises rate limit |

## Platform

### Android

| Resource | Link | Notes |
|---|---|---|
| **Android developer portal** | https://developer.android.com/ | canonical |
| **Jetpack** | https://developer.android.com/jetpack | WorkManager, Keystore live here |
| **Play Console** | https://play.google.com/console/ | builds, testing tracks, release |
| **Play Console policies** | https://support.google.com/googleplay/android-developer | **read before every release** |
| **Android Keystore System** | https://developer.android.com/privacy-and-security/keystore | hardware-backed secure storage |
| **App Bundle (AAB) docs** | https://developer.android.com/guide/app-bundle | what we publish |
| **Split APKs** | https://developer.android.com/studio/build/configure-apk-splits | per-ABI artefacts |

### iOS *(planned)*

| Resource | Link | Notes |
|---|---|---|
| **Apple Developer** | https://developer.apple.com/documentation/ | canonical |
| **iOS runtime docs (Flutter)** | https://docs.flutter.dev/deployment/ios | shipping guide |
| **Keychain** | https://developer.apple.com/documentation/security/keychain_services | flutter_secure_storage backend |
| **WidgetKit** | https://developer.apple.com/documentation/widgetkit/ | for porting our home-screen widget |

## Testing

| Resource | Link | Notes |
|---|---|---|
| **flutter_test** | https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html | base test library |
| **integration_test** | https://docs.flutter.dev/cookbook/testing/integration/introduction | full-flow tests |
| **mocktail** | https://pub.dev/packages/mocktail | we prefer fakes but mocktail covers callbacks |
| **Flutter testing guide** | https://docs.flutter.dev/testing | pyramid + conventions |
| **LCOV format** | https://ltp.sourceforge.net/coverage/lcov.php | what coverage reports emit |

## CI / CD

| Resource | Link | Notes |
|---|---|---|
| **GitHub Actions docs** | https://docs.github.com/en/actions | workflow reference |
| **GitHub Actions Flutter setup** | https://github.com/subosito/flutter-action | the action we use |
| **Dependabot config** | https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file | `.github/dependabot.yml` reference |
| **Semantic versioning** | https://semver.org/ | releases follow `major.minor.patch+build` |
| **Conventional Commits** | https://www.conventionalcommits.org/en/v1.0.0/ | commit-message spec |

## GDPR & privacy

| Resource | Link | Notes |
|---|---|---|
| **GDPR full text** | https://gdpr-info.eu/ | indexed per article |
| **EU Commission — data protection rules** | https://commission.europa.eu/law/law-topic/data-protection_en | official guidance |
| **Google Play Data safety** | https://support.google.com/googleplay/android-developer/answer/10787469 | form we fill on the Play Console |

---

## Our own references

Not external but worth listing here for completeness:

- [PRIVACY.md](https://github.com/fdittgen-png/tankstellen/blob/master/PRIVACY.md) — full privacy policy
- [SECURITY.md](https://github.com/fdittgen-png/tankstellen/blob/master/SECURITY.md) — security reporting
- [CODE_OF_CONDUCT.md](https://github.com/fdittgen-png/tankstellen/blob/master/CODE_OF_CONDUCT.md) — community norms
- [README.md](https://github.com/fdittgen-png/tankstellen/blob/master/README.md) — repo intro

## Related wiki pages

- [Architecture Overview](Dev-Architecture-Overview) — how these SDKs compose in the app
- [Service Layer & Fallback](Dev-Service-Layer-Fallback) — how we wrap each country API
- [Adding a Country](Dev-Adding-A-Country) — the playbook for a new data source
- [OBD2 Implementation](Dev-OBD2-Implementation) — detailed ELM327 + BLE stack
- [Storage & Sync](Dev-Storage-Hive-Sync) — Hive box layout, TankSync model
