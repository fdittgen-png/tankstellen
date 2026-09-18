// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel_offer.dart';
import 'package:tankstellen/core/domain/money.dart';

/// #4361 — what makes two fuel prices comparable, and what makes them
/// not comparable at all.
void main() {
  group('unit scale', () {
    test('a pence-per-litre figure becomes pounds per litre', () {
      // 155.9 p/L is the UK forecourt convention; £1.559/L is the number
      // an arithmetic layer may use. The two must never meet.
      final quote = FuelPriceQuote.fromSubUnit(155.9, currencyCode: 'GBP');
      expect(quote.amountPerLitre, closeTo(1.559, 1e-12));
      expect(quote.perLitre.currencyCode, 'GBP');
      expect(quote.perLitre.amount, closeTo(1.559, 1e-12));
    });

    test('a per-gallon price is normalised to litres on the way in', () {
      final quote = FuelPriceQuote.perUnit(3.785411784,
          currencyCode: 'USD', volumeUnit: FuelVolumeUnit.usGallon);
      expect(quote.amountPerLitre, closeTo(1, 1e-12));
    });

    test('a quote knows its own currency, never a symbol', () {
      const quote = FuelPriceQuote(amountPerLitre: 1.8, currencyCode: 'EUR');
      expect(quote.currencyCode, 'EUR');
      expect(quote.cost(10), const Money(18, 'EUR'));
    });
  });

  group('cheaper per litre is not cheaper per kilometre', () {
    // #4361's acceptance case, for a vehicle approved for both.
    const e85 = FuelOffer(
      stationId: 'flex',
      grade: FuelGrade.e85,
      quote: FuelPriceQuote(amountPerLitre: 1.30, currencyCode: 'EUR'),
      consumptionLPer100km: 9,
      consumptionIsEstimated: true,
    );
    const e10 = FuelOffer(
      stationId: 'flex',
      grade: FuelGrade.e10,
      quote: FuelPriceQuote(amountPerLitre: 1.60, currencyCode: 'EUR'),
      consumptionLPer100km: 7,
      consumptionIsEstimated: true,
    );

    test('E85 costs €11.70/100 km and E10 €11.20/100 km', () {
      expect(e85.costPer100Km!.amount, closeTo(11.70, 1e-9));
      expect(e10.costPer100Km!.amount, closeTo(11.20, 1e-9));
    });

    test('the cheaper litre loses over the distance', () {
      expect(e85.quote.amountPerLitre, lessThan(e10.quote.amountPerLitre));
      expect(e10.costPer100Km!.amount, lessThan(e85.costPer100Km!.amount));
      final winner = cheapestOverDistance([e85, e10], 100,
          target: 'EUR',
          rates: const ExchangeRateSnapshot.empty(),
          now: DateTime.utc(2026));
      expect(winner!.grade, FuelGrade.e10);
    });

    test('both figures stay estimated', () {
      expect(e85.consumptionIsEstimated, isTrue);
      expect(e10.consumptionIsEstimated, isTrue);
    });

    test('no per-grade consumption means no distance comparison', () {
      const unmeasured = FuelOffer(
        stationId: 'x',
        grade: FuelGrade.e10,
        quote: FuelPriceQuote(amountPerLitre: 1.6, currencyCode: 'EUR'),
      );
      expect(unmeasured.costPer100Km, isNull);
      expect(
        cheapestOverDistance([e10, unmeasured], 100,
            target: 'EUR',
            rates: const ExchangeRateSnapshot.empty(),
            now: DateTime.utc(2026)),
        isNull,
        reason: 'a winner over a candidate that could not be costed is a '
            'winner over a shorter list',
      );
    });

    test('an unconvertible competitor withholds the winner', () {
      const danish = FuelOffer(
        stationId: 'dk',
        grade: FuelGrade.e10,
        quote: FuelPriceQuote(amountPerLitre: 13, currencyCode: 'DKK'),
        consumptionLPer100km: 7,
      );
      expect(
        cheapestOverDistance([e10, danish], 100,
            target: 'EUR',
            rates: const ExchangeRateSnapshot.empty(),
            now: DateTime.utc(2026)),
        isNull,
      );
    });
  });

  group('approval — a price existing is not an approval', () {
    VehicleFuelCapability capability(List<FuelGrade> grades) =>
        VehicleFuelCapability(approvedGrades: grades, provenance: 'test');

    test('diesel is never offered to a petrol car', () {
      expect(
        fuelOfferApproval(FuelGrade.diesel,
            capability: capability([FuelGrade.e10])),
        FuelOfferApproval.incompatible,
      );
    });

    test('E85 is not a petrol grade for an E10 car', () {
      expect(
        fuelOfferApproval(FuelGrade.e85,
            capability: capability([FuelGrade.e5, FuelGrade.e10])),
        FuelOfferApproval.incompatible,
      );
    });

    test('E85 is approved for a flex-fuel car', () {
      expect(
        fuelOfferApproval(FuelGrade.e85,
            capability: capability(
                [FuelGrade.e5, FuelGrade.e10, FuelGrade.e98, FuelGrade.e85])),
        FuelOfferApproval.approved,
      );
    });

    test('an unapproved sibling petrol grade is not confirmed, not refused',
        () {
      expect(
        fuelOfferApproval(FuelGrade.e98,
            capability: capability([FuelGrade.e10])),
        FuelOfferApproval.notConfirmed,
      );
    });

    test('LPG is its own class', () {
      expect(
        fuelOfferApproval(FuelGrade.lpg,
            capability: capability([FuelGrade.e10])),
        FuelOfferApproval.incompatible,
      );
      expect(
        fuelOfferApproval(FuelGrade.e10,
            capability: capability([FuelGrade.lpg])),
        FuelOfferApproval.incompatible,
      );
    });

    test('diesel premium and diesel are one class', () {
      expect(
        fuelOfferApproval(FuelGrade.dieselPremium,
            capability: capability([FuelGrade.diesel])),
        FuelOfferApproval.notConfirmed,
      );
    });

    test('a configured fuel alone never produces an approval', () {
      expect(
        fuelOfferApproval(FuelGrade.e10, configured: FuelGrade.e10),
        FuelOfferApproval.notConfirmed,
        reason: 'profile fuel fallback is not proof of compatibility',
      );
      expect(
        fuelOfferApproval(FuelGrade.diesel, configured: FuelGrade.e10),
        FuelOfferApproval.incompatible,
      );
    });

    test('an unknown vehicle approves nothing', () {
      expect(fuelOfferApproval(FuelGrade.e10),
          FuelOfferApproval.vehicleUnknown);
      expect(
        fuelOfferApproval(FuelGrade.e10,
            capability: const VehicleFuelCapability.unknown()),
        FuelOfferApproval.vehicleUnknown,
      );
    });
  });
}
