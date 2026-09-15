// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart';

/// #4189 — the seam between what an adapter STORES and what the
/// freshness gate PARSES.
///
/// Every existing test of that gate builds a `RefuelCandidate` with a
/// `DataValue<Duration>` by hand, so it is exercised with a `Measured`
/// age no adapter can actually produce. Each half passes on its own and
/// the join is broken — the shape #2776 warned about.
///
/// These cross it: a real Prix-Carburants record in, the value the app
/// would really store out, and the parse the gate would really do.
void main() {
  /// The real FR record shape, with the stamp the feed really carries.
  Map<String, dynamic> frRecord(String maj) => {
        'id': '12345',
        'gazole_prix': '1.719',
        'gazole_maj': maj,
      };

  group('what the FR adapter stores', () {
    test('is a display string, not a timestamp', () {
      final stored =
          parsePrixCarburantsMostRecentUpdate(frRecord('2026-03-23T00:01:00+00:00'));

      expect(stored, '23/03 00:01',
          reason: 'the adapter formats at the parse boundary — this is '
              'the value that reaches Station.updatedAt');
    });

    test('and DateTime.tryParse cannot read it back', () {
      final stored =
          parsePrixCarburantsMostRecentUpdate(frRecord('2026-03-23T00:01:00+00:00'))!;

      expect(DateTime.tryParse(stored), isNull,
          reason: 'this single fact is why the price-freshness gate has '
              'never fired in France: the machine-readable value was '
              'thrown away and a label kept in its place');
    });
  });

  group('what the capability promises', () {
    test('France declares that it stamps prices', () {
      final fr = CountryServiceRegistry.capabilityFor('FR');
      expect(fr, isNotNull);
      expect(fr!.priceTimestamp, isTrue);
    });

    test('so a null age reads as "the provider left THIS row blank"', () {
      // Which is a block, not a stand-down — and it is not what
      // happened. The provider published a stamp.
      final fr = CountryServiceRegistry.capabilityFor('FR')!;
      expect(
          fr.priceAge(null),
          const DataValue<Duration>.unknown(
              reason: DataUnknownReason.notPublishedForThisItem));
    });
  });

  group('the seam, end to end', () {
    test('a price stamped ten minutes ago produces a MEASURED age', () {
      // #4189's acceptance criterion, and the assertion that was RED
      // when the issue was filed: a fresh French price must be datable.
      final now = DateTime.utc(2026, 3, 23, 0, 11);
      final stored = parsePrixCarburantsMostRecentUpdate(
          frRecord('2026-03-23T00:01:00Z'));

      final record = frRecord('2026-03-23T00:01:00Z');
      final station = Station(
        id: 'fr-12345',
        name: 'Station',
        brand: 'Total',
        street: 'Rue',
        postCode: '75001',
        place: 'Paris',
        lat: 48.86,
        lng: 2.35,
        diesel: 1.719,
        updatedAt: stored,
        priceUpdatedAt: parsePrixCarburantsUpdatedAt(record),
      );

      expect(station.updatedAt, '23/03 00:01',
          reason: 'the displayed string is byte-identical to before');

      final age = station.priceUpdatedAt == null
          ? null
          : now.difference(station.priceUpdatedAt!);
      expect(age, const Duration(minutes: 10),
          reason: 'the feed said 00:01, it is now 00:11. Until #4189 this '
              'was null, so the confident pick was withheld for every '
              'station in France, Denmark and Portugal');

      final fr = CountryServiceRegistry.capabilityFor('FR')!;
      expect(fr.priceAge(age), isA<Measured<Duration>>());
    });

    test('a country that publishes no stamps is unaffected', () {
      // The gate must start working, not stop existing. Germany stamps
      // nothing, so its unknown still stands the gate down with a
      // caveat rather than blocking.
      final de = CountryServiceRegistry.capabilityFor('DE')!;
      expect(de.priceTimestamp, isFalse);
      expect(
          de.priceAge(null),
          const DataValue<Duration>.unknown(
              reason: DataUnknownReason.notPublishedByProvider));
    });
  });
}
