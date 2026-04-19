@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/mise_station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// #695 — live reachability + end-to-end search test for the Italian
/// MISE provider. Guards against the bug the user reported ("search
/// for Italy returns no results") by hitting the real upstream and
/// asserting >0 stations for a known-busy location (Rome).
///
/// Run with `flutter test --tags network` on demand; skipped by the
/// default test runner (CI `flutter test` excludes tagged suites).
void main() {
  test(
    'MISE returns stations within 10km of Rome (Roma Centro)',
    () async {
      final service = MiseStationService();
      // Via del Corso, Roma (Piazza Venezia area)
      final result = await service.searchStations(
        const SearchParams(
          lat: 41.8967,
          lng: 12.4822,
          radiusKm: 10,
          fuelType: FuelType.e10,
        ),
      );
      expect(result.data, isNotEmpty,
          reason:
              'MISE upstream + parser + bbox filter must return >0 stations '
              'for central Rome. If this fails, either the CSV schema '
              'changed (parse error) or the bounding box / distance calc '
              'regressed.');
      // Pin a few structural invariants rather than exact count.
      expect(result.data.every((s) => s.lat > 40 && s.lat < 43), isTrue,
          reason: 'All stations within radius should have Italian lat');
      expect(result.data.every((s) => s.lng > 11 && s.lng < 14), isTrue,
          reason: 'All stations within radius should have Italian lng');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'MISE returns stations within 5km of Milan (Duomo)',
    () async {
      final service = MiseStationService();
      final result = await service.searchStations(
        const SearchParams(
          lat: 45.4642,
          lng: 9.1900,
          radiusKm: 5,
          fuelType: FuelType.diesel,
        ),
      );
      expect(result.data, isNotEmpty,
          reason: 'Milan must return >0 stations in a 5 km radius');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
