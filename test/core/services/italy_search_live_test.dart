// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

@Tags(['network'])
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_services/italy/mise_station_service.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

import '../../helpers/network_retry.dart';

/// #695 — live end-to-end search against the Italian MISE provider.
/// Hits `mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv`
/// + the price CSV, asserts >0 stations for Rome and Milan.
///
/// Rerun after touching `mise_station_service.dart`, `mise_csv_parser.dart`,
/// or the Italian bounding box — also when a user reports "Italy returns
/// no results". CI excludes the tag; see `docs/guides/NETWORK_TESTS.md`.
void main() {
  test(
    'MISE returns stations within 10km of Rome (Roma Centro)',
    () async {
      final dio = retryingDio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 45),
          responseType: ResponseType.plain,
        ),
        maxRetries: 0,
      );
      addTearDown(() => dio.close(force: true));
      final service = MiseStationService(dio: dio);
      // Via del Corso, Roma (Piazza Venezia area). #3096 — retry the live
      // upstream fetch so a transient MIMIT timeout self-heals.
      final result = await withNetworkDeadline(
        (token) => retryNetwork(
          () => service.searchStations(
            const SearchParams(
              lat: 41.8967,
              lng: 12.4822,
              radiusKm: 10,
              fuelType: FuelType.e10,
            ),
            cancelToken: token,
          ),
          cancelToken: token,
        ),
        timeout: const Duration(seconds: 55),
      );
      expect(
        result.data,
        isNotEmpty,
        reason:
            'MISE upstream + parser + bbox filter must return >0 stations '
            'for central Rome. If this fails, either the CSV schema '
            'changed (parse error) or the bounding box / distance calc '
            'regressed.',
      );
      // Pin a few structural invariants rather than exact count.
      expect(
        result.data.every((s) => s.lat > 40 && s.lat < 43),
        isTrue,
        reason: 'All stations within radius should have Italian lat',
      );
      expect(
        result.data.every((s) => s.lng > 11 && s.lng < 14),
        isTrue,
        reason: 'All stations within radius should have Italian lng',
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'MISE returns stations within 5km of Milan (Duomo)',
    () async {
      final dio = retryingDio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 45),
          responseType: ResponseType.plain,
        ),
        maxRetries: 0,
      );
      addTearDown(() => dio.close(force: true));
      final service = MiseStationService(dio: dio);
      final result = await withNetworkDeadline(
        (token) => retryNetwork(
          () => service.searchStations(
            const SearchParams(
              lat: 45.4642,
              lng: 9.1900,
              radiusKm: 5,
              fuelType: FuelType.diesel,
            ),
            cancelToken: token,
          ),
          cancelToken: token,
        ),
        timeout: const Duration(seconds: 55),
      );
      expect(
        result.data,
        isNotEmpty,
        reason: 'Milan must return >0 stations in a 5 km radius',
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
