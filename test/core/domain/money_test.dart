// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/money.dart';

/// #4361 — the rate in every case below is SYNTHETIC and fixed. No live
/// FX is assumed anywhere in this suite, and the app ships no rate table:
/// what is tested is that a stated rate converts correctly in both
/// directions, and that a missing or stale one refuses rather than
/// silently becoming 1:1.
void main() {
  final captured = DateTime.utc(2026, 9, 12, 8);
  final now = DateTime.utc(2026, 9, 12, 12);

  // 7.50 DKK = €1, stated once, read both ways.
  final eurDkk = ExchangeRate(
    baseCurrency: 'EUR',
    quoteCurrency: 'DKK',
    rate: 7.5,
    source: 'test-fixture',
    capturedAt: captured,
  );
  final snapshot = ExchangeRateSnapshot(rates: [eurDkk]);

  group('conversion', () {
    test('DKK 13/L normalises to €1.733333…/L', () {
      final result = snapshot.convert(const Money(13, 'DKK'), 'EUR', now);
      expect(result.isUsable, isTrue);
      expect(result.converted!.currencyCode, 'EUR');
      expect(result.converted!.amount, closeTo(13 / 7.5, 1e-12));
      expect(result.converted!.amount, closeTo(1.7333333333, 1e-9));
      // …and it loses to €1.80/L, which the bare numbers would not say.
      expect(result.converted!.amount, lessThan(1.80));
    });

    test('the same rate converts the other direction', () {
      final result = snapshot.convert(const Money(1, 'EUR'), 'DKK', now);
      expect(result.converted, const Money(7.5, 'DKK'));
      expect(result.rate, same(eurDkk));
    });

    test('same currency needs no rate at all', () {
      // An empty snapshot: a domestic comparison must never depend on FX
      // being present.
      const empty = ExchangeRateSnapshot.empty();
      final result = empty.convert(const Money(1.8, 'EUR'), 'EUR', now);
      expect(result.isUsable, isTrue);
      expect(result.wasAlreadyInTargetCurrency, isTrue);
      expect(result.converted, const Money(1.8, 'EUR'));
    });

    test('a missing rate refuses — it never becomes 1:1', () {
      final result = snapshot.convert(const Money(13, 'SEK'), 'EUR', now);
      expect(result.converted, isNull);
      expect(result.refusal, MoneyConversionRefusal.noRate);
      // The native amount survives so the row can still be shown.
      expect(result.native, const Money(13, 'SEK'));
    });

    test('a stale rate refuses, and says which refusal it is', () {
      final late = now.add(const Duration(days: 3));
      final result = snapshot.convert(const Money(13, 'DKK'), 'EUR', late);
      expect(result.converted, isNull);
      expect(result.refusal, MoneyConversionRefusal.rateStale);
      expect(result.rate, same(eurDkk), reason: 'the stale rate is named');
    });

    test('a non-positive rate is invalid, not a conversion', () {
      final broken = ExchangeRateSnapshot(rates: [
        ExchangeRate(
          baseCurrency: 'EUR',
          quoteCurrency: 'DKK',
          rate: 0,
          source: 'test-fixture',
          capturedAt: captured,
        ),
      ]);
      final result = broken.convert(const Money(13, 'DKK'), 'EUR', now);
      expect(result.refusal, MoneyConversionRefusal.noRate,
          reason: 'an unusable rate relates nothing');
    });
  });

  group('arithmetic never crosses a currency', () {
    test('addition across currencies is null, not a number', () {
      expect(const Money(1, 'EUR') + const Money(1, 'DKK'), isNull);
      expect(const Money(1, 'EUR') + const Money(2, 'EUR'),
          const Money(3, 'EUR'));
    });

    test('sumMoney refuses a mixed list', () {
      expect(sumMoney(const [Money(1, 'EUR'), Money(1, 'DKK')]), isNull);
      expect(sumMoney(const [Money(1, 'EUR'), Money(2, 'EUR')]),
          const Money(3, 'EUR'));
      expect(sumMoney(const [], fallbackCurrency: 'EUR'),
          const Money(0, 'EUR'));
    });

    test('multiplication keeps the currency', () {
      expect(const Money(1.5, 'DKK') * 4, const Money(6, 'DKK'));
    });
  });

  group('cross-currency ordering', () {
    test('withholds an answer when either side cannot be converted', () {
      expect(
        snapshot.compareInCurrency(
            const Money(13, 'DKK'), const Money(1.8, 'SEK'), 'EUR', now),
        isNull,
      );
    });

    test('orders correctly once both convert', () {
      final order = snapshot.compareInCurrency(
          const Money(13, 'DKK'), const Money(1.8, 'EUR'), 'EUR', now);
      expect(order, lessThan(0), reason: 'DKK13/L is the cheaper litre');
    });
  });
}
