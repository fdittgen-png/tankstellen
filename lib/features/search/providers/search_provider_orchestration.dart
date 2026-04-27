import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/location/user_position_provider.dart';
import '../../../core/services/geocoding_chain.dart';
import '../../../core/services/service_result.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/search_result_item.dart';
import '../../profile/providers/effective_fuel_type_provider.dart';
import '../../profile/providers/profile_provider.dart';
import 'ev_search_provider.dart';
import 'search_result_helpers.dart';

/// Orchestration helpers extracted from `search_provider.dart` (#563)
/// so the notifier file stays under the 250-LOC budget. These take
/// [Ref] explicitly so they remain pure functions of riverpod state
/// and can be reused by any notifier (or test) that needs the same
/// dispatch logic.

/// Auto-update user position from GPS if the active profile has
/// `autoUpdatePosition` enabled. Failures are logged but never
/// propagated — the search itself can still proceed without GPS.
Future<void> autoUpdatePositionIfEnabled(Ref ref) async {
  if (ref.read(activeProfileProvider)?.autoUpdatePosition != true) return;
  try {
    await ref.read(userPositionProvider.notifier).updateFromGps();
  } on Exception catch (e, st) {
    debugPrint('GPS auto-update failed: $e\n$st');
  }
}

/// Resolves the effective fuel + radius: honour explicit overrides,
/// otherwise fall back to the active profile's effective fuel (#704)
/// and default search radius (10 km).
({FuelType fuelType, double radiusKm}) resolveFuelAndRadius(
  Ref ref,
  FuelType? fuelType,
  double? radiusKm,
) {
  final profile = ref.read(activeProfileProvider);
  return (
    fuelType: fuelType ?? ref.read(effectiveFuelTypeProvider),
    radiusKm: radiusKm ?? profile?.defaultSearchRadius ?? 10.0,
  );
}

/// Triggers the EV search path when [fuelType] is electric. Returns
/// the wrapped EV [ServiceResult] (or `null` if EV state is still
/// loading) so the caller can write it into its own [AsyncValue]
/// state. Returns `null` when [fuelType] is not electric so callers
/// can short-circuit with `if (result == null) ... fuel path`.
///
/// Used by every search entry point ([searchByGps], [searchByZipCode],
/// [searchByCoordinates]) — keeps the EV-vs-fuel branch in one spot.
Future<AsyncValue<ServiceResult<List<SearchResultItem>>>?> dispatchEvIfNeeded({
  required Ref ref,
  required FuelType fuelType,
  required double lat,
  required double lng,
  required double radiusKm,
}) async {
  if (fuelType != FuelType.electric) return null;
  await ref
      .read(eVSearchStateProvider.notifier)
      .searchNearby(lat: lat, lng: lng, radiusKm: radiusKm);
  return ref.read(eVSearchStateProvider).when(
        data: (r) => AsyncValue.data(wrapEvResultAsSearchItems(r)),
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
}

/// Reverse-geocodes [lat], [lng] to a human-readable address. Returns
/// `null` on failure (network error, no result) — every caller treats
/// reverse geocoding as a non-fatal optional step. Errors are logged
/// via [debugPrint] with full stack trace context.
///
/// Both [searchByGps] (postal-code extraction) and [searchByZipCode]
/// (city-label lookup) share this pattern.
Future<String?> tryReverseGeocode(
  GeocodingChain geocoding,
  double lat,
  double lng, {
  CancelToken? cancelToken,
}) async {
  try {
    final addrResult = await geocoding.coordinatesToAddress(
      lat, lng, cancelToken: cancelToken,
    );
    return addrResult.data;
  } on Exception catch (e, st) {
    debugPrint('Reverse geocoding failed: $e\n$st');
    return null;
  }
}

/// Maps an exception thrown inside a search closure to an
/// [AsyncValue.error]. Returns `null` for cancellations so callers can
/// silently drop them.
///
/// Recognised classes:
/// - [DioException] with type `cancel` → null (silently dropped)
/// - any other [DioException] → wrapped as error
/// - [ServiceChainExhaustedException] → wrapped as error
/// - everything else → wrapped as error
AsyncValue<ServiceResult<List<SearchResultItem>>>? classifySearchError(
  Object error,
  StackTrace stackTrace,
) {
  if (error is DioException) {
    if (error.type == DioExceptionType.cancel) return null;
    return AsyncValue.error(error, stackTrace);
  }
  if (error is ServiceChainExhaustedException) {
    return AsyncValue.error(error, stackTrace);
  }
  return AsyncValue.error(error, stackTrace);
}
