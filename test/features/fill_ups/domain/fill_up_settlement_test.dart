// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/features/carbon/domain/monthly_summary.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_report.dart';

/// #4437 B/D/E — a foreign fill carries the money the card statement
/// charged, the rate that implies, and every spend aggregate books that
/// amount instead of summing across currencies.
void main() {
  // The Gandria receipt (#4428): SP95 25,61 L at CHF 2,020/L = CHF 51,73.
  final gandriaDate = DateTime(2026, 9, 20, 14, 5);
  FillUp gandria({String? currency = 'CHF'}) => FillUp(
        id: 'gandria',
        date: gandriaDate,
        liters: 25.61,
        totalCost: 51.73,
        odometerKm: 10500,
        fuelType: FuelType.e5,
        currency: currency,
        scannedPricePerLiter: 2.020,
      );

  FillUp home(String id, DateTime date, double odo,
          {double liters = 40, double cost = 70, String? currency = 'EUR'}) =>
      FillUp(
        id: id,
        date: date,
        liters: liters,
        totalCost: cost,
        odometerKm: odo,
        fuelType: FuelType.e5,
        currency: currency,
      );

  group('settledExchangeRateOf', () {
    test('a card settlement implies base CHF, quote EUR, dated to the fill',
        () {
      final settled =
          gandria().settledByCard(amount: 55.12, currency: 'eur');
      final rate = settledExchangeRateOf(settled)!;
      expect(rate.baseCurrency, 'CHF');
      expect(rate.quoteCurrency, 'EUR');
      expect(rate.rate, closeTo(55.12 / 51.73, 1e-12));
      expect(rate.source, kRateSourceCardSettlement);
      // The TRANSACTION date — never the day the statement was typed in.
      expect(rate.capturedAt, gandriaDate);
    });

    test('a hand-typed rate is stored AND labelled as entered by hand', () {
      final settled =
          gandria().settledByHandRate(rate: 1.07, currency: 'EUR');
      expect(settled.rateSource, kRateSourceEnteredByHand);
      expect(settled.isRateEnteredByHand, isTrue);
      expect(settledExchangeRateOf(settled)!.source, kRateSourceEnteredByHand);
      expect(settled.settledAmount, closeTo(51.73 * 1.07, 1e-9));
    });

    test('no rate without a nameable base, a conversion, or real amounts',
        () {
      // Unknown record currency: a rate needs a base that can be named.
      expect(
          settledExchangeRateOf(gandria(currency: null)
              .copyWith(settledAmount: 55.12, settledCurrency: 'EUR')),
          isNull);
      // Same currency: nothing was converted.
      expect(
          settledExchangeRateOf(gandria(currency: 'EUR')
              .settledByCard(amount: 51.73, currency: 'EUR')),
          isNull);
      expect(
          settledExchangeRateOf(
              gandria().settledByCard(amount: 0, currency: 'EUR')),
          isNull);
      expect(settledExchangeRateOf(gandria()), isNull);
    });

    test('withoutSettlement returns the record to its native amount', () {
      final back = gandria()
          .settledByCard(amount: 55.12, currency: 'EUR')
          .withoutSettlement();
      expect(back.settledAmount, isNull);
      expect(back.settledCurrency, isNull);
      expect(back.rateSource, isNull);
      expect(back.rateCapturedAt, isNull);
      expect(back.bookedSpend, (51.73, 'CHF'));
    });

    test('the new fields round-trip through JSON (the synced data blob)',
        () {
      final settled = gandria().settledByCard(amount: 55.12, currency: 'EUR');
      final back = FillUp.fromJson(settled.toJson());
      expect(back, settled);
      // A pre-#4437 row still decodes, with no settlement.
      final legacy = Map<String, dynamic>.from(gandria().toJson())
        ..remove('settledAmount')
        ..remove('settledCurrency')
        ..remove('rateSource')
        ..remove('rateCapturedAt');
      expect(FillUp.fromJson(legacy).isSettled, isFalse);
    });
  });

  group('bookedSpend', () {
    test('the settled amount EXACTLY as entered, never totalCost × rate', () {
      final settled = gandria().settledByCard(amount: 55.12, currency: 'EUR');
      expect(settled.bookedSpend, (55.12, 'EUR'));
      expect(settled.settledMoney, const Money(55.12, 'EUR'));
    });

    test('an unsettled record books its native amount and currency', () {
      expect(gandria().bookedSpend, (51.73, 'CHF'));
      expect(gandria(currency: null).bookedSpend, (51.73, null));
    });
  });

  test('settledRatesSnapshot holds every settled rate, newest first', () {
    final older = gandria()
        .copyWith(id: 'a', date: DateTime(2026, 5, 1))
        .settledByCard(amount: 50, currency: 'EUR');
    final newer = gandria().settledByCard(amount: 55.12, currency: 'EUR');
    final snapshot = settledRatesSnapshot([older, gandria(), newer]);
    expect(snapshot.rates, hasLength(2));
    expect(snapshot.rates.first.capturedAt, gandriaDate);
  });

  group('ConsumptionStats with a Swiss fill (#4437 / #4364)', () {
    final history = [
      home('h1', DateTime(2026, 9, 1), 10000),
      home('h2', DateTime(2026, 9, 10), 10250),
    ];

    test('unsettled: the total is withheld, never a cross-currency sum', () {
      final stats = ConsumptionStats.fromFillUps([...history, gandria()]);
      expect(stats.totalSpent, isNull);
      expect(stats.spend.amountIn('CHF'), 51.73);
      expect(stats.spend.amountIn('EUR'), 140);
    });

    test('settled: the EUR total includes EXACTLY the amount charged', () {
      final settled = gandria().settledByCard(amount: 55.12, currency: 'EUR');
      final stats = ConsumptionStats.fromFillUps([...history, settled]);
      expect(stats.totalSpent, closeTo(140 + 55.12, 1e-9));
      expect(stats.spendCurrency, 'EUR');
    });

    test('settling never moves litres, distance or L/100 km', () {
      final a = ConsumptionStats.fromFillUps([...history, gandria()]);
      final b = ConsumptionStats.fromFillUps([
        ...history,
        gandria().settledByCard(amount: 55.12, currency: 'EUR'),
      ]);
      expect(b.totalLiters, a.totalLiters);
      expect(b.totalDistanceKm, a.totalDistanceKm);
      expect(b.avgConsumptionL100km, a.avgConsumptionL100km);
    });

    test('an EUR-only history totals exactly as before (regression)', () {
      final stats = ConsumptionStats.fromFillUps(history);
      expect(stats.totalSpent, 140);
      expect(stats.spendCurrency, 'EUR');
    });
  });

  group('MonthlySummary no longer sums across currencies (#4437 E)', () {
    test('a month holding CHF and EUR has no single cost', () {
      final months = MonthlyAggregator.byMonth([
        home('h1', DateTime(2026, 9, 1), 10000),
        gandria(),
      ]);
      expect(months.single.totalCost, isNull);
      expect(months.single.avgPricePerLiter, isNull);
      expect(months.single.spend.amountIn('CHF'), 51.73);
      // Litres and CO2 are unaffected by money.
      expect(months.single.totalLiters, closeTo(65.61, 1e-9));
      expect(MonthlyAggregator.totalCost(months), isNull);
    });

    test('settled, the month costs what the card charged', () {
      final months = MonthlyAggregator.byMonth([
        home('h1', DateTime(2026, 9, 1), 10000),
        gandria().settledByCard(amount: 55.12, currency: 'EUR'),
      ]);
      expect(months.single.totalCost, closeTo(70 + 55.12, 1e-9));
      expect(MonthlyAggregator.totalCost(months), closeTo(125.12, 1e-9));
    });

    test('an EUR history in two months totals as before', () {
      final months = MonthlyAggregator.byMonth([
        home('h1', DateTime(2026, 8, 1), 10000),
        home('h2', DateTime(2026, 9, 1), 10500, cost: 80),
      ]);
      expect(months.map((m) => m.totalCost), [70, 80]);
      expect(MonthlyAggregator.totalCost(months), 150);
    });

    test('a EUR month and a CHF month have no combined total', () {
      final months = MonthlyAggregator.byMonth([
        home('h1', DateTime(2026, 8, 1), 10000),
        gandria(),
      ]);
      expect(months.map((m) => m.totalCost), [70, 51.73]);
      expect(MonthlyAggregator.totalCost(months), isNull);
      expect(MonthlyAggregator.spend(months).currencies,
          containsAll(['EUR', 'CHF']));
    });
  });

  test('a tank window straddling a foreign fill keeps its money apart', () {
    final periods = closedTankPeriods([
      home('h1', DateTime(2026, 9, 1), 10000),
      home('h2', DateTime(2026, 9, 10), 10500),
      gandria().copyWith(odometerKm: 11000),
    ]);
    expect(periods, hasLength(2));
    final last = periods.last;
    expect(last.pumpedSpend.soleCurrency, 'CHF');
    expect(last.pumpedSpend.isSingleDenomination, isTrue);
    expect(periods.first.pumpedSpend.soleMoney, const Money(70, 'EUR'));
  });
}
