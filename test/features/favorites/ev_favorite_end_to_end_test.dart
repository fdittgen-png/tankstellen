import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/presentation/screens/ev_station_detail_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// End-to-end TDD test for #566: tapping the star on the EV station
/// detail screen must:
///   1. Persist the station to EV favorite storage (so Favorites tab shows it)
///   2. Flip isFavoriteProvider to true (so the star icon turns amber)
///
/// This test drives the EXACT screen the router uses (the one under
/// `search/presentation/screens/`, which after #560 uses the unified
/// `ev/` ChargingStation), backed by REAL Hive storage — no mocks for
/// favorites or storage.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ev_fav_e2e_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // Mirrors what EVChargingService returns: an OpenChargeMap-prefixed id.
  const testStation = ChargingStation(
    id: 'ocm-987654',
    name: 'IONITY Pézenas',
    operator: 'IONITY',
    latitude: 43.4672,
    longitude: 3.4242,
    dist: 1.1,
    address: 'A75 Aire de Pézenas',
    postCode: '34120',
    place: 'Pézenas',
    totalPoints: 6,
    isOperational: true,
  );

  Future<ProviderContainer> pumpDetailScreen(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        syncStateProvider.overrideWith(() => _DisabledSyncState()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EVStationDetailScreen(station: testStation),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  test(
    '#566 PROVIDER: toggle() with rawJson persists ID + JSON and '
    'favoritesProvider reflects it',
    () async {
      final container = ProviderContainer(
        overrides: [
          syncStateProvider.overrideWith(() => _DisabledSyncState()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(favoritesProvider), isEmpty);

      await container.read(favoritesProvider.notifier).toggle(
            testStation.id,
            rawJson: testStation.toJson(),
          );

      final storage = container.read(storageRepositoryProvider);
      expect(storage.getEvFavoriteIds(), contains(testStation.id),
          reason: 'ID must be in EV storage');
      expect(storage.getEvFavoriteStationData(testStation.id), isNotNull,
          reason: 'JSON must be in EV storage');
      expect(container.read(favoritesProvider), contains(testStation.id),
          reason:
              'favoritesProvider state must include the EV id after toggle()');
      expect(container.read(isFavoriteProvider(testStation.id)), isTrue,
          reason: 'isFavoriteProvider must report true after toggle()');
      expect(container.read(evFavoriteStationsProvider), hasLength(1),
          reason: 'EV station must appear in evFavoriteStationsProvider');
    },
  );

  testWidgets(
    '#566 tapping the star on an EV station detail screen adds it to '
    'favorites AND turns the star amber',
    (tester) async {
      final container = await pumpDetailScreen(tester);

      expect(container.read(isFavoriteProvider(testStation.id)), isFalse,
          reason: 'Start state: nothing favorited');
      expect(container.read(evFavoriteStationsProvider), isEmpty,
          reason: 'Start state: favorites tab is empty');

      final starFinder = find.byIcon(Icons.star_outline);
      expect(starFinder, findsOneWidget,
          reason: 'The star-outline button must be visible before favoriting');

      await tester.runAsync(() async {
        await tester.tap(starFinder);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // ----- POST-TAP EXPECTATIONS -----

      final storage = container.read(storageRepositoryProvider);
      expect(storage.getEvFavoriteIds(), contains(testStation.id),
          reason: 'EV favorite id must be in EV storage after tap');

      final data = storage.getEvFavoriteStationData(testStation.id);
      expect(data, isNotNull,
          reason: 'Station JSON must be persisted');
      expect(data!['id'], testStation.id);

      expect(container.read(favoritesProvider), contains(testStation.id),
          reason:
              'Unified favoritesProvider must include the EV id after tap');

      final evStations = container.read(evFavoriteStationsProvider);
      expect(evStations, hasLength(1),
          reason:
              'Favorites tab watches evFavoriteStationsProvider — the station must appear there');
      expect(evStations.first.id, testStation.id);

      expect(container.read(isFavoriteProvider(testStation.id)), isTrue,
          reason:
              'The same provider the detail screen watches must report true after the tap');

      await tester.pump();
      expect(find.byIcon(Icons.star), findsOneWidget,
          reason: 'Star icon must swap to the filled variant when favorited');
    },
  );

  testWidgets(
    '#566 tapping the filled star again removes the EV favorite',
    (tester) async {
      final container = await pumpDetailScreen(tester);

      await tester.runAsync(() async {
        await container.read(favoritesProvider.notifier).toggle(
              testStation.id,
              rawJson: testStation.toJson(),
            );
      });
      await tester.pump();

      expect(container.read(isFavoriteProvider(testStation.id)), isTrue);
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.star));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final storage = container.read(storageRepositoryProvider);
      expect(storage.getEvFavoriteIds(), isEmpty,
          reason: 'EV favorite id must be gone after untoggle');
      expect(storage.getEvFavoriteStationData(testStation.id), isNull,
          reason: 'EV favorite JSON must be gone after untoggle');

      expect(container.read(favoritesProvider), isEmpty);
      expect(container.read(isFavoriteProvider(testStation.id)), isFalse);
      expect(container.read(evFavoriteStationsProvider), isEmpty);

      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    },
  );
}

class _DisabledSyncState extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}
