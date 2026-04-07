import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_helper.dart';
import '../../../core/sync/sync_service.dart';

part 'ignored_stations_provider.g.dart';

/// Manages the user's list of ignored (hidden) station IDs.
///
/// Ignored stations are filtered out of search results, map markers,
/// and route results. This lets users hide irrelevant or closed stations.
///
/// ## Local-first pattern:
/// - Saves to Hive immediately, then syncs to Supabase.
/// - On conflict: local list wins (union merge on sync).
@Riverpod(keepAlive: true)
class IgnoredStations extends _$IgnoredStations {
  @override
  List<String> build() {
    final storage = ref.watch(storageRepositoryProvider);
    return storage.getIgnoredIds();
  }

  /// Hide a station from all search results and maps.
  Future<void> add(String stationId) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.addIgnored(stationId);
    state = storage.getIgnoredIds();

    await SyncHelper.syncIfEnabled(ref, 'IgnoredStations.add',
      () => SyncService.syncIgnoredStations(state),
    );
  }

  /// Un-hide a station — make it visible again in results.
  Future<void> remove(String stationId) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.removeIgnored(stationId);
    state = storage.getIgnoredIds();

    await SyncHelper.syncIfEnabled(ref, 'IgnoredStations.remove',
      () => SyncService.syncIgnoredStations(state),
    );
  }

  /// Toggle ignored status for a station.
  Future<void> toggle(String stationId) async {
    if (state.contains(stationId)) {
      await remove(stationId);
    } else {
      await add(stationId);
    }
  }
}

/// Whether a specific station is ignored. Rebuilds when ignored list changes.
@riverpod
bool isIgnored(Ref ref, String stationId) {
  final ignored = ref.watch(ignoredStationsProvider);
  return ignored.contains(stationId);
}
