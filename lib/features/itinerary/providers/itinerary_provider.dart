import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_storage.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_provider.dart';
import '../domain/entities/saved_itinerary.dart';
import '../../route_search/domain/entities/route_info.dart';

part 'itinerary_provider.g.dart';

/// Manages saved itineraries with local-first strategy:
/// - Save locally first, then sync to DB
/// - Load from DB first, then overwrite with local (local wins)
/// - Sync only adds/changes, never deletes (except explicit user delete)
@Riverpod(keepAlive: true)
class ItineraryNotifier extends _$ItineraryNotifier {
  @override
  List<SavedItinerary> build() {
    // Start with local data immediately
    final storage = ref.read(hiveStorageProvider);
    final local = _fromStorage(storage);
    // Kick off async merge in background
    Future.microtask(() => _loadAndMerge());
    return local;
  }

  List<SavedItinerary> _fromStorage(HiveStorage storage) {
    try {
      return storage.getItineraries().map((r) {
        return SavedItinerary(
          id: r['id'] as String,
          name: r['name'] as String,
          waypoints: (r['waypoints'] as List).cast<Map<String, dynamic>>(),
          distanceKm: (r['distanceKm'] as num?)?.toDouble() ?? (r['distance_km'] as num?)?.toDouble() ?? 0,
          durationMinutes: (r['durationMinutes'] as num?)?.toDouble() ?? (r['duration_minutes'] as num?)?.toDouble() ?? 0,
          avoidHighways: r['avoidHighways'] as bool? ?? r['avoid_highways'] as bool? ?? false,
          fuelType: r['fuelType'] as String? ?? r['fuel_type'] as String? ?? 'e10',
          selectedStationIds: (r['selectedStationIds'] as List?)?.cast<String>() ??
              (r['selected_station_ids'] as List?)?.cast<String>() ?? [],
          createdAt: DateTime.tryParse(r['createdAt']?.toString() ?? r['created_at']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(r['updatedAt']?.toString() ?? r['updated_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('ItineraryNotifier._fromStorage FAILED: $e');
      return [];
    }
  }

  /// Load from DB first, then merge with local (local wins on conflict).
  Future<void> _loadAndMerge() async {
    final syncState = ref.read(syncStateProvider);
    if (!syncState.enabled) return;

    try {
      final serverItineraries = await SyncService.fetchItineraries();
      if (serverItineraries.isEmpty) return;

      final storage = ref.read(hiveStorageProvider);
      final localIds = state.map((i) => i.id).toSet();

      // Merge: add server-only items, local items win on conflict
      final merged = [...state];
      for (final serverItem in serverItineraries) {
        if (!localIds.contains(serverItem.id)) {
          merged.add(serverItem);
          // Also save to local storage
          await storage.addItinerary(_toMap(serverItem));
        }
      }

      // Sort by updatedAt descending
      merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = merged;

      // Upload local-only items to server (sync adds, never deletes)
      final serverIds = serverItineraries.map((i) => i.id).toSet();
      for (final localItem in state) {
        if (!serverIds.contains(localItem.id)) {
          await SyncService.saveItinerary(localItem);
        }
      }

      debugPrint('ItineraryNotifier: merged ${state.length} itineraries (${serverItineraries.length} from server)');
    } catch (e) {
      debugPrint('ItineraryNotifier._loadAndMerge FAILED: $e');
    }
  }

  /// Reload from server (pull-to-refresh).
  Future<void> loadFromServer() async => _loadAndMerge();

  /// Save a new itinerary — local first, then sync.
  Future<bool> saveRoute({
    required String name,
    required List<RouteWaypoint> waypoints,
    required double distanceKm,
    required double durationMinutes,
    required bool avoidHighways,
    required String fuelType,
    List<String> selectedStationIds = const [],
  }) async {
    final itinerary = SavedItinerary(
      id: const Uuid().v4(),
      name: name,
      waypoints: waypoints.map((w) => <String, dynamic>{
        'lat': w.lat,
        'lng': w.lng,
        'label': w.label,
      }).toList(),
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      avoidHighways: avoidHighways,
      fuelType: fuelType,
      selectedStationIds: selectedStationIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 1. Save locally first
    final storage = ref.read(hiveStorageProvider);
    await storage.addItinerary(_toMap(itinerary));
    state = [itinerary, ...state];

    // 2. Sync to server (non-blocking)
    try {
      await SyncService.saveItinerary(itinerary);
    } catch (e) {
      debugPrint('ItineraryNotifier.saveRoute sync FAILED: $e');
    }

    return true;
  }

  /// Delete an itinerary — local + server.
  Future<void> delete(String id) async {
    // 1. Delete locally
    final storage = ref.read(hiveStorageProvider);
    await storage.deleteItinerary(id);
    state = state.where((i) => i.id != id).toList();

    // 2. Delete from server
    try {
      await SyncService.deleteItinerary(id);
    } catch (e) {
      debugPrint('ItineraryNotifier.delete sync FAILED: $e');
    }
  }

  Map<String, dynamic> _toMap(SavedItinerary i) => {
    'id': i.id,
    'name': i.name,
    'waypoints': i.waypoints,
    'distanceKm': i.distanceKm,
    'durationMinutes': i.durationMinutes,
    'avoidHighways': i.avoidHighways,
    'fuelType': i.fuelType,
    'selectedStationIds': i.selectedStationIds,
    'createdAt': i.createdAt.toIso8601String(),
    'updatedAt': i.updatedAt.toIso8601String(),
  };
}
