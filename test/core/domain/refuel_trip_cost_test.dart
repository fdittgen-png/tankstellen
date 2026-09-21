// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4360 — a refuelling trip conserves fuel, and money compares equal
/// tank states.
///
/// Every expected value below is worked by hand in the comment beside it,
/// independently of the code, from the issue's own fixtures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/refuel_economics.dart';
import 'package:tankstellen/core/domain/refuel_trip_cost.dart';

void main() {
  RefuelTripCost costed(RefuelTripInput input) {
    final outcome = RefuelEconomics.tripCost(input);
    expect(outcome.blocker, isNull, reason: 'expected a cost');
    return outcome.cost!;
  }

  group('fixture A — the cheaper pump loses after the drive', () {
    // Start 10 L, target 20 L after returning, capacity 40 L,
    // 10 L/100 km, no charges.
    RefuelTripInput station(double returnTripKm, double price) =>
        RefuelTripInput(
          outboundKm: returnTripKm / 2,
          returnKm: returnTripKm / 2,
          pricePerLitre: price,
          consumptionLPer100km: 10,
          quantity: const RefuelPurchaseQuantity.targetFinal(20),
          startLitres: 10,
          capacityL: 40,
        );

    RefuelTripCost a() => costed(station(2, 1.80));
    RefuelTripCost b() => costed(station(12, 1.70));

    test('A: 2 km burns 0.2 L, so 10.2 L are bought for €18.36', () {
      expect(a().consumedLitres, closeTo(0.2, 1e-9));
      expect(a().litresDispensed, closeTo(10.2, 1e-9));
      expect(a().cashAtPump, closeTo(18.36, 1e-9)); // 10.2 × 1.80
      expect(a().endLitres, closeTo(20, 1e-9));
    });

    test('B: 12 km burns 1.2 L, so 11.2 L are bought for €19.04', () {
      expect(b().consumedLitres, closeTo(1.2, 1e-9));
      expect(b().litresDispensed, closeTo(11.2, 1e-9));
      expect(b().cashAtPump, closeTo(19.04, 1e-9)); // 11.2 × 1.70
      expect(b().endLitres, closeTo(20, 1e-9));
    });

    test('for the same final tank, B costs €0.68 MORE despite its pump', () {
      expect(netSavingAtEqualEnd(b(), a()), closeTo(-0.68, 1e-9));
      expect(netSavingAtEqualEnd(a(), b()), closeTo(0.68, 1e-9));
    });

    test('the quantity keeps its meaning to the output', () {
      expect(a().quantity, const RefuelPurchaseQuantity.targetFinal(20));
      expect(a().quantity.meaning, RefuelQuantityMeaning.targetFinal);
    });

    test('the tank is conserved at every point of the sequence', () {
      // arrival = 10 − 0.1; departure = 9.9 + 10.2; end = 20.1 − 0.1.
      expect(a().arrivalLitres, closeTo(9.9, 1e-9));
      expect(a().departureLitres, closeTo(20.1, 1e-9));
      expect(a().endLitres, closeTo(20.0, 1e-9));
    });
  });

  group('purchase meanings stay distinct', () {
    RefuelTripInput trip(RefuelPurchaseQuantity q) => RefuelTripInput(
          outboundKm: 3,
          returnKm: 7, // 10 km, not 6: the return leg is its own leg
          pricePerLitre: 2,
          consumptionLPer100km: 10,
          quantity: q,
          startLitres: 10,
          capacityL: 50,
        );

    test('actual litres are never reinterpreted', () {
      final c = costed(trip(const RefuelPurchaseQuantity.dispensed(30)));
      expect(c.litresDispensed, 30);
      expect(c.cashAtPump, 60);
      // 10 − 0.3 + 30 − 0.7
      expect(c.endLitres, closeTo(39, 1e-9));
    });

    test('a net increase adds the fuel the trip burns', () {
      final c = costed(trip(const RefuelPurchaseQuantity.netIncrease(30)));
      expect(c.consumedLitres, closeTo(1.0, 1e-9)); // 10 km at 10 L/100
      expect(c.litresDispensed, closeTo(31, 1e-9));
      expect(c.endLitres, closeTo(40, 1e-9));
    });

    test('different end states refuse a cash "saving"', () {
      final actual = costed(trip(const RefuelPurchaseQuantity.dispensed(30)));
      final net = costed(trip(const RefuelPurchaseQuantity.netIncrease(30)));
      expect(netSavingAtEqualEnd(actual, net), isNull);
    });
  });

  group('fixture C — no purchase still consumes', () {
    test('a zero-litre errand burns fuel and pays nothing', () {
      final c = costed(const RefuelTripInput(
        outboundKm: 20,
        returnKm: 20,
        pricePerLitre: 1.9,
        consumptionLPer100km: 5,
        quantity: RefuelPurchaseQuantity.dispensed(0),
        startLitres: 30,
      ));
      expect(c.cashAtPump, 0);
      expect(c.consumedLitres, closeTo(2, 1e-9)); // 40 km × 5 / 100
      expect(c.endLitres, closeTo(28, 1e-9));
      expect(c.consumedValue, isA<Unknown<double>>(),
          reason: 'the opening tank price is unknown — no invented cost');
    });

    test('with an opening price the consumption is valued, not charged', () {
      final c = costed(const RefuelTripInput(
        outboundKm: 20,
        returnKm: 20,
        pricePerLitre: 1.9,
        consumptionLPer100km: 5,
        quantity: RefuelPurchaseQuantity.dispensed(0),
        startLitres: 30,
        openingPricePerLitre: 1.5,
      ));
      // outbound 1 L × 1.5 + return 1 L × 1.9
      expect((c.consumedValue as Estimated<double>).value,
          closeTo(3.4, 1e-9));
      expect(c.cashAtPump, 0);
    });
  });

  test('display rounding cannot change the winner', () {
    // €1.799 vs €1.800 at 40 L net refill, same 2 km: totals differ by
    // €0.04 before rounding and read the same at €/L display precision
    // (1,80). The ranking uses the unrounded value, so 'a' wins — and it
    // keeps winning when the list order is reversed.
    const profile = RefuelProfile(consumptionLPer100km: 7, litresIntended: 40);
    const a = RefuelCandidate(stationId: 'b-a', oneWayKm: 1, pricePerLitre: 1.799);
    const b = RefuelCandidate(stationId: 'a-b', oneWayKm: 1, pricePerLitre: 1.800);
    for (final order in [
      [a, b],
      [b, a],
    ]) {
      final d = RefuelEconomics.decide(order, profile);
      expect(d.bestValue!.candidate.stationId, 'b-a');
      expect(d.cheapest!.candidate.stationId, 'b-a');
    }
  });

  group('invalid inputs fail explicitly', () {
    RefuelTripBlocker? blockerOf(RefuelTripInput i) =>
        RefuelEconomics.tripCost(i).blocker;

    const ok = RefuelTripInput(
      outboundKm: 1,
      returnKm: 1,
      pricePerLitre: 1.8,
      consumptionLPer100km: 7,
      quantity: RefuelPurchaseQuantity.netIncrease(30),
    );

    test('NaN, infinite and negative inputs', () {
      for (final bad in [double.nan, double.infinity, -1.0]) {
        expect(
            blockerOf(RefuelTripInput(
                outboundKm: bad,
                returnKm: 1,
                pricePerLitre: 1.8,
                consumptionLPer100km: 7,
                quantity: const RefuelPurchaseQuantity.netIncrease(30))),
            RefuelTripBlocker.invalidInput,
            reason: 'distance $bad');
        expect(
            blockerOf(RefuelTripInput(
                outboundKm: 1,
                returnKm: 1,
                pricePerLitre: bad,
                consumptionLPer100km: 7,
                quantity: const RefuelPurchaseQuantity.netIncrease(30))),
            bad == -1.0
                ? RefuelTripBlocker.noPrice
                : RefuelTripBlocker.invalidInput,
            reason: 'price $bad');
      }
      expect(blockerOf(ok), isNull);
    });

    test('no price, no consumption, a reference point', () {
      expect(
          blockerOf(const RefuelTripInput(
              outboundKm: 1,
              returnKm: 1,
              pricePerLitre: null,
              consumptionLPer100km: 7,
              quantity: RefuelPurchaseQuantity.netIncrease(30))),
          RefuelTripBlocker.noPrice);
      expect(
          blockerOf(const RefuelTripInput(
              outboundKm: 1,
              returnKm: 1,
              pricePerLitre: 1.8,
              consumptionLPer100km: 0,
              quantity: RefuelPurchaseQuantity.netIncrease(30))),
          RefuelTripBlocker.noConsumption);
      expect(
          blockerOf(const RefuelTripInput(
              outboundKm: 1,
              returnKm: 1,
              pricePerLitre: 1.8,
              consumptionLPer100km: 7,
              isPhysicalStation: false,
              quantity: RefuelPurchaseQuantity.netIncrease(30))),
          RefuelTripBlocker.notAStation);
    });

    test('a target without a start, an overflow, an unreachable station', () {
      expect(
          blockerOf(const RefuelTripInput(
              outboundKm: 1,
              returnKm: 1,
              pricePerLitre: 1.8,
              consumptionLPer100km: 7,
              quantity: RefuelPurchaseQuantity.targetFinal(30))),
          RefuelTripBlocker.unknownStartLevel);
      expect(
          blockerOf(const RefuelTripInput(
              outboundKm: 1,
              returnKm: 1,
              pricePerLitre: 1.8,
              consumptionLPer100km: 7,
              startLitres: 30,
              capacityL: 40,
              quantity: RefuelPurchaseQuantity.dispensed(20))),
          RefuelTripBlocker.exceedsCapacity);
      expect(
          blockerOf(const RefuelTripInput(
              outboundKm: 100,
              returnKm: 100,
              pricePerLitre: 1.8,
              consumptionLPer100km: 7,
              startLitres: 3,
              quantity: RefuelPurchaseQuantity.netIncrease(20))),
          RefuelTripBlocker.cannotReachStation);
    });
  });
}
