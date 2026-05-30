// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/station_service.dart';

void main() {
  group('StationPrices', () {
    test('constructor keeps every field including nulls', () {
      const p = StationPrices(
        e5: 1.859,
        e10: null,
        diesel: 1.659,
        status: 'open',
      );
      expect(p.e5, closeTo(1.859, 0.0001));
      expect(p.e10, isNull);
      expect(p.diesel, closeTo(1.659, 0.0001));
      expect(p.status, 'open');
    });

    test('carries the full FuelType-aligned set (#2249)', () {
      // Before #2249 the model only held e5/e10/diesel, silently dropping
      // LPG/CNG/E98/diesel-premium/E85 on a favorites/alerts refresh for
      // fuel-rich countries. All eight priced fuels must now survive.
      const p = StationPrices(
        e5: 1.81,
        e10: 1.79,
        e98: 1.95,
        diesel: 1.69,
        dieselPremium: 1.85,
        e85: 0.99,
        lpg: 0.95,
        cng: 1.49,
        status: 'open',
      );
      expect(p.e5, closeTo(1.81, 0.0001));
      expect(p.e10, closeTo(1.79, 0.0001));
      expect(p.e98, closeTo(1.95, 0.0001));
      expect(p.diesel, closeTo(1.69, 0.0001));
      expect(p.dieselPremium, closeTo(1.85, 0.0001));
      expect(p.e85, closeTo(0.99, 0.0001));
      expect(p.lpg, closeTo(0.95, 0.0001));
      expect(p.cng, closeTo(1.49, 0.0001));
      expect(p.status, 'open');
    });

    test('isOpen is true only for status == "open"', () {
      expect(
        const StationPrices(status: 'open').isOpen,
        isTrue,
      );
      expect(
        const StationPrices(status: 'closed').isOpen,
        isFalse,
      );
      // Defensive: any other string is treated as not-open.
      expect(
        const StationPrices(status: 'maintenance').isOpen,
        isFalse,
      );
    });
  });

  group('StationPrices.toJson', () {
    test('serialises every field', () {
      const p = StationPrices(
        e5: 1.859,
        e10: 1.799,
        e98: 1.999,
        diesel: 1.659,
        dieselPremium: 1.899,
        e85: 0.989,
        lpg: 0.949,
        cng: 1.499,
        status: 'open',
      );
      expect(p.toJson(), {
        'e5': 1.859,
        'e10': 1.799,
        'e98': 1.999,
        'diesel': 1.659,
        'dieselPremium': 1.899,
        'e85': 0.989,
        'lpg': 0.949,
        'cng': 1.499,
        'status': 'open',
      });
    });

    test('preserves nulls in the output map (explicit absence)', () {
      const p = StationPrices(e5: 1.8, status: 'closed');
      final json = p.toJson();
      expect(json['e5'], 1.8);
      expect(json['e10'], isNull);
      expect(json['e98'], isNull);
      expect(json['diesel'], isNull);
      expect(json['dieselPremium'], isNull);
      expect(json['e85'], isNull);
      expect(json['lpg'], isNull);
      expect(json['cng'], isNull);
      expect(json['status'], 'closed');
    });
  });

  group('StationPrices.fromJson', () {
    test('round-trips with every field set', () {
      final json = {
        'e5': 1.859,
        'e10': 1.799,
        'diesel': 1.659,
        'status': 'open',
      };
      final p = StationPrices.fromJson(json);
      expect(p.e5, closeTo(1.859, 0.0001));
      expect(p.e10, closeTo(1.799, 0.0001));
      expect(p.diesel, closeTo(1.659, 0.0001));
      expect(p.status, 'open');
    });

    test('full-set toJson→fromJson round-trip is lossless (#2249)', () {
      const original = StationPrices(
        e5: 1.811,
        e10: 1.791,
        e98: 1.951,
        diesel: 1.691,
        dieselPremium: 1.851,
        e85: 0.991,
        lpg: 0.951,
        cng: 1.491,
        status: 'open',
      );
      final restored = StationPrices.fromJson(original.toJson());
      expect(restored.e5, closeTo(original.e5!, 0.0001));
      expect(restored.e10, closeTo(original.e10!, 0.0001));
      expect(restored.e98, closeTo(original.e98!, 0.0001));
      expect(restored.diesel, closeTo(original.diesel!, 0.0001));
      expect(restored.dieselPremium, closeTo(original.dieselPremium!, 0.0001));
      expect(restored.e85, closeTo(original.e85!, 0.0001));
      expect(restored.lpg, closeTo(original.lpg!, 0.0001));
      expect(restored.cng, closeTo(original.cng!, 0.0001));
      expect(restored.status, 'open');
    });

    test('null price values map to null on the model', () {
      final p = StationPrices.fromJson({
        'e5': null,
        'e10': null,
        'diesel': null,
        'status': 'closed',
      });
      expect(p.e5, isNull);
      expect(p.e10, isNull);
      expect(p.diesel, isNull);
    });

    test('integer prices from APIs are coerced to doubles', () {
      // Some APIs emit `1.6` as the integer `2` after rounding, or
      // bare ints for round prices. Defend against both cases.
      final p = StationPrices.fromJson({
        'e5': 2,
        'status': 'open',
      });
      expect(p.e5, 2.0);
    });

    test('non-numeric price fields become null rather than throwing', () {
      // The defensive `json[x] is num ? ... : null` path — matters
      // because historical Hive caches occasionally held `false`
      // sentinels for closed stations in the e5 slot.
      final p = StationPrices.fromJson({
        'e5': false,
        'e10': 'not-a-number',
        'diesel': null,
        'status': 'open',
      });
      expect(p.e5, isNull);
      expect(p.e10, isNull);
      expect(p.diesel, isNull);
    });

    test('missing status falls back to "closed"', () {
      // So the UI never shows an incorrect "open" bubble for a
      // malformed / truncated response.
      final p = StationPrices.fromJson(const {});
      expect(p.status, 'closed');
      expect(p.isOpen, isFalse);
    });
  });
}
