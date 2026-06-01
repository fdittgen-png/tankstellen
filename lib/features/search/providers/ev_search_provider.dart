// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/services/service_result.dart';
import '../../../core/country/country_provider.dart';
import '../../ev/data/services/ev_price_enricher.dart';
import '../../ev/data/services/fr_irve_price_service.dart';
import '../../ev/domain/entities/charging_station.dart';
import 'ev_charging_service_provider.dart';

part 'ev_search_provider.g.dart';

/// The EV price/access enricher applied after the OCM search returns
/// (#2618). Defaults to the France IRVE enricher, which is itself a
/// no-op for any result set with no FR stations — so non-FR searches
/// make zero extra network calls. Overridable in tests.
@Riverpod(keepAlive: true)
EvPriceEnricher evPriceEnricher(Ref ref) => FrIrvePriceService();

/// Manages EV charging station search, parallel to [SearchState] for fuel.
///
/// Uses `keepAlive` because SearchState dispatches to this notifier
/// asynchronously — without keepAlive, the auto-dispose fires mid-request
/// when nothing is watching, causing UnmountedRefException (#550).
@Riverpod(keepAlive: true)
class EVSearchState extends _$EVSearchState {
  @override
  AsyncValue<ServiceResult<List<ChargingStation>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.openChargeMapApi,
      fetchedAt: DateTime.now(),
    ));
  }

  Future<void> searchNearby({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(evChargingServiceProvider);
      if (service == null) {
        throw const NoEvApiKeyException();
      }

      final country = ref.read(activeCountryProvider);
      final result = await service.searchStations(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        countryCode: country.code,
      );

      // Layer onto the OCM result any country-authoritative price/access
      // signal (#2618). The enricher is a no-op for result sets with no
      // FR stations, so this is free outside France; it never throws,
      // degrading to the un-enriched result on any failure.
      final enricher = ref.read(evPriceEnricherProvider);
      final enriched = await enricher.enrich(result.data);
      state = AsyncValue.data(ServiceResult(
        data: enriched,
        source: result.source,
        fetchedAt: result.fetchedAt,
        isStale: result.isStale,
        errors: result.errors,
      ));
    } on DioException catch (e, st) {
      if (e.type == DioExceptionType.cancel) return;
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
