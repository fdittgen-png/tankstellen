// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/sync/sync_events.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/itinerary/providers/itinerary_provider.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';
import 'package:tankstellen/features/search/providers/station_rating_provider.dart';

import '../../../fakes/fake_hive_storage.dart';
import '../../../helpers/silence_error_logger.dart';

/// #3446 acceptance — each formerly-stale one-shot provider re-reads
/// LOCAL storage when its table's [SyncTableChanged] lands on the bus,
/// so pulled server rows appear in-session instead of one restart late.
///
/// Each test simulates a sync pull's persist step (write to storage
/// directly, exactly what the merges do) and then emits the event the
/// persist site fires — asserting the provider state catches up WITHOUT
/// an invalidate/restart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  silenceErrorLoggerSpool();

  late FakeHiveStorage fakeStorage;
  late ProviderContainer container;

  setUp(() {
    fakeStorage = FakeHiveStorage();
    container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(fakeStorage),
    ]);
    addTearDown(container.dispose);
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('stale-provider refresh on sync events (#3446)', () {
    test('connect-time favorites pull → favoritesProvider reflects it',
        () async {
      await fakeStorage.setFavoriteIds(['local-1']);
      expect(container.read(favoritesProvider), ['local-1']);

      // What syncAndPersistIds does: persist the union, then emit.
      await fakeStorage.setFavoriteIds(['local-1', 'server-1']);
      SyncEvents.instance.emitIdSetDelta(
          SyncTables.favorites, ['local-1'], ['local-1', 'server-1']);
      await flush();

      expect(container.read(favoritesProvider),
          containsAll(<String>['local-1', 'server-1']));
    });

    test('connect-time ignored pull → ignoredStationsProvider reflects it',
        () async {
      expect(container.read(ignoredStationsProvider), isEmpty);

      await fakeStorage.setIgnoredIds(['server-hidden']);
      SyncEvents.instance.emitIdSetDelta(
          SyncTables.ignoredStations, const [], ['server-hidden']);
      await flush();

      expect(container.read(ignoredStationsProvider), ['server-hidden']);
    });

    test('launch ratings pull → stationRatingsProvider reflects it '
        'without restart', () async {
      await fakeStorage.setRating('st-local', 4);
      expect(container.read(stationRatingsProvider), {'st-local': 4});

      // What syncAndPersistRatings does: write server-only, then emit.
      await fakeStorage.setRating('st-server', 5);
      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.stationRatings, 1));
      await flush();

      expect(container.read(stationRatingsProvider),
          {'st-local': 4, 'st-server': 5});
    });

    test('trips merge → TripHistoryList refreshes from the repository',
        () async {
      final fakeRepo = _FakeTripHistoryRepository();
      final c = ProviderContainer(overrides: [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        tripHistoryRepositoryProvider.overrideWith((ref) => fakeRepo),
      ]);
      addTearDown(c.dispose);

      expect(c.read(tripHistoryListProvider), isEmpty);

      // What runTripsSyncMerge does: repo.save the server-only
      // summaries, then emit.
      fakeRepo.entries.add(_entry('server-trip'));
      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.tripSummaries, 1));
      await flush();

      expect(c.read(tripHistoryListProvider).map((e) => e.id),
          contains('server-trip'));
    });

    test('itineraries pull → itineraryProvider re-reads storage', () async {
      expect(container.read(itineraryProvider), isEmpty);

      await fakeStorage.addItinerary(_itineraryMap('itin-server'));
      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.itineraries, 1));
      await flush();

      expect(container.read(itineraryProvider).map((i) => i.id),
          contains('itin-server'));
    });

    test('unsubscribed table event leaves other providers untouched',
        () async {
      await fakeStorage.setFavoriteIds(['keep']);
      expect(container.read(favoritesProvider), ['keep']);

      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.vehicles, 3));
      await flush();

      expect(container.read(favoritesProvider), ['keep']);
    });
  });
}

TripHistoryEntry _entry(String id) => TripHistoryEntry(
      id: id,
      vehicleId: null,
      summary: TripSummary(
        startedAt: DateTime(2026, 7, 1, 8),
        endedAt: DateTime(2026, 7, 1, 9),
        distanceKm: 10.0,
        maxRpm: 2500,
        highRpmSeconds: 3,
        idleSeconds: 20,
        harshBrakes: 0,
        harshAccelerations: 0,
      ),
    );

Map<String, dynamic> _itineraryMap(String id) => {
      'id': id,
      'name': 'server route', // i18n-ignore: test fixture data, not UI
      'waypoints': <Map<String, dynamic>>[],
      'distanceKm': 12.0,
      'durationMinutes': 20.0,
      'avoidHighways': false,
      'fuelType': 'e10',
      'selectedStationIds': <String>[],
      'createdAt': DateTime.utc(2026, 7, 1).toIso8601String(),
      'updatedAt': DateTime.utc(2026, 7, 1).toIso8601String(),
    };

/// In-memory [TripHistoryRepository] exposing just what
/// [TripHistoryList] touches ([loadAll]); everything else fails loudly.
class _FakeTripHistoryRepository implements TripHistoryRepository {
  final List<TripHistoryEntry> entries = [];

  @override
  List<TripHistoryEntry> loadAll({bool dedupe = true}) => List.of(entries);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
        '_FakeTripHistoryRepository.${invocation.memberName} '
        'was not expected to be called by TripHistoryList.build/refresh',
      );
}
