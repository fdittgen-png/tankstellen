// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/field_names.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/station_prices.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/features/alerts/background/background_price_shape.dart';
import 'package:tankstellen/features/alerts/background/scan_opportunity_capture.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_scorer.dart';

/// #4186 — the provider's price stamp reaches the background scan.
///
/// The background twin of #4189: there, a timestamp was formatted for
/// display and the instant thrown away; here, the flattened price map
/// had nowhere to put one at all, so `priceAgeForScannedRow` reported
/// "the provider left this row blank" for eight providers that had in
/// fact published one.
///
/// The consequence was not cosmetic. `OpportunityScorer` refuses a
/// `stalePrice` only on a **Measured** age, so with no age it could
/// never refuse one — a background alert about a day-old price had no
/// way of being caught.
void main() {
  final now = DateTime.utc(2026, 9, 15, 12);
  final fr = CountryServiceRegistry.capabilityFor('FR')!;
  final de = CountryServiceRegistry.capabilityFor('DE')!;

  group('the stamp survives the flattening', () {
    test('from a polled StationPrices', () {
      final shape = stationPricesToTankerkoenigShape(StationPrices(
        e10: 1.719,
        status: 'open',
        priceUpdatedAt: DateTime.utc(2026, 9, 15, 11),
      ));

      expect(shape[TankerkoenigFields.priceUpdatedAt],
          '2026-09-15T11:00:00.000Z');
      expect(scannedRowStamp(shape), DateTime.utc(2026, 9, 15, 11));
    });

    test('from a bulk-dataset Station', () {
      final shape = stationToTankerkoenigShape(Station(
        id: 'fr-1',
        name: 'S',
        brand: 'B',
        street: 'R',
        postCode: '1',
        place: 'P',
        lat: 48.8,
        lng: 2.3,
        e10: 1.719,
        priceUpdatedAt: DateTime.utc(2026, 9, 15, 11),
      ));

      expect(scannedRowStamp(shape), DateTime.utc(2026, 9, 15, 11),
          reason: 'the bulk path already had it on the Station (#4189) '
              'and simply dropped it here');
    });

    test('a provider with no stamp emits no key', () {
      final shape = stationPricesToTankerkoenigShape(
          const StationPrices(e10: 1.719, status: 'open'));

      expect(shape.containsKey(TankerkoenigFields.priceUpdatedAt), isFalse,
          reason: 'absent, not null-filled — the same rule the rest of '
              'the export paths follow');
      expect(scannedRowStamp(shape), isNull);
    });
  });

  group('priceAgeForScannedRow', () {
    test('a stamping provider with a stamp gives a MEASURED age', () {
      final age = priceAgeForScannedRow(fr,
          stampedAt: now.subtract(const Duration(hours: 2)), now: now);

      expect(age, const Measured(Duration(hours: 2)),
          reason: 'before #4186 this was Unknown(notPublishedForThisItem) '
              'even though FR had published the stamp');
    });

    test('a stamping provider with NO stamp still says so honestly', () {
      expect(
          priceAgeForScannedRow(fr, now: now),
          const DataValue<Duration>.unknown(
              reason: DataUnknownReason.notPublishedForThisItem),
          reason: 'the provider does stamp prices and this row has none — '
              'a fact about the row');
    });

    test('a non-stamping provider is unchanged', () {
      expect(
          priceAgeForScannedRow(de,
              stampedAt: now.subtract(const Duration(hours: 2)), now: now),
          const DataValue<Duration>.unknown(
              reason: DataUnknownReason.notPublishedByProvider),
          reason: 'DE publishes no per-price stamp; a stray value must not '
              'turn into a claim about its freshness');
    });

    test('an unregistered country is unknown, never assumed', () {
      expect(
          priceAgeForScannedRow(null, stampedAt: now, now: now),
          const DataValue<Duration>.unknown(
              reason: DataUnknownReason.notPublishedByProvider));
    });

    test('a stamp in the future is a broken feed, not a fresh price', () {
      expect(
          priceAgeForScannedRow(fr,
              stampedAt: now.add(const Duration(hours: 1)), now: now),
          const DataValue<Duration>.unknown(
              reason: DataUnknownReason.notPublishedForThisItem));
    });
  });

  test('the staleness gate can finally refuse a background opportunity', () {
    // The point of the whole change. `OpportunityScorer` refuses a
    // stalePrice only on a Measured age, so before #4186 a background
    // opportunity about a day-old price could never be caught.
    final old = priceAgeForScannedRow(fr,
        stampedAt: now.subtract(kOpportunityMaxPriceAge * 2), now: now);

    expect(old, isA<Measured<Duration>>());
    expect((old as Measured<Duration>).value,
        greaterThan(kOpportunityMaxPriceAge));
  });
}
