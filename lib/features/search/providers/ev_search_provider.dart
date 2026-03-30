import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/services/service_result.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/country/country_provider.dart';
import '../data/services/ev_charging_service.dart';
import '../domain/entities/charging_station.dart';

part 'ev_search_provider.g.dart';

/// Manages EV charging station search, parallel to [SearchState] for fuel.
@riverpod
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
      final storage = ref.read(hiveStorageProvider);
      final apiKey = storage.getEvApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw const ApiException(
          message: 'OpenChargeMap API key not configured. '
              'Set it up in Settings to search for EV charging stations.',
        );
      }

      final country = ref.read(activeCountryProvider);
      final service = EVChargingService(apiKey: apiKey);
      final result = await service.searchStations(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        countryCode: country.code,
      );
      state = AsyncValue.data(result);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
