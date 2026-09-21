// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/money.dart';
import 'package:tankstellen/core/domain/money_tally.dart';

/// #4364 acceptance box 1 + 2, at the arithmetic layer: the canonical
/// currency-segregating accumulator.
void main() {
  final asOf = DateTime.utc(2026, 9, 20, 12);
  ExchangeRateSnapshot ratesAt(DateTime captured, {double rate = 7.50}) =>
      ExchangeRateSnapshot(rates: [
        ExchangeRate(
          baseCurrency: 'EUR',
          quoteCurrency: 'DKK',
          rate: rate,
          source: 'synthetic test rate',
          capturedAt: captured,
        ),
      ]);

  group('segregation', () {
    test('€30 and DKK 225 stay separately denominated — never 255', () {
      final tally = MoneyTally.of([(30.0, 'EUR'), (225.0, 'DKK')]);

      expect(tally.amountIn('EUR'), 30);
      expect(tally.amountIn('DKK'), 225);
      expect(tally.isSingleDenomination, isFalse);
      // The defect this type exists to prevent: one naive number.
      expect(tally.soleAmount, isNull);
      expect(tally.byCurrency.values, isNot(contains(255)));
    });

    test('under a synthetic 7.50 DKK/EUR rate the comparable sum is €60', () {
      final tally = MoneyTally.of([(30.0, 'EUR'), (225.0, 'DKK')]);

      final combined = tally.combine(
          target: 'EUR', rates: ratesAt(asOf), asOf: asOf);

      expect(combined.isAvailable, isTrue);
      expect(combined.total!.currencyCode, 'EUR');
      expect(combined.total!.amount, closeTo(60, 1e-9));
      expect(combined.total!.amount, isNot(closeTo(255, 1)));
    });

    test('every converted part carries the rate that moved it', () {
      final tally = MoneyTally.of([(30.0, 'EUR'), (225.0, 'DKK')]);

      final combined = tally.combine(
          target: 'EUR', rates: ratesAt(asOf), asOf: asOf);
      final dkk = combined.parts.firstWhere((p) => p.native.currencyCode == 'DKK');

      expect(dkk.rate!.source, 'synthetic test rate');
      expect(dkk.rate!.capturedAt, asOf);
      expect(dkk.rate!.rate, 7.50);
      expect(dkk.native.amount, 225);
    });

    test('a stale rate withholds the combined total, keeps the natives', () {
      final tally = MoneyTally.of([(30.0, 'EUR'), (225.0, 'DKK')]);

      final combined = tally.combine(
        target: 'EUR',
        rates: ratesAt(asOf.subtract(const Duration(days: 5))),
        asOf: asOf,
      );

      expect(combined.isAvailable, isFalse);
      expect(combined.refusal, MoneyConversionRefusal.rateStale);
      expect(combined.parts.map((p) => p.native.amount), containsAll([30, 225]));
    });

    test('no rate at all refuses rather than assuming 1:1', () {
      final tally = MoneyTally.of([(30.0, 'EUR'), (225.0, 'DKK')]);

      final combined = tally.combine(
          target: 'EUR', rates: const ExchangeRateSnapshot.empty(), asOf: asOf);

      expect(combined.isAvailable, isFalse);
      expect(combined.refusal, MoneyConversionRefusal.noRate);
    });
  });

  group('unknown stays unknown', () {
    test('a null currency lands in its own bucket, not the active one', () {
      final tally = MoneyTally.of([(30.0, null), (12.0, null)]);

      expect(tally.currencies, [kUnknownCurrency]);
      expect(tally.hasUnknownCurrency, isTrue);
      // All-unknown is still ONE denomination: the driver who never left
      // home and logged before the field existed keeps their total.
      expect(tally.isSingleDenomination, isTrue);
      expect(tally.soleAmount, 42);
      // ...but it can never be named, so it cannot enter a euro figure.
      expect(tally.soleMoney, isNull);
    });

    test('unknown mixed with a named currency has no single total', () {
      final tally = MoneyTally.of([(30.0, 'EUR'), (12.0, null)]);

      expect(tally.isSingleDenomination, isFalse);
      expect(tally.soleAmount, isNull);
      expect(tally.unknownEntryCount, 1);
    });

    test('an unknown-currency amount blocks a conversion outright', () {
      final tally = MoneyTally.of([(30.0, 'EUR'), (12.0, null)]);

      final combined = tally.combine(
          target: 'EUR', rates: ratesAt(asOf), asOf: asOf);

      expect(combined.isAvailable, isFalse);
      expect(combined.unknownCurrencyEntryCount, 1);
    });

    test('case is not a denomination: eur and EUR are one bucket', () {
      final tally = MoneyTally.of([(10.0, 'eur'), (5.0, 'EUR')]);

      expect(tally.currencies, ['EUR']);
      expect(tally.soleAmount, 15);
    });
  });

  group('valuation policy', () {
    test('carries target, rule and a dated sourced rate', () {
      final policy = MoneyValuationPolicy(
        targetCurrency: 'EUR',
        rates: ratesAt(asOf),
        asOf: asOf,
      );

      final out = policy.apply(MoneyTally.of([(225.0, 'DKK')]));

      expect(policy.rule, MoneyValuationRule.reportDateRate);
      expect(out.total, const Money(30, 'EUR'));
      expect(out.parts.single.rate!.source, 'synthetic test rate');
    });
  });

  test('an empty tally totals zero, a mixed one totals nothing', () {
    expect(MoneyTally.empty.soleAmount, 0);
    expect(MoneyTally.empty.isEmpty, isTrue);
    expect(MoneyTally.of([(1.0, 'EUR'), (1.0, 'GBP')]).soleAmount, isNull);
  });

  test('value equality so it can sit inside a freezed model', () {
    expect(MoneyTally.of([(1.0, 'EUR')]), MoneyTally.of([(1.0, 'EUR')]));
    expect(MoneyTally.of([(1.0, 'EUR')]).hashCode,
        MoneyTally.of([(1.0, 'EUR')]).hashCode);
    expect(MoneyTally.of([(1.0, 'EUR')]) == MoneyTally.of([(1.0, 'DKK')]),
        isFalse);
  });
}
