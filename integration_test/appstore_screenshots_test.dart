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
Future<void> _bootReady(String languageCode) async {
  await _clearAllHiveBoxes();
  await HiveStorage.init();
  final storage = HiveStorage();
  await storage.putSetting(StorageKeys.gdprConsentGiven, true);
  await storage.skipSetup();
  await storage.putSetting('active_language_code', languageCode);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const shots = <({String locale, String lang, AppThemeChoice theme, String mode})>[
    (locale: 'en-US', lang: 'en', theme: AppThemeChoice.light, mode: 'light'),
    (locale: 'en-US', lang: 'en', theme: AppThemeChoice.dark, mode: 'dark'),
    (locale: 'fr-FR', lang: 'fr', theme: AppThemeChoice.light, mode: 'light'),
    (locale: 'fr-FR', lang: 'fr', theme: AppThemeChoice.dark, mode: 'dark'),
  ];

  for (final s in shots) {
    testWidgets('appstore screenshot ${s.locale} ${s.mode}', (tester) async {
      await _bootReady(s.lang);

      final container = ProviderContainer(overrides: [
        stationServiceProvider.overrideWithValue(
          _FakeStationService(_frenchStations),
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

      // Populate the results screen (no GPS/geocoding) — Pézenas, France.
      await container.read(searchStateProvider.notifier).searchByCoordinates(
            lat: 43.4610,
            lng: 3.4230,
            fuelType: FuelType.e10,
            radiusKm: 10.0,
          );
      await tester.pumpAndSettle(const Duration(seconds: 5));

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
