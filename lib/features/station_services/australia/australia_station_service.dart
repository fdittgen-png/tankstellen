import 'package:dio/dio.dart';

import '../../search/data/models/search_params.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/services/service_result.dart';
import '../../../core/services/station_service.dart';
import '../../../core/services/mixins/station_service_helpers.dart';

/// NSW FuelCheck — Australian fuel price service.
///
/// **Current status: unavailable.** The legacy endpoint the previous
/// implementation hit (`api.onegov.nsw.gov.au/FuelCheckApp/v2/fuel/prices`
/// with a placeholder `apikey: 'empty'` header) has been retired — the
/// namespace 404s today. The current NSW Government FuelCheck API is
/// published at `api.nsw.gov.au/Product/Index/22` and requires OAuth2
/// client credentials + a subscription key, which this app does not
/// carry and cannot ship to users without a dedicated onboarding flow.
///
/// Rather than pretend to work, [searchStations] now throws a descriptive
/// [ApiException] so the service chain surfaces the failure, the error
/// dialog shows a useful message, and the \"Report this issue\" button
/// introduced in #500 lets the user file a follow-up with the real
/// context instead of a 404 blob.
///
/// Tracking: #804 — restore real Australian fuel search, likely via a
/// dedicated NSW API key onboarding flow. (Issue #504 was the older
/// \"placeholder `apikey: 'empty'` header\" bug and is closed.)
class AustraliaStationService
    with StationServiceHelpers
    implements StationService {
  const AustraliaStationService();

  /// Exposed for tests so the assertion message stays in sync with
  /// the thrown exception.
  static const String unavailableMessage =
      'NSW FuelCheck is currently unavailable. The public '
      'FuelCheckApp/v2 endpoint has been retired and the replacement '
      'api.nsw.gov.au FuelCheck product requires OAuth2 client '
      'credentials. Tracked in #804.';

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    throw const ApiException(message: unavailableMessage);
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    throw const ApiException(
      message: 'Station detail not supported for Australia',
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) async {
    return ServiceResult(
      data: const {},
      source: ServiceSource.australiaApi,
      fetchedAt: DateTime.now(),
    );
  }
}
