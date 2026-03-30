import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../search/domain/entities/station.dart';
import '../../search/providers/search_provider.dart';

part 'station_detail_provider.g.dart';

@riverpod
Future<ServiceResult<StationDetail>> stationDetail(
  Ref ref,
  String stationId,
) async {
  // First: check if the station is in the current search results
  // (which have OSM brand enrichment). This avoids a re-fetch and
  // preserves the brand name.
  final searchState = ref.read(searchStateProvider);
  if (searchState.hasValue) {
    final searchResults = searchState.value?.data ?? [];
    final fromSearch = searchResults
        .where((s) => s.id == stationId)
        .firstOrNull;
    if (fromSearch != null) {
      return ServiceResult(
        data: StationDetail(station: fromSearch),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );
    }
  }

  // Fallback: fetch from API (won't have OSM brand)
  final stationService = ref.watch(stationServiceProvider);
  return stationService.getStationDetail(stationId);
}
