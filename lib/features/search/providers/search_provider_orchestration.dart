// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/location/user_position_provider.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/services/geocoding_chain.dart';
import '../../../core/services/service_result.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/search_result_item.dart';
import '../domain/entities/station.dart';
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
    // #2146 — route to the user-exportable log; the search continues
    // without GPS so the user still gets results.
    unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
      'where': 'search_provider: autoUpdatePositionIfEnabled',
    }));
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

/// True when [fuelType] denotes an EV charging search (#1866).
///
/// EV charging stations may only appear in the result feed when the
/// user explicitly searched for them — `FuelType.electric` is that
/// signal. Every other fuel type — including the `all` wildcard, which
/// means "all *fuels*" — is a fuel search and must not merge EV
/// results in. `SearchNotifier` gates [beginEvSearch] on this so a
/// fuel search returns fuel stations only, and vice versa.
bool isEvSearch(FuelType fuelType) => fuelType == FuelType.electric;

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
    // #2146 — non-fatal, but route so silent failures surface in
    // the exportable log for bug-report triage.
    // #3145 — coords are bucketed to 1 decimal (~11 km): enough for
    // triage, no longer a precise user location in the exportable log.
    unawaited(errorLogger.log(ErrorLayer.services, e, st, context: {
      'where': 'search_provider: tryReverseGeocode',
      'lat': lat.toStringAsFixed(1),
      'lng': lng.toStringAsFixed(1),
    }));
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

/// Kicks off the EV charging search for [lat]/[lng]/[radiusKm] without
/// awaiting it, so it runs concurrently with the fuel fetch (#1781).
///
/// The returned future completes once [EVSearchState.searchNearby] has
/// written its state. `searchNearby` captures its own exceptions into
/// `AsyncValue.error` (including the keyless `NoEvApiKeyException`), so
/// this future never throws — the outcome is read back from
/// [eVSearchStateProvider] by [finalizeUnifiedResult].
Future<void> beginEvSearch(
  Ref ref, {
  required double lat,
  required double lng,
  required double radiusKm,
}) {
  return ref
      .read(eVSearchStateProvider.notifier)
      .searchNearby(lat: lat, lng: lng, radiusKm: radiusKm);
}

/// Builds the final [SearchResultItem] feed so it always matches the
/// search intent (#1866): a search is either a fuel search or an EV
/// search, never both, so the two kinds are never mixed in one feed.
///
///   * [evFuture] is `null` — a fuel search. [fuelResult] is wrapped on
///     its own; no EV rows.
///   * [evFuture] is non-null — an EV search. It is awaited and the EV
///     outcome is returned alone; the [fuelResult] the caller still
///     fetched is discarded so no fuel row leaks into an EV feed. An
///     EV-side error becomes an empty result carrying that error so the
///     freshness banner can still report the OpenChargeMap outage.
Future<AsyncValue<ServiceResult<List<SearchResultItem>>>>
    finalizeUnifiedResult(
  Ref ref,
  ServiceResult<List<Station>> fuelResult,
  Future<void>? evFuture,
) async {
  if (evFuture == null) {
    return AsyncValue.data(wrapFuelResultAsSearchItems(fuelResult));
  }
  await evFuture;
  return AsyncValue.data(
    ref.read(eVSearchStateProvider).when(
          data: wrapEvResultAsSearchItems,
          loading: _emptyEvSearchResult,
          error: (e, _) => _emptyEvSearchResult(evError: e),
        ),
  );
}

/// An empty EV [SearchResultItem] feed, optionally carrying [evError]
/// so an EV search that failed still surfaces the OpenChargeMap outage
/// in the freshness / fallback banner (#1866).
ServiceResult<List<SearchResultItem>> _emptyEvSearchResult({Object? evError}) =>
    ServiceResult<List<SearchResultItem>>(
      data: const [],
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime.now(),
      errors: evError == null
          ? const []
          : [
              ServiceError(
                source: ServiceSource.openChargeMapApi,
                message: evError.toString(),
                occurredAt: DateTime.now(),
              ),
            ],
    );
