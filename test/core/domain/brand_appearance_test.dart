// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/brand_appearance.dart';
import 'package:tankstellen/core/domain/brand_registry.dart';

/// #3930 — the offline brand mark. Every canonical brand must own a
/// colour and a monogram, and every monogram must be legible on the
/// colour beside it.
void main() {
  group('BrandAppearance table', () {
    test('every canonical BrandRegistry brand has an appearance', () {
      final missing = BrandRegistry.allBrands
          .where((b) => !brandAppearances.containsKey(b))
          .toList();

      expect(
        missing,
        isEmpty,
        reason: 'these canonical brands would still render the neutral grey '
            'tile every user saw before #3930: $missing',
      );
    });

    test('every appearance key is a canonical brand or a documented '
        'registry-less charging network', () {
      // `Mer` is deliberately out of the registry — `mer` is a substring
      // of `Supermarché` and would poison the partial-match pass.
      const registryLess = {'Mer'};
      final canonical = BrandRegistry.allBrands.toSet();

      final orphans = brandAppearances.keys
          .where((k) => !canonical.contains(k) && !registryLess.contains(k))
          .toList();

      expect(
        orphans,
        isEmpty,
        reason: 'appearance keys that no longer canonicalise would silently '
            'stop resolving: $orphans',
      );
    });

    test('every monogram is 1-3 characters and non-blank', () {
      for (final entry in brandAppearances.entries) {
        final monogram = entry.value.monogram;
        expect(monogram.trim(), isNotEmpty, reason: entry.key);
        expect(
          monogram.length,
          inInclusiveRange(1, 3),
          reason: '${entry.key} monogram "$monogram" is not 1-3 characters',
        );
      }
    });

    test('every monogram clears the 4.5:1 WCAG contrast floor', () {
      for (final entry in brandAppearances.entries) {
        expect(
          entry.value.contrastRatio,
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: monogram "${entry.value.monogram}" on '
              '${entry.value.background} is below the AA floor',
        );
      }
    });

    test('a light ground takes black text, a dark ground takes white', () {
      // Shell yellow and Aral blue — the two ends of the table.
      expect(brandAppearances['Shell']!.foreground, const Color(0xFF000000));
      expect(brandAppearances['Aral']!.foreground, const Color(0xFFFFFFFF));
    });

    test('the charging networks carry an EV or dual kind, never fuel-only',
        () {
      const evNetworks = [
        'Ionity',
        'Fastned',
        'Allego',
        'EnBW',
        'Electra',
        'Izivia',
        'Freshmile',
        'Driveco',
        'Bump',
        'Engie Vianeo',
        'Powerdot',
        'Zunder',
        'Atlante',
        'Be Charge',
        'Enel X Way',
        'Vattenfall InCharge',
        'Tesla',
        'Shell Recharge',
        'TotalEnergies Charge',
        'E.ON Drive',
        'Mer',
      ];
      for (final network in evNetworks) {
        final appearance = brandAppearances[network];
        expect(appearance, isNotNull, reason: '$network has no appearance');
        expect(appearance!.kind, BrandKind.ev, reason: network);
      }
      // Supermarkets and majors run both.
      for (final dual in ['Circle K', 'Lidl', 'Aldi', 'Kaufland', 'Shell']) {
        expect(brandAppearances[dual]!.kind, BrandKind.both, reason: dual);
      }
    });
  });

  group('BrandAppearance.of', () {
    test('resolves an exact canonical name', () {
      expect(BrandAppearance.of('Shell')!.monogram, 'SH');
    });

    test('canonicalises an alias before looking up', () {
      // Star was folded into Orlen; TOTAL ACCESS into TotalEnergies.
      expect(BrandAppearance.of('STAR')!.monogram, 'OR');
      expect(BrandAppearance.of('TOTAL ACCESS')!.monogram, 'TE');
      expect(BrandAppearance.of('Statoil')!.monogram, 'CK');
    });

    test('trims and is case-insensitive', () {
      expect(BrandAppearance.of('  aral  ')!.monogram, 'AR');
    });

    test('resolves a registry-less network by its exact operator title', () {
      expect(BrandAppearance.of('Mer')!.kind, BrandKind.ev);
    });

    test('returns null for an unknown brand and for blank input', () {
      expect(BrandAppearance.of('NoSuchNetwork123'), isNull);
      expect(BrandAppearance.of(''), isNull);
      expect(BrandAppearance.of('   '), isNull);
    });

    test('the independent sentinel stays unbranded', () {
      expect(BrandAppearance.of(BrandRegistry.independentLabel), isNull);
    });
  });

  group('EV networks in the registry (#3931)', () {
    test('the European networks canonicalise from their common spellings', () {
      expect(BrandRegistry.canonicalize('IONITY'), 'Ionity');
      expect(BrandRegistry.canonicalize('Fastned'), 'Fastned');
      expect(BrandRegistry.canonicalize('Power Dot'), 'Powerdot');
      expect(BrandRegistry.canonicalize('NewMotion'), 'Shell Recharge');
      expect(BrandRegistry.canonicalize('Supercharger'), 'Tesla');
      expect(BrandRegistry.canonicalize('EnBW mobility+'), 'EnBW');
    });

    test('`Mer` and `Recharge` stay OUT of the registry — their names are '
        'substrings that would stamp a phantom brand (#481 / #2922)', () {
      expect(BrandRegistry.allBrands, isNot(contains('Mer')));
      expect(BrandRegistry.allBrands, isNot(contains('Recharge')));
      // The regression the exclusion prevents.
      expect(BrandRegistry.canonicalize('Supermarché du Port'), isNot('Mer'));
    });

    test('adding the networks did not disturb the fuel vocabulary', () {
      expect(BrandRegistry.canonicalize('Shell'), 'Shell');
      expect(BrandRegistry.canonicalize('TotalEnergies'), 'TotalEnergies');
      expect(BrandRegistry.canonicalize('Power'), 'Power');
      expect(BrandRegistry.canonicalize('Circle K'), 'Circle K');
    });
  });
}
