import '../../../core/location/user_position_provider.dart';
import '../../../core/services/service_result.dart';
import '../../../core/utils/geo_utils.dart';
import '../../ev/domain/entities/charging_station.dart';
import '../domain/entities/search_result_item.dart';
import '../domain/entities/station.dart';

/// Pure helpers that convert country-service results into the unified
/// [SearchResultItem] feed consumed by the UI.
///
/// Extracted from `search_provider.dart` (#563) so the helpers can be
/// unit-tested in isolation and so the notifier file stays focused on
/// orchestration (cancel tokens, profile lookups, error states).

/// Recalculates [Station.dist] for every station against a known
/// [userPos]. When [userPos] is null the list is returned unchanged so
/// the caller can skip the allocation path in the common "no saved
/// position yet" case.
///
/// Distances are rounded to one decimal to match the formatting used
/// everywhere else in the UI (`"1.2 km"`).
List<Station> recalcDistancesFrom(
  List<Station> stations,
  UserPositionData? userPos,
) {
  if (userPos == null) return stations;
  return stations.map((s) {
    final d = distanceKm(userPos.lat, userPos.lng, s.lat, s.lng);
    return s.copyWith(dist: double.parse(d.toStringAsFixed(1)));
  }).toList();
}

/// Wraps a fuel [ServiceResult<List<Station>>] as a
/// [ServiceResult<List<SearchResultItem>>] so the UI can render both
/// fuel and EV results through the same sealed type.
///
/// Preserves source, fetchedAt, isStale and accumulated errors so the
/// freshness banner and fallback summary stay accurate.
ServiceResult<List<SearchResultItem>> wrapFuelResultAsSearchItems(
  ServiceResult<List<Station>> result,
) {
  return ServiceResult(
    data:
        result.data.map((s) => FuelStationResult(s) as SearchResultItem).toList(),
    source: result.source,
    fetchedAt: result.fetchedAt,
    isStale: result.isStale,
    errors: result.errors,
  );
}

/// Wraps an EV [ServiceResult<List<ChargingStation>>] as a
/// [ServiceResult<List<SearchResultItem>>]. Mirrors
/// [wrapFuelResultAsSearchItems] so EV dispatch can share the same
/// downstream renderer path.
ServiceResult<List<SearchResultItem>> wrapEvResultAsSearchItems(
  ServiceResult<List<ChargingStation>> result,
) {
  return ServiceResult(
    data: result.data
        .map((cs) => EVStationResult(cs) as SearchResultItem)
        .toList(),
    source: result.source,
    fetchedAt: result.fetchedAt,
    isStale: result.isStale,
    errors: result.errors,
  );
}

/// Returns a copy of [result] with [stations] replacing `result.data`.
/// Used after distance recalculation where only the station list
/// changes — every other `ServiceResult` field (source, fetchedAt,
/// isStale, errors) must survive untouched.
ServiceResult<List<Station>> withStations(
  ServiceResult<List<Station>> result,
  List<Station> stations,
) {
  return ServiceResult(
    data: stations,
    source: result.source,
    fetchedAt: result.fetchedAt,
    isStale: result.isStale,
    errors: result.errors,
  );
}

/// Extracts a 4- or 5-digit postal code from a reverse-geocoded
/// address string (e.g. `"34120 Pézenas"` → `"34120"`).
///
/// Returns `null` when no plausible postal code is found — callers
/// should treat a missing postal code as a non-fatal signal (some
/// country APIs work without it, others will just skip the extra
/// filter).
String? extractPostalCode(String address) {
  final parts = address.split(' ');
  final re = RegExp(r'^\d{4,5}$');
  for (final part in parts) {
    if (re.hasMatch(part)) return part;
  }
  return null;
}

/// Merges a geocoding [ServiceResult] into a fuel [ServiceResult] so
/// geocoding errors/staleness surface in the unified banner alongside
/// station-service errors.
///
/// Used by [searchByZipCode] where the chain is
/// "geocode zip → search stations" and the user should see both kinds
/// of failure at once.
ServiceResult<List<Station>> mergeGeocodingIntoStationResult({
  required ServiceResult<List<Station>> stationResult,
  required List<ServiceError> geocodingErrors,
  required bool geocodingIsStale,
  required List<Station> adjustedStations,
}) {
  return ServiceResult(
    data: adjustedStations,
    source: stationResult.source,
    fetchedAt: stationResult.fetchedAt,
    isStale: stationResult.isStale || geocodingIsStale,
    errors: [
      ...geocodingErrors,
      ...stationResult.errors,
    ],
  );
}
