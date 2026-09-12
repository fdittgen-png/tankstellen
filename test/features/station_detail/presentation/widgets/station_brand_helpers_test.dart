// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_helpers.dart';
import 'package:flutter/material.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import '../../../../fixtures/stations.dart';

/// Builds a minimal Station with the given [brand]. All other fields use
/// stable, valid defaults so the brand is the only variable under test.
Station _stationWithBrand(String brand) => Station(
      id: 'fixture-id',
      name: 'Fixture Station',
      brand: brand,
      street: 'Hauptstr.',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.405,
      isOpen: true,
    );

void main() {
  group('hasRealBrand', () {
    test('returns false when brand is empty', () {
      expect(hasRealBrand(_stationWithBrand('')), isFalse);
    });

    test("returns false for legacy 'Station' sentinel", () {
      expect(hasRealBrand(_stationWithBrand('Station')), isFalse);
    });

    test('returns false for canonical Independent sentinel', () {
      expect(
        hasRealBrand(_stationWithBrand(BrandRegistry.independentLabel)),
        isFalse,
      );
    });

    test('returns true for a real single-word brand', () {
      expect(hasRealBrand(_stationWithBrand('Shell')), isTrue);
    });

    test('returns true for a real multi-word brand', () {
      expect(hasRealBrand(_stationWithBrand('TotalEnergies')), isTrue);
    });

    test('returns true for lowercase brand (no case normalization)', () {
      // The helper does NOT normalize case — only exact-match sentinels are
      // treated as missing, so a lowercased real brand is still "real".
      expect(hasRealBrand(_stationWithBrand('shell')), isTrue);
    });
  });

  group('isIndependentSentinel', () {
    test('returns false when brand is empty', () {
      expect(isIndependentSentinel(_stationWithBrand('')), isFalse);
    });

    test("returns true for legacy 'Station' sentinel", () {
      expect(isIndependentSentinel(_stationWithBrand('Station')), isTrue);
    });

    test('returns true for canonical Independent sentinel', () {
      expect(
        isIndependentSentinel(
          _stationWithBrand(BrandRegistry.independentLabel),
        ),
        isTrue,
      );
    });

    test('returns false for a real brand', () {
      expect(isIndependentSentinel(_stationWithBrand('Shell')), isFalse);
    });

    test('returns false for wrong-case sentinel (match is case-sensitive)',
        () {
      expect(
        isIndependentSentinel(_stationWithBrand('independent')),
        isFalse,
      );
    });
  });

  // #4076 — the zone folds into the header as one secondary line.
  group('stationZoneLine (#4076)', () {
    final l = lookupAppLocalizations(const Locale('en'));

    test('department, region and station kind on one line', () {
      expect(stationZoneLine(_zoned, l), 'Hérault, Occitanie · Local station');
      expect(stationZoneLine(_zonedHighway, l), 'Hérault, Occitanie · Highway');
    });

    test('absent when the source has neither department nor region', () {
      expect(stationZoneLine(testStation, l), isNull);
    });
  });
}

const _zoned = Station(
  id: '51d4b477-a095-1aa0-e100-80009459e03a',
  name: 'Star Tankstelle',
  brand: 'STAR',
  street: 'Hauptstr.',
  houseNumber: '12',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5200,
  lng: 13.4050,
  dist: 1.5,
  e5: 1.859,
  e10: 1.799,
  diesel: 1.659,
  isOpen: true,
  updatedAt: '2026-03-27T10:00:00+01:00',
  department: 'Hérault',
  region: 'Occitanie',
  stationType: 'R',
);

const _zonedHighway = Station(
  id: '51d4b477-a095-1aa0-e100-80009459e03a',
  name: 'Star Tankstelle',
  brand: 'STAR',
  street: 'Hauptstr.',
  houseNumber: '12',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5200,
  lng: 13.4050,
  dist: 1.5,
  e5: 1.859,
  e10: 1.799,
  diesel: 1.659,
  isOpen: true,
  updatedAt: '2026-03-27T10:00:00+01:00',
  department: 'Hérault',
  region: 'Occitanie',
  stationType: 'A',
);
