import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/storage_providers.dart';
import '../storage/storage_keys.dart';
import 'location_service.dart';

part 'user_position_provider.g.dart';

/// The user's known position, separate from the search center.
/// Persisted to Hive so it survives app restarts.
class UserPositionData {
  final double lat;
  final double lng;
  final DateTime updatedAt;
  final String source; // 'GPS' or location name

  const UserPositionData({
    required this.lat,
    required this.lng,
    required this.updatedAt,
    required this.source,
  });
}

@Riverpod(keepAlive: true)
class UserPosition extends _$UserPosition {
  @override
  UserPositionData? build() {
    // Load persisted position from storage
    final storage = ref.read(storageRepositoryProvider);
    final lat = storage.getSetting(StorageKeys.userPositionLat) as double?;
    final lng = storage.getSetting(StorageKeys.userPositionLng) as double?;
    final ts = storage.getSetting(StorageKeys.userPositionTimestamp) as int?;
    final source = storage.getSetting(StorageKeys.userPositionSource) as String?;

    if (lat != null && lng != null && ts != null) {
      return UserPositionData(
        lat: lat,
        lng: lng,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(ts),
        source: source ?? 'GPS',
      );
    }
    return null;
  }

  /// Update from GPS coordinates (e.g., after a GPS search).
  void setFromGps(double lat, double lng) {
    _persist(lat, lng, 'GPS');
  }

  /// Update from named location (e.g., reverse-geocoded address).
  void setWithSource(double lat, double lng, String source) {
    _persist(lat, lng, source);
  }

  /// Fetch fresh GPS position and update.
  Future<void> updateFromGps() async {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentPosition();
    setFromGps(position.latitude, position.longitude);
  }

  void clear() {
    final storage = ref.read(storageRepositoryProvider);
    storage.putSetting(StorageKeys.userPositionLat, null);
    storage.putSetting(StorageKeys.userPositionLng, null);
    storage.putSetting(StorageKeys.userPositionTimestamp, null);
    storage.putSetting(StorageKeys.userPositionSource, null);
    state = null;
  }

  void _persist(double lat, double lng, String source) {
    final now = DateTime.now();
    final storage = ref.read(storageRepositoryProvider);
    storage.putSetting(StorageKeys.userPositionLat, lat);
    storage.putSetting(StorageKeys.userPositionLng, lng);
    storage.putSetting(StorageKeys.userPositionTimestamp, now.millisecondsSinceEpoch);
    storage.putSetting(StorageKeys.userPositionSource, source);
    state = UserPositionData(lat: lat, lng: lng, updatedAt: now, source: source);
  }
}
