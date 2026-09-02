// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station_amenity.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_amenities_services_section.dart';

/// The dedup rule behind the merged "Amenities & services" section
/// (#3928, epic #3925) — unit-level, so the normalisation can be pinned
/// without pumping a widget.
void main() {
  group('normaliseAmenityKey', () {
    test('strips case, accents and punctuation', () {
      expect(normaliseAmenityKey('Toilettes'), normaliseAmenityKey('toilettes'));
      expect(normaliseAmenityKey('Épicerie'), normaliseAmenityKey('epicerie'));
      expect(normaliseAmenityKey('Wi-Fi'), normaliseAmenityKey('WIFI'));
      expect(normaliseAmenityKey('Relais colis'), 'relaiscolis');
    });

    test('folds the synonyms the upstream APIs actually emit', () {
      expect(normaliseAmenityKey('Station de lavage'), 'carwash');
      expect(normaliseAmenityKey('Lavage'), 'carwash');
      expect(normaliseAmenityKey('Lavage automatique'), 'carwash');
      expect(normaliseAmenityKey('Boutique'), 'shop');
      expect(normaliseAmenityKey('Shop'), 'shop');
      expect(normaliseAmenityKey('DAB'), 'atm');
      expect(normaliseAmenityKey('Distributeur'), 'atm');
      expect(normaliseAmenityKey('Gonflage'), 'airpump');
      expect(normaliseAmenityKey('Air'), 'airpump');
      expect(normaliseAmenityKey('WC'), 'toilet');
    });

    test('leaves an unknown service in its own bucket', () {
      expect(normaliseAmenityKey('Piste poids lourds'), 'pistepoidslourds');
      expect(
        normaliseAmenityKey('Piste poids lourds'),
        isNot(normaliseAmenityKey('Relais colis')),
      );
    });
  });

  group('mergedServiceLabels', () {
    test('drops every raw string a typed amenity already says', () {
      final kept = mergedServiceLabels(
        amenities: const {
          StationAmenity.carWash,
          StationAmenity.airPump,
          StationAmenity.atm,
        },
        services: const [
          'Station de lavage',
          'Gonflage',
          'Distributeur',
          'Piste poids lourds',
        ],
      );

      expect(kept, ['Piste poids lourds']);
    });

    test('deduplicates the raw list against itself', () {
      final kept = mergedServiceLabels(
        amenities: const {},
        services: const ['Lavage', 'Station de lavage', 'Boutique', 'Shop'],
      );

      // First wording wins its bucket; the later synonym is dropped.
      expect(kept, ['Lavage', 'Boutique']);
    });

    test('keeps source order and skips blank entries', () {
      final kept = mergedServiceLabels(
        amenities: const {},
        services: const ['Bar', '  ', 'Douches', ''],
      );

      expect(kept, ['Bar', 'Douches']);
    });

    test('an empty amenity set keeps every distinct service', () {
      final kept = mergedServiceLabels(
        amenities: const {},
        services: const ['Piste poids lourds', 'Relais colis'],
      );

      expect(kept, ['Piste poids lourds', 'Relais colis']);
    });
  });
}
