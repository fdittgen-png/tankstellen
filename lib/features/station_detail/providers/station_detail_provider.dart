import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/country/country_config.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/service_result.dart';
import '../../search/domain/entities/search_result_item.dart';
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
  //
  // #753 — match by id, but only when the search-state country matches
  // the id's origin country prefix (or there is no prefix, e.g. legacy
  // `demo-`). Without this guard a stale country-A search cache could
  // shadow a country-B widget tap with a colliding numeric id and open
  // the wrong station — the original bug.
  final searchState = ref.read(searchStateProvider);
  if (searchState.hasValue) {
    final searchResults = searchState.value?.data ?? [];
    final fromSearch = searchResults
        .whereType<FuelStationResult>()
        .where((r) => r.station.id == stationId)
        .firstOrNull;
    if (fromSearch != null) {
      return ServiceResult(
        data: StationDetail(station: fromSearch.station),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );
    }
  }

  // Fallback: fetch from the country whose id prefix the [stationId]
  // carries (#753) — not the active profile country. Widget rows live
  // forever in SharedPreferences, so the user can tap a row written
  // under a different country than is currently active and still land
  // on the right station. Falls back to the active profile country
  // when the id has no recognised prefix (legacy bare id, demo data).
  //
  // Mirrors the favorites-provider pattern: when the id's origin
  // country matches the active country we reuse the active provider
  // (so test overrides on `stationServiceProvider` still drive the
  // right instance), otherwise we resolve the cross-country service.
  // Only touches `activeCountryProvider` when the id carries a prefix —
  // unprefixed legacy ids skip the comparison entirely so existing
  // unit tests that overrode just `stationServiceProvider` keep
  // working without standing up Hive.
  final originCountry = Countries.countryCodeForStationId(stationId);
  if (originCountry == null) {
    return ref.watch(stationServiceProvider).getStationDetail(stationId);
  }
  final activeCountry = ref.watch(activeCountryProvider).code;
  final stationService = (originCountry == activeCountry)
      ? ref.watch(stationServiceProvider)
      : stationServiceForCountry(ref, originCountry);
  return stationService.getStationDetail(stationId);
}
