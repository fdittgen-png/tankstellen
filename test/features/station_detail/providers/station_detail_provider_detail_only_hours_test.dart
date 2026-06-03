// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2778 (Epic #2776 D2) — DE (Tankerkönig) and PT (DGEG) carry opening hours
// ONLY on the detail endpoint; their SEARCH payload has none, so a cached
// search station has openingHours==null. The station-detail fast path must
// fall through to getStationDetail for these countries to surface hours,
// instead of serving the hours-less cached station synchronously (the bug:
// the section rendered empty). Every other provider is served from cache with
// no extra fetch. RED on master (fast path returned cached null hours), GREEN
// after.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

import '../../../mocks/mocks.dart';

class _FixedActiveCountry extends ActiveCountry {
  final CountryConfig _country;
  _FixedActiveCountry(this._country);
  @override
  CountryConfig build() => _country;
}

class _FakeSearchState extends SearchState {
  final List<SearchResultItem> items;
  _FakeSearchState(this.items);
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: items,
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );
}

void main() {
  late MockStationService mockStationService;

  setUp(() => mockStationService = MockStationService());

  // A cached search station with NO structured hours — exactly what DE/PT
  // search parses produce (hours live only on the detail endpoint).
  Station hoursLess(String id) => Station(
        id: id,
        name: 'Test',
        brand: 'Test',
        street: 'Str.',
        postCode: '00000',
        place: 'Town',
        lat: 50.0,
        lng: 10.0,
        isOpen: true,
        // openingHours intentionally null.
      );

  ProviderContainer containerFor(CountryConfig country, Station cached) {
    final c = ProviderContainer(overrides: [
      stationServiceProvider.overrideWithValue(mockStationService),
      searchStateProvider
          .overrideWith(() => _FakeSearchState([FuelStationResult(cached)])),
      activeCountryProvider.overrideWith(() => _FixedActiveCountry(country)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  StationDetail detailWithHours(Station s) => StationDetail(
        station: s,
        openingHours: WeeklyOpeningHours.allWeek24h(),
      );

  group('detail-only opening hours fast-path fall-through (#2778)', () {
    test('DE: cached search station with no hours → fetches getStationDetail',
        () async {
      final cached = hoursLess('de-123');
      when(() => mockStationService.getStationDetail('de-123')).thenAnswer(
        (_) async => ServiceResult(
          data: detailWithHours(cached),
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        ),
      );

      final result = await containerFor(Countries.germany, cached)
          .read(stationDetailProvider('de-123').future);

      expect(result.data.openingHours, isNotNull,
          reason: 'DE detail endpoint hours must reach the screen');
      expect(result.data.openingHours!.availability,
          isNot(OpeningHoursAvailability.notProvided));
      verify(() => mockStationService.getStationDetail('de-123')).called(1);
    });

    test('PT: cached search station with no hours → fetches getStationDetail',
        () async {
      final cached = hoursLess('pt-456');
      when(() => mockStationService.getStationDetail('pt-456')).thenAnswer(
        (_) async => ServiceResult(
          data: detailWithHours(cached),
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime.now(),
        ),
      );

      final result = await containerFor(Countries.portugal, cached)
          .read(stationDetailProvider('pt-456').future);

      expect(result.data.openingHours, isNotNull);
      verify(() => mockStationService.getStationDetail('pt-456')).called(1);
    });

    test('DE: detail fetch failure keeps the instant cached result (no regress)',
        () async {
      final cached = hoursLess('de-789');
      when(() => mockStationService.getStationDetail('de-789'))
          .thenThrow(Exception('detail endpoint down'));

      final result = await containerFor(Countries.germany, cached)
          .read(stationDetailProvider('de-789').future);

      // Falls back to the cached station rather than failing the screen.
      expect(result.data.station.id, 'de-789');
      expect(result.source, ServiceSource.cache);
    });

    test('non-detail-only country (AT): served from cache, NO extra fetch',
        () async {
      final cached = hoursLess('at-111');
      final result = await containerFor(Countries.austria, cached)
          .read(stationDetailProvider('at-111').future);

      expect(result.source, ServiceSource.cache);
      verifyNever(() => mockStationService.getStationDetail(any()));
    });
  });
}
