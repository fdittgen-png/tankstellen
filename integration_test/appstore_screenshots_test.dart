// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// App Store screenshot GENERATOR (not a pass/fail test). Drives the real app
// to the populated Search-results screen with deterministic French station
// fixtures (no network/GPS), in en-US + fr-FR × light + dark, and captures a
// screenshot of each via the flutter-drive driver (test_driver/integration_test.dart).
//
// On the iPhone 17 Pro Max simulator each capture is 1320×2868 — exactly the
// App Store 6.9" iPhone slot. Run:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/appstore_screenshots_test.dart \
//     -d <iphone-17-pro-max-sim-udid>
//
// Reusable for every release. Mirrors the boot/seed pattern of
// golden_flow_integration_test.dart (#1113).
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tankstellen/app/app.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

/// Deterministic French (Pézenas-area) fixtures so the listing screenshots
/// look like a real run without touching the network or GPS.
const List<Station> _frenchStations = [
  Station(
    id: 'shot-1',
    name: 'Pézenas Carburant',
    brand: 'Indépendant',
    street: '18 Avenue de Verdun',
    postCode: '34120',
    place: 'Pézenas',
    lat: 43.4610,
    lng: 3.4230,
    dist: 0.4,
    e10: 1.659,
    e5: 1.719,
    diesel: 1.609,
    isOpen: true,
  ),
  Station(
    id: 'shot-2',
    name: 'Intermarché',
    brand: 'Intermarché',
    street: 'Route de Béziers',
    postCode: '34120',
    place: 'Pézenas',
    lat: 43.4555,
    lng: 3.4180,
    dist: 1.2,
    e10: 1.679,
    e5: 1.739,
    diesel: 1.629,
    isOpen: true,
  ),
  Station(
    id: 'shot-3',
    name: 'TotalEnergies',
    brand: 'TotalEnergies',
    street: '38 Avenue de Verdun',
    postCode: '34120',
    place: 'Pézenas',
    lat: 43.4620,
    lng: 3.4250,
    dist: 1.5,
    e10: 1.699,
    e5: 1.759,
    diesel: 1.649,
    isOpen: true,
  ),
  Station(
    id: 'shot-4',
    name: 'Carrefour Market',
    brand: 'Carrefour',
    street: 'Rue Henri Reboul',
    postCode: '34120',
    place: 'Pézenas',
    lat: 43.4700,
    lng: 3.4300,
    dist: 2.6,
    e10: 1.709,
    e5: 1.769,
    diesel: 1.659,
    isOpen: true,
  ),
  Station(
    id: 'shot-5',
    name: 'Esso Express',
    brand: 'Esso',
    street: 'Avenue Paul Vidal',
    postCode: '34120',
    place: 'Pézenas',
    lat: 43.4520,
    lng: 3.4350,
    dist: 3.3,
    e10: 1.729,
    e5: 1.789,
    diesel: 1.679,
    isOpen: false,
  ),
];

/// Deterministic German (Trier-area) fixtures — the de-DE listing should
/// show German brands and streets, not the French set (#3521).
const List<Station> _germanStations = [
  Station(
    id: 'shot-de-1',
    name: 'HEM Tankstelle',
    brand: 'HEM',
    street: 'Zurmaiener Straße 143',
    postCode: '54292',
    place: 'Trier',
    lat: 49.7666,
    lng: 6.6510,
    dist: 0.6,
    e10: 1.649,
    e5: 1.709,
    diesel: 1.579,
    isOpen: true,
  ),
  Station(
    id: 'shot-de-2',
    name: 'JET Trier',
    brand: 'JET',
    street: 'Ostallee 20',
    postCode: '54290',
    place: 'Trier',
    lat: 49.7530,
    lng: 6.6480,
    dist: 1.4,
    e10: 1.659,
    e5: 1.719,
    diesel: 1.589,
    isOpen: true,
  ),
  Station(
    id: 'shot-de-3',
    name: 'Aral Tankstelle',
    brand: 'ARAL',
    street: 'Bitburger Straße 47',
    postCode: '54294',
    place: 'Trier',
    lat: 49.7620,
    lng: 6.6210,
    dist: 2.1,
    e10: 1.689,
    e5: 1.749,
    diesel: 1.619,
    isOpen: true,
  ),
  Station(
    id: 'shot-de-4',
    name: 'Shell Station',
    brand: 'Shell',
    street: 'Saarstraße 5',
    postCode: '54290',
    place: 'Trier',
    lat: 49.7470,
    lng: 6.6350,
    dist: 2.8,
    e10: 1.699,
    e5: 1.759,
    diesel: 1.629,
    isOpen: true,
  ),
  Station(
    id: 'shot-de-5',
    name: 'Esso Station',
    brand: 'ESSO',
    street: 'Ruwerer Straße 35',
    postCode: '54292',
    place: 'Trier',
    lat: 49.7790,
    lng: 6.6700,
    dist: 3.9,
    e10: 1.709,
    e5: 1.769,
    diesel: 1.639,
    isOpen: false,
  ),
];

class _FakeStationService implements StationService {
  _FakeStationService(this._stations);
  final List<Station> _stations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async =>
      ServiceResult(
        data: _stations,
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) async =>
      ServiceResult(
        data: StationDetail(
          station: _stations.firstWhere((s) => s.id == id,
              orElse: () => _stations.first),
        ),
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) async =>
      ServiceResult(
        data: {for (final id in ids) id: const StationPrices(status: 'open')},
        source: ServiceSource.tankerkoenigApi,
        fetchedAt: DateTime.now(),
      );
}

/// Forces a fixed theme choice regardless of the simulator's system setting.
class _FixedTheme extends ThemeModeSetting {
  _FixedTheme(this._choice);
  final AppThemeChoice _choice;
  @override
  AppThemeChoice build() => _choice;
}

Future<void> _clearAllHiveBoxes() async {
  await Hive.close();
  const names = [
    'settings',
    'favorites',
    'cache',
    'profiles',
    'price_history',
    'alerts',
    'obd2_baselines',
    'obd2_trip_history',
    'achievements',
  ];
  for (final name in names) {
    try {
      await Hive.deleteBoxFromDisk(name);
    } catch (_) {/* box may not exist yet */}
  }
}

/// Boot "consent given + setup skipped + locale pinned" so the router lands
/// straight on the Search shell (mirrors golden_flow_integration_test.dart).
///
/// Listing polish (#3521): pin the country so the source-attribution banner
/// matches the fixture set (DE — Tankerkönig for the German shots, FR —
/// Prix-Carburants otherwise), seed a fresh GPS position so the store shot
/// shows the positive position bar instead of the error-tinted "position
/// unknown" one, and mark the favorites swipe tutorial as seen so its
/// one-time overlay doesn't cover the result list.
Future<void> _bootReady(String languageCode, {required bool german}) async {
  await _clearAllHiveBoxes();
  await HiveStorage.init();
  final storage = HiveStorage();
  await storage.putSetting(StorageKeys.gdprConsentGiven, true);
  await storage.skipSetup();
  await storage.putSetting('active_language_code', languageCode);
  await storage.putSetting('active_country_code', german ? 'DE' : 'FR');
  await storage.putSetting(StorageKeys.swipeTutorialShown, true);
  // #1690's one-time shell snackbar ("swipe between tabs") — its 5s timer
  // races the capture; pre-mark it shown so no shot ever carries it.
  await storage.putSetting('shell_swipe_hint_shown', true);
  await storage.putSetting(
      StorageKeys.userPositionLat, german ? 49.7666 : 43.4610);
  await storage.putSetting(
      StorageKeys.userPositionLng, german ? 6.6510 : 3.4230);
  await storage.putSetting(StorageKeys.userPositionTimestamp,
      DateTime.now().millisecondsSinceEpoch);
  await storage.putSetting(StorageKeys.userPositionSource, 'GPS');
  if (german) {
    // DE (Tankerkönig) requires an API key; without one the search header
    // renders the demo-mode banner instead of the country attribution. The
    // station service is faked, so the key's value is never sent anywhere.
    await storage.setApiKey('appstore-screenshot-placeholder');
  }
}

/// One capture per `flutter drive` process: cross-test Hive re-init in a
/// shared process corrupts every run after the first (empty result list,
/// stray tip snackbar). scripts/gen_appstore_screenshots.sh loops the shot
/// list, passing each key via `--dart-define=SHOT=<locale>_<mode>`. An empty
/// SHOT runs everything (the historical single-process batch mode).
const String _onlyShot = String.fromEnvironment('SHOT');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // All six App Store launch locales (#2560). de-DE gets the German fixture
  // set; the Romance-language locales share the French one. Light + dark for
  // the three biggest markets, light-only for the rest (#3521).
  const shots = <({String locale, String lang, AppThemeChoice theme, String mode, bool german})>[
    (locale: 'en-US', lang: 'en', theme: AppThemeChoice.light, mode: 'light', german: false),
    (locale: 'en-US', lang: 'en', theme: AppThemeChoice.dark, mode: 'dark', german: false),
    (locale: 'de-DE', lang: 'de', theme: AppThemeChoice.light, mode: 'light', german: true),
    (locale: 'de-DE', lang: 'de', theme: AppThemeChoice.dark, mode: 'dark', german: true),
    (locale: 'fr-FR', lang: 'fr', theme: AppThemeChoice.light, mode: 'light', german: false),
    (locale: 'fr-FR', lang: 'fr', theme: AppThemeChoice.dark, mode: 'dark', german: false),
    (locale: 'es-ES', lang: 'es', theme: AppThemeChoice.light, mode: 'light', german: false),
    (locale: 'it', lang: 'it', theme: AppThemeChoice.light, mode: 'light', german: false),
    (locale: 'pt-PT', lang: 'pt', theme: AppThemeChoice.light, mode: 'light', german: false),
  ];

  for (final s in shots) {
    if (_onlyShot.isNotEmpty && _onlyShot != '${s.locale}_${s.mode}') continue;
    testWidgets('appstore screenshot ${s.locale} ${s.mode}', (tester) async {
      await _bootReady(s.lang, german: s.german);

      final container = ProviderContainer(overrides: [
        stationServiceProvider.overrideWithValue(
          _FakeStationService(s.german ? _germanStations : _frenchStations),
        ),
        themeModeSettingProvider.overrideWith(() => _FixedTheme(s.theme)),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TankstellenApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Populate the results screen (no GPS/geocoding) — Trier for the
      // German set, Pézenas for the French one.
      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: s.german ? 49.7666 : 43.4610,
            lng: s.german ? 6.6510 : 3.4230,
            fuelType: FuelType.e10,
            radiusKm: 10.0,
          );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // pumpAndSettle alone is not enough on the live binding: captures have
      // repeatedly fired with the result list not yet built (blank list under
      // a correct "5 stations found" header). Wait for a fixture station to
      // actually be on screen before shooting, and fail loudly otherwise —
      // a blank store screenshot must never pass silently.
      final marker = s.german ? 'Zurmaiener' : 'Verdun';
      var visible = false;
      for (var i = 0; i < 20 && !visible; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        visible = tester.any(find.textContaining(marker));
      }
      expect(visible, isTrue,
          reason: 'station card "$marker" never rendered — screenshot would '
              'show an empty result list');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Android needs the surface converted before a screenshot; iOS captures
      // the native screen directly.
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
      }
      await binding.takeScreenshot('${s.locale}_${s.mode}_search');
    });
  }
}
