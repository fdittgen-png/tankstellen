import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/country/country_config.dart';
import '../../../core/data/storage_repository.dart';
import '../../../core/services/station_service.dart';
import '../../../core/storage/storage_keys.dart';
import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';

/// Storage boundary for the nearest-widget JSON payload.
///
/// The builder writes the current rendering payload (and reads back the
/// previous one on stale fallback). In production this is backed by the
/// `home_widget` plugin's SharedPreferences bridge; in tests it's a
/// plain in-memory map so unit tests don't need platform channels.
abstract class NearestWidgetPayloadStore {
  /// Read the `nearest_json` from the previous successful build, or null
  /// when no prior payload exists.
  Future<String?> readLastJson();

  /// Read the ISO-8601 timestamp of the previous successful build, or null.
  Future<DateTime?> readLastFetchedAt();

  /// Persist a fresh payload (successful OR empty). The widget always
  /// reads this; a stale flag + empty_reason tell the renderer what to
  /// show on top of the data.
  Future<void> writePayload({
    required int count,
    required String stationsJson,
    required String updatedAtIso,
    required String emptyReason,
    required bool isStale,
    double? userLat,
    double? userLng,
  });
}

/// Production [NearestWidgetPayloadStore] backed by the `home_widget`
/// plugin. Uses the same keys the `StationWidgetRenderer` on the Kotlin
/// side reads.
class HomeWidgetPayloadStore implements NearestWidgetPayloadStore {
  const HomeWidgetPayloadStore();

  @override
  Future<String?> readLastJson() async {
    try {
      final value = await HomeWidget.getWidgetData<String>('nearest_json');
      return (value != null && value.isNotEmpty && value != '[]') ? value : null;
    } catch (e, st) {
      debugPrint('HomeWidgetPayloadStore.readLastJson failed: $e\n$st');
      return null;
    }
  }

  @override
  Future<DateTime?> readLastFetchedAt() async {
    try {
      final iso =
          await HomeWidget.getWidgetData<String>('nearest_updated_at');
      return iso == null ? null : DateTime.tryParse(iso);
    } catch (e, st) {
      debugPrint('HomeWidgetPayloadStore.readLastFetchedAt failed: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> writePayload({
    required int count,
    required String stationsJson,
    required String updatedAtIso,
    required String emptyReason,
    required bool isStale,
    double? userLat,
    double? userLng,
  }) async {
    await HomeWidget.saveWidgetData('nearest_count', count);
    await HomeWidget.saveWidgetData('nearest_json', stationsJson);
    await HomeWidget.saveWidgetData('nearest_updated_at', updatedAtIso);
    await HomeWidget.saveWidgetData('nearest_empty_reason', emptyReason);
    await HomeWidget.saveWidgetData('nearest_is_stale', isStale);
    if (userLat != null) {
      await HomeWidget.saveWidgetData('nearest_lat', userLat);
    }
    if (userLng != null) {
      await HomeWidget.saveWidgetData('nearest_lng', userLng);
    }
  }
}

/// The JSON-ready result the builder returns in-process (also what it
/// writes through the [NearestWidgetPayloadStore]).
@immutable
class NearestWidgetPayload {
  final List<Map<String, dynamic>> stations;

  /// Populated only when [stations] is empty. One of: `no_gps`, `no_network`,
  /// or null on success.
  final String? emptyReason;

  /// True when the returned payload is a reuse of the previous successful
  /// render because the current fetch failed. Widget greys out rows.
  final bool isStale;

  final DateTime updatedAt;

  const NearestWidgetPayload({
    required this.stations,
    required this.updatedAt,
    this.emptyReason,
    this.isStale = false,
  });
}

/// Builds the JSON payload the "nearest" home screen widget renders.
///
/// Rewritten for #609: previously the list came from favorites sorted by
/// distance (empty for users with no favorites). Now it queries the active
/// country's [StationService] with the user's last-known GPS fix so the
/// widget reflects the real surroundings.
///
/// ## Failure modes
/// - No GPS known → empty payload + `empty_reason='no_gps'`
/// - Search fails, no prior payload → empty payload + `empty_reason='no_network'`
/// - Search fails, prior payload exists → reuse last payload + `isStale=true`
///
/// All three paths write to the same SharedPreferences keys the Kotlin
/// widget renderer reads; the empty_reason / isStale flags drive the UI.
class NearestWidgetDataBuilder {
  NearestWidgetDataBuilder({
    required this.stationService,
    required this.settingsStorage,
    required this.profileStorage,
    NearestWidgetPayloadStore? payloadStore,
  }) : payloadStore = payloadStore ?? const HomeWidgetPayloadStore();

  final StationService stationService;
  final SettingsStorage settingsStorage;
  final ProfileStorage profileStorage;
  final NearestWidgetPayloadStore payloadStore;

  /// Maximum rows the widget renders.
  static const int maxStations = 5;

  /// Build the payload and persist it via [payloadStore].
  Future<NearestWidgetPayload> build() async {
    final lat = (settingsStorage.getSetting(StorageKeys.userPositionLat)
            as num?)
        ?.toDouble();
    final lng = (settingsStorage.getSetting(StorageKeys.userPositionLng)
            as num?)
        ?.toDouble();

    if (lat == null || lng == null) {
      final payload = NearestWidgetPayload(
        stations: const [],
        updatedAt: DateTime.now(),
        emptyReason: 'no_gps',
      );
      await _persist(payload, userLat: null, userLng: null);
      return payload;
    }

    final profile = _activeProfile();
    final radiusKm = profile.radiusKm;
    final fuelType = profile.fuelType;

    try {
      final result = await stationService.searchStations(
        SearchParams(
          lat: lat,
          lng: lng,
          radiusKm: radiusKm,
          fuelType: fuelType,
          sortBy: SortBy.distance,
        ),
      );

      // Sort locally too — some country services honour sortBy at the
      // server side, others don't. Cheap enough to always do.
      final sorted = [...result.data]..sort((a, b) => a.dist.compareTo(b.dist));
      final top = sorted.take(maxStations).toList(growable: false);

      final rows = top
          .map((s) => _stationToRow(s, userLat: lat, userLng: lng, fuel: fuelType))
          .toList(growable: false);

      final payload = NearestWidgetPayload(
        stations: rows,
        updatedAt: DateTime.now(),
      );
      await _persist(payload, userLat: lat, userLng: lng);
      return payload;
    } catch (e, st) {
      debugPrint('NearestWidgetDataBuilder.build search failed: $e\n$st');
      // Attempt stale-fallback: reuse the previous successful payload.
      final previousJson = await payloadStore.readLastJson();
      if (previousJson != null) {
        try {
          final decoded = (jsonDecode(previousJson) as List)
              .cast<Map<String, dynamic>>();
          if (decoded.isNotEmpty) {
            final payload = NearestWidgetPayload(
              stations: decoded,
              updatedAt: await payloadStore.readLastFetchedAt() ??
                  DateTime.now(),
              isStale: true,
            );
            await _persist(payload, userLat: lat, userLng: lng);
            return payload;
          }
        } catch (decodeErr, st) { // ignore: unused_catch_stack
          debugPrint(
            'NearestWidgetDataBuilder: previous JSON decode failed: '
            '$decodeErr',
          );
        }
      }
      // No usable prior payload — surface the network failure.
      final payload = NearestWidgetPayload(
        stations: const [],
        updatedAt: DateTime.now(),
        emptyReason: 'no_network',
      );
      await _persist(payload, userLat: lat, userLng: lng);
      return payload;
    }
  }

  // --- private helpers ------------------------------------------------------

  _ProfileDefaults _activeProfile() {
    final id = profileStorage.getActiveProfileId();
    if (id == null) return const _ProfileDefaults();
    final raw = profileStorage.getProfile(id);
    if (raw == null) return const _ProfileDefaults();
    final radius =
        (raw['defaultSearchRadius'] as num?)?.toDouble() ?? 10.0;
    FuelType fuel = FuelType.e10;
    final key = raw['preferredFuelType']?.toString();
    if (key != null) {
      try {
        fuel = FuelType.fromString(key);
      } catch (e, st) { // ignore: unused_catch_stack
        debugPrint(
          'NearestWidgetDataBuilder: unknown preferred fuel "$key": $e',
        );
      }
    }
    return _ProfileDefaults(radiusKm: radius, fuelType: fuel);
  }

  Map<String, dynamic> _stationToRow(
    Station station, {
    required double userLat,
    required double userLng,
    required FuelType fuel,
  }) {
    final brand = station.brand.trim().isNotEmpty
        ? station.brand
        : (station.name.trim().isNotEmpty ? station.name : 'Station');

    final currency = Countries.countryForStation(
          id: station.id,
          lat: station.lat,
          lng: station.lng,
        )?.currencySymbol ??
        '';

    final price = _priceForFuel(station, fuel);
    final priceFormatted =
        price != null ? price.toStringAsFixed(3) : '';

    return <String, dynamic>{
      'id': station.id,
      'brand': brand,
      'name': station.name,
      'street': station.street,
      'postCode': station.postCode,
      'place': station.place,
      'distanceKm': double.parse(station.dist.toStringAsFixed(1)),
      'priceFormatted': priceFormatted,
      'currency': currency,
      'isOpen': station.isOpen,
      // Parity fields with the favorites widget so the Kotlin renderer
      // can switch modes without a second JSON shape.
      'preferred_fuel_code': fuel.apiValue,
      'preferred_fuel_price': price,
      'e5': station.e5,
      'e10': station.e10,
      'diesel': station.diesel,
    };
  }

  static double? _priceForFuel(Station s, FuelType fuel) {
    return switch (fuel) {
      FuelTypeE5() => s.e5,
      FuelTypeE10() => s.e10,
      FuelTypeE98() => s.e98,
      FuelTypeDiesel() => s.diesel,
      FuelTypeDieselPremium() => s.dieselPremium,
      FuelTypeE85() => s.e85,
      FuelTypeLpg() => s.lpg,
      FuelTypeCng() => s.cng,
      _ => s.e10 ?? s.e5 ?? s.diesel,
    };
  }

  Future<void> _persist(
    NearestWidgetPayload payload, {
    required double? userLat,
    required double? userLng,
  }) async {
    await payloadStore.writePayload(
      count: payload.stations.length,
      stationsJson: jsonEncode(payload.stations),
      updatedAtIso: payload.updatedAt.toIso8601String(),
      emptyReason: payload.emptyReason ?? '',
      isStale: payload.isStale,
      userLat: userLat,
      userLng: userLng,
    );
  }
}

/// Active-profile snapshot for one build pass.
class _ProfileDefaults {
  final double radiusKm;
  final FuelType fuelType;
  const _ProfileDefaults({
    this.radiusKm = 10.0,
    this.fuelType = FuelType.e10,
  });
}
