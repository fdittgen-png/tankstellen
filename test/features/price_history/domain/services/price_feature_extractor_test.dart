// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/domain/services/price_feature_extractor.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// Fast, station-stub-friendly factory for tests.
Station _stubStation({String brand = 'Aral'}) => Station(
      id: 'de-1',
      name: 'Test Station',
      brand: brand,
      street: 'Hauptstr.',
      postCode: '12345',
      place: 'Berlin',
      lat: 52.5,
      lng: 13.4,
      isOpen: true,
    );

void main() {
  const extractor = PriceFeatureExtractor();

  group('PriceFeatureExtractor — basic extraction', () {
    test('produces one vector per record with a price for the requested fuel',
        () {
      final records = [
        PriceRecord(
          stationId: 'de-1',
          recordedAt: DateTime(2026, 5, 1, 8),
          e10: 1.65,
        ),
        PriceRecord(
          stationId: 'de-1',
          recordedAt: DateTime(2026, 5, 1, 18),
          e10: 1.72,
        ),
        // No e10 — should be skipped.
        PriceRecord(
          stationId: 'de-1',
          recordedAt: DateTime(2026, 5, 2, 10),
          diesel: 1.50,
        ),
      ];

      final vectors = extractor.extract(
        records: records,
        fuelType: FuelType.e10,
      );

      expect(vectors, hasLength(2));
      expect(vectors[0].priceEur, 1.65);
      expect(vectors[1].priceEur, 1.72);
    });

    test('hourOfDay and dayOfWeek mirror DateTime.hour/weekday', () {
      // 2026-05-01 is a Friday → weekday 5.
      final r = PriceRecord(
        stationId: 'de-1',
        recordedAt: DateTime(2026, 5, 1, 14),
        diesel: 1.50,
      );
      final v = extractor.extract(
        records: [r],
        fuelType: FuelType.diesel,
      ).single;

      expect(v.hourOfDay, 14);
      expect(v.dayOfWeek, 5);
    });

    test('returns an empty list when no records have a price for the fuel',
        () {
      final records = [
        PriceRecord(
          stationId: 'de-1',
          recordedAt: DateTime(2026, 5, 1, 8),
          diesel: 1.50,
        ),
      ];
      final vectors = extractor.extract(
        records: records,
        fuelType: FuelType.e10,
      );
      expect(vectors, isEmpty);
    });

    test('returns an empty list for hydrogen / electric / all (unsupported)',
        () {
      final records = [
        PriceRecord(
          stationId: 'de-1',
          recordedAt: DateTime(2026, 5, 1, 8),
          e10: 1.50,
          diesel: 1.40,
        ),
      ];
      expect(
        extractor.extract(records: records, fuelType: FuelType.hydrogen),
        isEmpty,
      );
      expect(
        extractor.extract(records: records, fuelType: FuelType.electric),
        isEmpty,
      );
      expect(
        extractor.extract(records: records, fuelType: FuelType.all),
        isEmpty,
      );
    });
  });

  group('PriceFeatureExtractor — station / brand / country pass-through', () {
    test('brand flows from station.brand into the vector', () {
      final r = PriceRecord(
        stationId: 'de-1',
        recordedAt: DateTime(2026, 5, 1, 10),
        e10: 1.65,
      );
      final v = extractor.extract(
        records: [r],
        fuelType: FuelType.e10,
        station: _stubStation(brand: 'Shell'),
      ).single;
      expect(v.brand, 'Shell');
    });

    test('brand is null when station is null', () {
      final r = PriceRecord(
        stationId: 'de-1',
        recordedAt: DateTime(2026, 5, 1, 10),
        e10: 1.65,
      );
      final v = extractor.extract(
        records: [r],
        fuelType: FuelType.e10,
      ).single;
      expect(v.brand, isNull);
    });

    test('countryCodeOverride wins over station-derived country', () {
      final r = PriceRecord(
        stationId: 'de-1',
        recordedAt: DateTime(2026, 5, 1, 10),
        e10: 1.65,
      );
      final v = extractor.extract(
        records: [r],
        fuelType: FuelType.e10,
        station: _stubStation(),
        countryCodeOverride: 'FR',
      ).single;
      expect(v.countryCode, 'FR');
    });

    test('countryCode is null when neither station nor override is provided',
        () {
      final r = PriceRecord(
        stationId: 'unknown',
        recordedAt: DateTime(2026, 5, 1, 10),
        e10: 1.65,
      );
      final v = extractor.extract(
        records: [r],
        fuelType: FuelType.e10,
      ).single;
      expect(v.countryCode, isNull);
    });
  });

  group('PriceFeatureExtractor — holiday flag', () {
    test('Bastille Day (Jul 14) records get isHoliday=true when country=FR',
        () {
      final records = [
        PriceRecord(
          stationId: 'fr-1',
          recordedAt: DateTime(2026, 7, 14, 10),
          e10: 1.80,
        ),
        PriceRecord(
          stationId: 'fr-1',
          recordedAt: DateTime(2026, 7, 15, 10),
          e10: 1.78,
        ),
      ];
      final vectors = extractor.extract(
        records: records,
        fuelType: FuelType.e10,
        countryCodeOverride: 'FR',
      );
      expect(vectors[0].isHoliday, isTrue);
      expect(vectors[1].isHoliday, isFalse);
    });

    test('Bastille Day in DE does not flag — national holiday is country-specific',
        () {
      final r = PriceRecord(
        stationId: 'de-1',
        recordedAt: DateTime(2026, 7, 14, 10),
        e10: 1.80,
      );
      final v = extractor.extract(
        records: [r],
        fuelType: FuelType.e10,
        countryCodeOverride: 'DE',
      ).single;
      expect(v.isHoliday, isFalse);
    });

    test('Christmas Day flags everywhere, even with null country', () {
      final r = PriceRecord(
        stationId: 'unknown',
        recordedAt: DateTime(2026, 12, 25, 10),
        e10: 1.80,
      );
      final v = extractor.extract(
        records: [r],
        fuelType: FuelType.e10,
      ).single;
      expect(v.isHoliday, isTrue);
    });
  });

  group('PriceFeatureExtractor — fuel coverage', () {
    test('extracts price from each supported fuel field', () {
      final base = DateTime(2026, 5, 1, 10);
      // One record per fuel field.
      final pairs = <(FuelType, PriceRecord, double)>[
        (
          FuelType.e5,
          PriceRecord(stationId: 's', recordedAt: base, e5: 1.80),
          1.80,
        ),
        (
          FuelType.e10,
          PriceRecord(stationId: 's', recordedAt: base, e10: 1.70),
          1.70,
        ),
        (
          FuelType.e98,
          PriceRecord(stationId: 's', recordedAt: base, e98: 1.95),
          1.95,
        ),
        (
          FuelType.diesel,
          PriceRecord(stationId: 's', recordedAt: base, diesel: 1.55),
          1.55,
        ),
        (
          FuelType.dieselPremium,
          PriceRecord(
              stationId: 's', recordedAt: base, dieselPremium: 1.75),
          1.75,
        ),
        (
          FuelType.e85,
          PriceRecord(stationId: 's', recordedAt: base, e85: 1.05),
          1.05,
        ),
        (
          FuelType.lpg,
          PriceRecord(stationId: 's', recordedAt: base, lpg: 0.95),
          0.95,
        ),
        (
          FuelType.cng,
          PriceRecord(stationId: 's', recordedAt: base, cng: 1.25),
          1.25,
        ),
      ];
      for (final (ft, record, expected) in pairs) {
        final v = extractor.extract(
          records: [record],
          fuelType: ft,
        ).single;
        expect(v.priceEur, expected, reason: 'fuel ${ft.apiValue}');
      }
    });
  });
}
