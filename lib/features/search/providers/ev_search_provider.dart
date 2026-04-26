import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/services/service_result.dart';
import '../../../core/country/country_provider.dart';
import '../../ev/domain/entities/charging_station.dart';
import 'ev_charging_service_provider.dart';

part 'ev_search_provider.g.dart';

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
      state = AsyncValue.data(result);
    } on DioException catch (e, st) {
      if (e.type == DioExceptionType.cancel) return;
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
