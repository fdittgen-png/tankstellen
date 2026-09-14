// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/price_baseline.dart';
import 'package:tankstellen/features/fill_ups/domain/services/savings_ledger.dart';

/// #4150 + #4136 — what this driver normally pays, and what beating it
/// was worth.
///
/// A savings total is the easiest number in this app to fake and the most
/// damaging to get wrong, so most of these tests are about what it
/// REFUSES to count.
void main() {
  final now = DateTime.utc(2026, 9, 13);

  FillUp fill({
    required String id,
    required double litres,
    required double pricePerLitre,
    int daysAgo = 1,
    FuelType fuel = FuelType.e10,
    bool correction = false,
  }) =>
      FillUp(
        id: id,
        date: now.subtract(Duration(days: daysAgo)),
        liters: litres,
        totalCost: litres * pricePerLitre,
        odometerKm: 10000 + daysAgo.toDouble(),
        fuelType: fuel,
        isCorrection: correction,
      );

  group('the baseline', () {
    test('is the MEDIAN, so one motorway fill cannot move it', () {
      final fills = [
        fill(id: '1', litres: 40, pricePerLitre: 1.70),
        fill(id: '2', litres: 40, pricePerLitre: 1.72, daysAgo: 10),
        fill(id: '3', litres: 40, pricePerLitre: 1.74, daysAgo: 20),
        // The outlier a mean would let through.
        fill(id: '4', litres: 5, pricePerLitre: 2.50, daysAgo: 30),
      ];

      final b = priceBaselineFor(fills, fuelType: FuelType.e10, now: now)!;
      expect(b.typicalPricePerLitre, closeTo(1.73, 1e-9));
      expect(b.typicalPricePerLitre, lessThan(1.80),
          reason: 'a mean would be dragged past 1.9 by the €2.50 fill');
    });

    test('needs enough history, and says so by being null', () {
      final fills = [
        fill(id: '1', litres: 40, pricePerLitre: 1.70),
        fill(id: '2', litres: 40, pricePerLitre: 1.72),
      ];
      expect(priceBaselineFor(fills, fuelType: FuelType.e10, now: now), isNull,
          reason: 'a baseline on two fills is noise wearing a number');
    });

    test('ignores fills outside the window', () {
      final fills = [
        for (var i = 0; i < 5; i++)
          fill(id: 'old$i', litres: 40, pricePerLitre: 1.20, daysAgo: 200),
        for (var i = 0; i < 5; i++)
          fill(id: 'new$i', litres: 40, pricePerLitre: 1.80, daysAgo: 5),
      ];
      final b = priceBaselineFor(fills, fuelType: FuelType.e10, now: now)!;
      expect(b.typicalPricePerLitre, closeTo(1.80, 1e-9),
          reason: 'last year\'s prices are not what you normally pay now');
    });

    test('is per fuel — an E85 fill does not price a diesel baseline', () {
      final fills = [
        for (var i = 0; i < 4; i++)
          fill(id: 'd$i', litres: 40, pricePerLitre: 1.70,
              fuel: FuelType.diesel, daysAgo: i + 1),
        for (var i = 0; i < 4; i++)
          fill(id: 'e$i', litres: 40, pricePerLitre: 0.85,
              fuel: FuelType.e85, daysAgo: i + 1),
      ];
      expect(
        priceBaselineFor(fills, fuelType: FuelType.diesel, now: now)!
            .typicalPricePerLitre,
        closeTo(1.70, 1e-9),
      );
    });

    test('excludes corrections', () {
      final fills = [
        for (var i = 0; i < 4; i++)
          fill(id: 'f$i', litres: 40, pricePerLitre: 1.70, daysAgo: i + 1),
        fill(id: 'c', litres: 999, pricePerLitre: 0.01, correction: true),
      ];
      expect(
        priceBaselineFor(fills, fuelType: FuelType.e10, now: now)!
            .typicalPricePerLitre,
        closeTo(1.70, 1e-9),
      );
    });
  });

  group('the ledger', () {
    test('counts a cheap fill as a saving, reproducibly', () {
      final fills = [
        for (var i = 0; i < 4; i++)
          fill(id: 'f$i', litres: 40, pricePerLitre: 1.70, daysAgo: i + 2),
        fill(id: 'cheap', litres: 50, pricePerLitre: 1.60),
      ];

      final ledger = savingsLedgerFor(fills, fuelType: FuelType.e10, now: now);
      final entry = ledger.entries.firstWhere((e) => e.fillUpId == 'cheap');

      // Hand-checkable: (1.70 − 1.60) × 50 = 5.00
      expect(entry.referencePrice, closeTo(1.70, 1e-9));
      expect(entry.amount, closeTo(5.0, 1e-9));
    });

    test('an expensive fill counts AGAINST the total', () {
      // A ledger that only counted wins would be a marketing number, and
      // its total a lie of omission.
      final fills = [
        for (var i = 0; i < 4; i++)
          fill(id: 'f$i', litres: 40, pricePerLitre: 1.70, daysAgo: i + 2),
        fill(id: 'dear', litres: 50, pricePerLitre: 1.90),
      ];

      final ledger = savingsLedgerFor(fills, fuelType: FuelType.e10, now: now);
      expect(ledger.entries.firstWhere((e) => e.fillUpId == 'dear').amount,
          closeTo(-10.0, 1e-9));
      expect(ledger.total, lessThan(ledger.totalSaved),
          reason: 'the net must be visible beside the wins-only figure');
    });

    test('no baseline, no ledger — never a zero that looks computed', () {
      final ledger = savingsLedgerFor(
        [fill(id: '1', litres: 40, pricePerLitre: 1.70)],
        fuelType: FuelType.e10,
        now: now,
      );
      expect(ledger.isAvailable, isFalse);
      expect(ledger.entries, isEmpty);
    });

    test('deleting a fill-up removes its entry, for free', () {
      final fills = [
        for (var i = 0; i < 5; i++)
          fill(id: 'f$i', litres: 40, pricePerLitre: 1.70, daysAgo: i + 1),
      ];
      final before = savingsLedgerFor(fills, fuelType: FuelType.e10, now: now);
      final after = savingsLedgerFor(
        fills.where((f) => f.id != 'f0'),
        fuelType: FuelType.e10,
        now: now,
      );

      // Derived, not stored: there is no second copy that can drift.
      expect(after.entries.length, before.entries.length - 1);
      expect(after.entries.any((e) => e.fillUpId == 'f0'), isFalse);
    });
  });
}
