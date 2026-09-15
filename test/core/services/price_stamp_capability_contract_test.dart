// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/features/station_services/france/prix_carburants_parsers.dart';
import 'package:tankstellen/features/station_services/portugal/portugal_merged_row.dart';

/// #4189 — a country that CLAIMS `priceTimestamp: true` must actually
/// produce a datable stamp from a real recorded response.
///
/// The defect this locks out: `kFrCapability` said the provider stamps
/// prices, the adapter parsed that stamp and stored only its
/// `dd/MM HH:mm` LABEL, and `DateTime.tryParse` returned null — so the
/// freshness gate read "the provider left this row blank", blocked, and
/// the confident pick was silently withheld across France, Denmark and
/// Portugal. Both halves were individually correct; nothing tested the
/// join.
///
/// So this drives RECORDED REAL RESPONSES through the real parsers
/// (#2776's rule: a fake that echoes the request proves nothing about a
/// data-shape bug) and asserts the instant comes out, not the label.
void main() {
  Map<String, dynamic> readJson(String name) =>
      jsonDecode(File('test/fixtures/$name').readAsStringSync())
          as Map<String, dynamic>;

  group('France — Prix-Carburants', () {
    test('a recorded record yields a real instant, not just a label', () {
      final record = (readJson('prix_carburants_paris_geo_ordered.json')
          ['results'] as List).first as Map<String, dynamic>;

      final label = parsePrixCarburantsMostRecentUpdate(record);
      final instant = parsePrixCarburantsUpdatedAt(record);

      expect(label, isNotNull, reason: 'the display value is unchanged');
      expect(DateTime.tryParse(label!), isNull,
          reason: 'and it remains unparseable — which is exactly why it '
              'must never be what the gate reads');
      expect(instant, isNotNull,
          reason: 'FR declares priceTimestamp: true, so a recorded record '
              'MUST produce a datable stamp');
      expect(instant, DateTime.parse('2026-04-16T14:51:12+00:00'));
    });

    test('a record with no maj fields yields no instant, not a guess', () {
      expect(parsePrixCarburantsUpdatedAt({'id': '1'}), isNull);
    });
  });

  PortugalMergedRow ptRow() => PortugalMergedRow(
        id: 1,
        name: 'Posto',
        brand: 'Galp',
        street: 'Rua',
        postCode: '1000',
        place: 'Lisboa',
        lat: 38.72,
        lng: -9.14,
      );

  group('Portugal — DGEG', () {
    test('a recorded row yields a real instant', () {
      // The DGEG stamp travels on the fuel rows; the merged row keeps
      // the freshest one.
      final row = ptRow()..noteUpdatedAt('2026-06-08 13:15');

      expect(row.formattedUpdatedAt, '08/06 13:15',
          reason: 'the display value is unchanged');
      expect(DateTime.tryParse(row.formattedUpdatedAt!), isNull);
      expect(row.priceUpdatedAt, DateTime.parse('2026-06-08 13:15'),
          reason: 'PT declares priceTimestamp: true');
    });

    test('an absent stamp yields no instant', () {
      expect(ptRow().priceUpdatedAt, isNull);
    });
  });

  group('the capability rows this protects', () {
    test('FR, PT and DK all claim to stamp prices', () {
      for (final code in ['FR', 'PT', 'DK']) {
        final capability = CountryServiceRegistry.capabilityFor(code);
        expect(capability, isNotNull, reason: code);
        expect(capability!.priceTimestamp, isTrue,
            reason: '$code claims it — so its adapter owes a datable '
                'stamp, which is what the cases above check');
      }
    });

    test('and Germany does not, so nothing is owed there', () {
      final de = CountryServiceRegistry.capabilityFor('DE')!;
      expect(de.priceTimestamp, isFalse,
          reason: 'DE stamps nothing per price; its unknown stands the '
              'gate down with a caveat instead of blocking');
    });
  });
}
