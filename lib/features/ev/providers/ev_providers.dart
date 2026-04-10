import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart' show ConnectorType;
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/repositories/ev_station_repository.dart';
import '../data/services/open_charge_map_service.dart';
import '../domain/entities/charging_station.dart';

part 'ev_providers.g.dart';

/// Repository for reading/writing cached [ChargingStation] entries.
@Riverpod(keepAlive: true)
EvStationRepository evStationRepository(Ref ref) {
  final storage = ref.watch(settingsStorageProvider);
  return EvStationRepository(storage);
}

/// Concrete [EvStationService] used by the app.
///
/// Plain `@riverpod` (not keepAlive) so a future settings change can swap
/// in a real API key without a restart.
@Riverpod(keepAlive: true)
EvStationService evStationService(Ref ref) {
  final storage = ref.watch(settingsStorageProvider);
  final rawKey = storage.getSetting(StorageKeys.evApiKey);
  final apiKey = rawKey is String && rawKey.trim().isNotEmpty ? rawKey : null;
  return OpenChargeMapService(apiKey: apiKey);
}

/// Whether EV charging stations should be overlaid on the map.
///
/// Persisted to the settings box so the user's preference survives
/// restarts. Defaults to `false` — existing fuel-station users shouldn't
/// suddenly see extra markers on upgrade.
@Riverpod(keepAlive: true)
class EvShowOnMap extends _$EvShowOnMap {
  @override
  bool build() {
    final storage = ref.watch(settingsStorageProvider);
    final raw = storage.getSetting(StorageKeys.evShowOnMap);
    return raw is bool ? raw : false;
  }

  Future<void> toggle() async {
    final storage = ref.read(settingsStorageProvider);
    final next = !state;
    await storage.putSetting(StorageKeys.evShowOnMap, next);
    state = next;
  }

  Future<void> set(bool value) async {
    final storage = ref.read(settingsStorageProvider);
    await storage.putSetting(StorageKeys.evShowOnMap, value);
    state = value;
  }
}

/// Filter criteria applied to [evStationsProvider] results before they
/// are rendered on the map or station list.
class EvFilter {
  final Set<ConnectorType> connectorTypes;
  final double minPowerKw;
  final bool availableOnly;

  const EvFilter({
    this.connectorTypes = const <ConnectorType>{},
    this.minPowerKw = 0,
    this.availableOnly = false,
  });

  EvFilter copyWith({
    Set<ConnectorType>? connectorTypes,
    double? minPowerKw,
    bool? availableOnly,
  }) {
    return EvFilter(
      connectorTypes: connectorTypes ?? this.connectorTypes,
      minPowerKw: minPowerKw ?? this.minPowerKw,
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }

  /// Whether [station] passes this filter.
  bool matches(ChargingStation station) {
    if (availableOnly && !station.hasAvailableConnector) return false;
    if (minPowerKw > 0 && station.maxPowerKw < minPowerKw) return false;
    if (connectorTypes.isNotEmpty) {
      final hasMatch = station.connectors.any(
        (c) => connectorTypes.contains(c.type),
      );
      if (!hasMatch) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is EvFilter &&
      other.connectorTypes.length == connectorTypes.length &&
      other.connectorTypes.containsAll(connectorTypes) &&
      other.minPowerKw == minPowerKw &&
      other.availableOnly == availableOnly;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(connectorTypes),
        minPowerKw,
        availableOnly,
      );
}

/// User-editable filter for EV stations.
///
/// Seeded from the active vehicle profile's `supportedConnectors` so a
/// driver with a CCS-only car doesn't see incompatible plugs by default.
@Riverpod(keepAlive: true)
class EvFilterController extends _$EvFilterController {
  @override
  EvFilter build() {
    final active = ref.watch(activeVehicleProfileProvider);
    final connectors = active?.supportedConnectors ?? const <ConnectorType>{};
    return EvFilter(connectorTypes: Set<ConnectorType>.from(connectors));
  }

  void setConnectorTypes(Set<ConnectorType> types) {
    state = state.copyWith(connectorTypes: Set<ConnectorType>.from(types));
  }

  void toggleConnector(ConnectorType type) {
    final next = Set<ConnectorType>.from(state.connectorTypes);
    if (next.contains(type)) {
      next.remove(type);
    } else {
      next.add(type);
    }
    state = state.copyWith(connectorTypes: next);
  }

  void setMinPowerKw(double value) {
    state = state.copyWith(minPowerKw: value);
  }

  void setAvailableOnly(bool value) {
    state = state.copyWith(availableOnly: value);
  }

  void reset() {
    state = const EvFilter();
  }
}

/// Parameters describing the map viewport for which to fetch EV stations.
class EvViewport {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const EvViewport({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 5,
  });

  @override
  bool operator ==(Object other) =>
      other is EvViewport &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radiusKm == radiusKm;

  @override
  int get hashCode => Object.hash(latitude, longitude, radiusKm);
}

/// Fetches charging stations for the given [viewport] and writes them
/// through the local repository cache. Applies the current
/// [evFilterControllerProvider] before returning.
@riverpod
Future<List<ChargingStation>> evStations(
  Ref ref,
  EvViewport viewport,
) async {
  final service = ref.watch(evStationServiceProvider);
  final repo = ref.watch(evStationRepositoryProvider);
  final filter = ref.watch(evFilterControllerProvider);

  List<ChargingStation> stations;
  try {
    stations = await service.fetchStations(
      centerLat: viewport.latitude,
      centerLng: viewport.longitude,
      radiusKm: viewport.radiusKm,
    );
    await repo.saveAll(stations);
  } catch (e) {
    // Fall back to whatever we have cached if the service fails.
    stations = repo.getAll();
  }

  return stations.where(filter.matches).toList();
}
