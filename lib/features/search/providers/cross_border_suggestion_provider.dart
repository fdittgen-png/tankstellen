import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/country/border_proximity.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/location/user_position_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/station_service.dart';
import '../../../core/utils/station_extensions.dart';
import '../data/models/search_params.dart';
import '../domain/entities/cross_border_suggestion.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/station.dart';
import 'search_provider.dart';

part 'cross_border_suggestion_provider.g.dart';

/// Distance threshold (km) below which a neighbor country is considered
/// close enough to fire a cross-border price probe.
///
/// Issue #1118: 25 km — far enough to catch a Saarbrücken / Strasbourg /
/// Innsbruck commuter, narrow enough that a Berlin user doesn't see
/// noise about a Polish border 70 km away.
const double crossBorderThresholdKm = 25.0;

/// Function signature for a station-service factory keyed by country
/// code. Indirection layer that exists so tests can inject a fake
/// `StationService` per neighbor without having to override the global
/// service-resolution machinery (cache manager, country registry,
/// API-key storage, ...).
typedef CrossBorderStationServiceFactory = StationService Function(
  String countryCode,
);

/// Injectable factory for resolving the neighbor country's station service.
///
/// Production path delegates to `stationServiceForCountry`, which goes
/// through `CountryServiceRegistry` + `StationServiceChain` so the call
/// is fully cached and request-coalesced (see #1118 acceptance: "coalesce
/// duplicate API calls — already supported by chain").
///
/// Tests override this with a closure returning a small in-memory fake.
@riverpod
CrossBorderStationServiceFactory crossBorderStationServiceFactory(Ref ref) {
  return (code) => stationServiceForCountry(ref, code);
}

/// Async suggestion of "the neighbor country has cheaper fuel right now".
///
/// Returns `null` when:
///  * the user's position is unknown,
///  * the user is not within [crossBorderThresholdKm] of any neighbor,
///  * the active fuel type is not supported by the neighbor (we don't
///    propose an EV-only neighbor for a diesel user, and vice versa),
///  * the neighbor's station service returns no usable prices,
///  * the current-country average is empty (we'd have nothing to compare
///    against),
///  * the neighbor is not actually cheaper (delta <= 0).
///
/// When non-null, the result encodes a positive `priceDeltaPerLiter` —
/// callers (the banner) can render it directly without re-checking the
/// sign.
@riverpod
Future<CrossBorderSuggestion?> crossBorderSuggestion(Ref ref) async {
  final position = ref.watch(userPositionProvider);
  if (position == null) return null;

  final activeCountry = ref.watch(activeCountryProvider);
  final fuelType = ref.watch(selectedFuelTypeProvider);

  // Need a current-country average to compare against.
  final localStations = ref.watch(fuelStationsProvider);
  if (localStations.isEmpty) return null;

  final localPrices = localStations
      .map((s) => s.priceFor(fuelType))
      .whereType<double>()
      .where((p) => p > 0)
      .toList();
  if (localPrices.isEmpty) return null;
  final localAvg = localPrices.reduce((a, b) => a + b) / localPrices.length;

  // Detect nearby borders within the issue's 25 km radius.
  final nearbyBorders = detectNearbyBorders(
    lat: position.lat,
    lng: position.lng,
    currentCountryCode: activeCountry.code,
    thresholdKm: crossBorderThresholdKm,
  );
  if (nearbyBorders.isEmpty) return null;

  final factory = ref.watch(crossBorderStationServiceFactoryProvider);

  // Probe each neighbor in order (closest first). Pick the first one
  // that is actually cheaper. We don't probe in parallel here — each
  // call is cached + coalesced by `StationServiceChain`, so a second
  // pump of the provider is essentially free.
  for (final border in nearbyBorders) {
    final neighbor = border.neighbor;

    // Don't propose a different fuel family — a diesel user shouldn't
    // see "France has cheaper electric" when their car runs on diesel.
    if (fuelType != FuelType.all &&
        !neighbor.supportedFuelTypes.contains(fuelType)) {
      continue;
    }
    // EV pricing model is per-kWh and not directly comparable to €/L,
    // so the cross-border banner sticks to fuel for now.
    if (fuelType == FuelType.electric) continue;

    final neighborStations = await _safeNeighborSearch(
      factory: factory,
      countryCode: neighbor.code,
      lat: position.lat,
      lng: position.lng,
      fuelType: fuelType,
    );
    if (neighborStations.isEmpty) continue;

    final neighborPrices = neighborStations
        .map((s) => s.priceFor(fuelType))
        .whereType<double>()
        .where((p) => p > 0)
        .toList();
    if (neighborPrices.isEmpty) continue;
    final neighborAvg =
        neighborPrices.reduce((a, b) => a + b) / neighborPrices.length;

    final delta = localAvg - neighborAvg;
    if (delta <= 0) continue; // not actually cheaper — skip

    return CrossBorderSuggestion(
      neighborCountryCode: neighbor.code,
      neighborName: neighbor.name,
      neighborFlag: neighbor.flag,
      distanceKm: double.parse(border.distanceKm.toStringAsFixed(1)),
      priceDeltaPerLiter: double.parse(delta.toStringAsFixed(3)),
      sampleCount: neighborPrices.length,
    );
  }

  return null;
}

/// Catches every error the neighbor service may throw (network, exhausted
/// fallback chain, missing API key, ...) so a single bad upstream never
/// breaks the whole search screen — the banner just stays hidden.
Future<List<Station>> _safeNeighborSearch({
  required CrossBorderStationServiceFactory factory,
  required String countryCode,
  required double lat,
  required double lng,
  required FuelType fuelType,
}) async {
  try {
    final service = factory(countryCode);
    final result = await service.searchStations(
      SearchParams(
        lat: lat,
        lng: lng,
        radiusKm: crossBorderThresholdKm,
        fuelType: fuelType,
      ),
    );
    return result.data;
  } catch (e, st) {
    debugPrint('cross-border probe ($countryCode) failed: $e\n$st');
    return const [];
  }
}

/// Set of neighbor country codes the user has dismissed during this
/// session. Resets on app restart (StateNotifier with no persistence).
@Riverpod(keepAlive: true)
class CrossBorderBannerDismissed extends _$CrossBorderBannerDismissed {
  @override
  Set<String> build() => <String>{};

  /// Marks [neighborCode] dismissed for this session — the banner stops
  /// showing for that neighbor until app restart.
  void dismiss(String neighborCode) {
    if (state.contains(neighborCode)) return;
    state = {...state, neighborCode};
  }
}
