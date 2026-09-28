// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/currency_backfill.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';

/// #4406 — the bulk currency statement: explicit, label-only, reversible.
void main() {
  final statedAt = DateTime(2026, 9, 27, 10);

  FillUp fill(String id, DateTime date, double odo,
          {String? currency, double cost = 70, bool correction = false}) =>
      FillUp(
        id: id,
        date: date,
        liters: 40,
        totalCost: correction ? 0 : cost,
        odometerKm: odo,
        fuelType: FuelType.e5,
        currency: currency,
        isCorrection: correction,
        isFullTank: !correction,
        notes: 'n-$id',
      );

  // A long-standing user: three pre-#4136 fills, then stamped EUR ones.
  final legacy = [
    fill('l1', DateTime(2025, 11, 3), 10000),
    fill('l2', DateTime(2025, 12, 1, 18, 40), 10600),
    fill('l3', DateTime(2026, 1, 12), 11200),
    fill('s1', DateTime(2026, 2, 2), 11800, currency: 'EUR'),
    fill('s2', DateTime(2026, 3, 2), 12400, currency: 'EUR'),
  ];

  test('labels only unknown fills on or before the stated day', () {
    final r = applyCurrencyBackfill(legacy,
        currency: 'eur',
        onOrBefore: DateTime(2025, 12, 1),
        statedAt: statedAt);
    // "on or before 1 Dec" covers the 18:40 fill of that day.
    expect(r.labelled.map((f) => f.id), ['l1', 'l2']);
    expect(r.labelled.every((f) => f.currency == 'EUR'), isTrue);
    expect(r.labelled.every((f) => f.currencyStatedAt == statedAt), isTrue);
    // The one left over is reported, never guessed.
    expect(r.remaining, 1);
  });

  test('never touches anything but the currency label', () {
    final r = applyCurrencyBackfill(legacy,
        currency: 'EUR', onOrBefore: DateTime(2026, 1, 31), statedAt: statedAt);
    expect(r.labelled, hasLength(3));
    for (final changed in r.labelled) {
      final before = legacy.singleWhere((f) => f.id == changed.id);
      expect(changed.copyWith(currency: null, currencyStatedAt: null), before);
    }
  });

  test('a record that already carries a currency is never relabelled', () {
    final r = applyCurrencyBackfill(legacy,
        currency: 'CHF', onOrBefore: DateTime(2026, 12, 31), statedAt: statedAt);
    expect(r.labelled.map((f) => f.id), ['l1', 'l2', 'l3']);
  });

  test('the currency must be stated — an empty one is refused', () {
    expect(
      () => applyCurrencyBackfill(legacy,
          currency: ' ', onOrBefore: DateTime(2026), statedAt: statedAt),
      throwsArgumentError,
    );
  });

  test('after the statement the totals return, equal to stamped records',
      () {
    expect(ConsumptionStats.fromFillUps(legacy).totalSpent, isNull);
    final r = applyCurrencyBackfill(legacy,
        currency: 'EUR', onOrBefore: DateTime(2026, 1, 31), statedAt: statedAt);
    final byId = {for (final f in r.labelled) f.id: f};
    final after = [for (final f in legacy) byId[f.id] ?? f];
    final stampedFromTheStart = [
      for (final f in legacy)
        f.currency == null ? f.copyWith(currency: 'EUR') : f,
    ];
    final a = ConsumptionStats.fromFillUps(after);
    final b = ConsumptionStats.fromFillUps(stampedFromTheStart);
    expect(a.totalSpent, 350);
    expect(a.totalSpent, b.totalSpent);
    expect(a.avgCostPerKm, b.avgCostPerKm);
    expect(a.avgPricePerLiter, b.avgPricePerLiter);
    expect(a.avgConsumptionL100km, b.avgConsumptionL100km);
    expect(r.remaining, 0);
  });

  test('undo returns exactly the stated records to unknown', () {
    final chosenPerRecord =
        fill('x', DateTime(2025, 10, 1), 9000, currency: 'CHF');
    final r = applyCurrencyBackfill([...legacy, chosenPerRecord],
        currency: 'EUR', onOrBefore: DateTime(2026, 1, 31), statedAt: statedAt);
    final reverted = revertCurrencyBackfill(r.labelled);
    expect(reverted.map((f) => f.id), ['l1', 'l2', 'l3']);
    for (final f in reverted) {
      expect(f, legacy.singleWhere((o) => o.id == f.id));
    }
    // A currency chosen per record (settle sheet) is not a bulk statement.
    expect(revertCurrencyBackfill([chosenPerRecord]), isEmpty);
  });

  test('corrections carry no money and are not counted as unknown spend', () {
    final withCorrection = [
      ...legacy,
      fill('c', DateTime(2026, 3, 10), 12500, correction: true),
    ];
    expect(unknownCurrencyPricedFillCount(withCorrection), 3);
  });
}
