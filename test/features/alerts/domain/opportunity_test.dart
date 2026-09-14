// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_detectors.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_scorer.dart';
import 'package:tankstellen/features/alerts/domain/station_price_sample.dart';
import 'package:tankstellen/features/alerts/domain/velocity_alert_detector.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';

/// #4149 — one shape for every reason to interrupt someone.
///
/// This is the surface that wakes a user who did not ask, so the rules
/// it has to keep are stricter than a list's: every saving reproducible
/// from what is shown, nothing ranked on money it does not have, and
/// nothing delivered after its reason stopped being true.
void main() {
  final now = DateTime.utc(2026, 9, 14, 12);

  Opportunity build({
    OpportunityKind kind = OpportunityKind.exceptionalLocalPrice,
    String? stationId = 's',
    double currentPrice = 1.60,
    double? gross,
    double? detour,
    double? net,
    double distanceKm = 3,
    DataValue<Duration> priceAge = const DataValue.measured(Duration(hours: 1)),
    DataConfidence confidence = DataConfidence.high,
    Duration lifetime = kOpportunityLifetime,
  }) =>
      Opportunity(
        kind: kind,
        stationId: stationId,
        fuelType: FuelType.e10.apiValue,
        currentPrice: currentPrice,
        reference: OpportunityReference.thresholdYouSet,
        referencePrice: 1.70,
        grossSaving: gross,
        detourCost: detour,
        netSaving: net,
        distanceKm: distanceKm,
        priceAge: priceAge,
        confidence: confidence,
        detectedAt: now,
        expiresAt: now.add(lifetime),
      );

  group('trust rule 4 — every saving is reproducible from what is shown',
      () {
    test('net equals gross minus detour, or the claim is refused', () {
      expect(build(gross: 4.0, detour: 1.0, net: 3.0).savingIsReproducible,
          isTrue);
      expect(build(gross: 4.0, detour: 1.0, net: 3.9).savingIsReproducible,
          isFalse,
          reason: 'a net figure that does not equal the difference of the '
              'two figures beside it is exactly the number nobody can '
              'check');
    });

    test('an unpriced opportunity is consistent, not broken', () {
      // All three absent is a legitimate state: the velocity detector
      // knows a drop happened and cannot know what it is worth.
      expect(build().savingIsReproducible, isTrue);
    });

    test('a partially priced one is NOT', () {
      expect(build(gross: 4.0).savingIsReproducible, isFalse);
      expect(build(gross: 4.0, detour: 1.0).savingIsReproducible, isFalse);
    });

    test('the scorer refuses an unverifiable claim outright', () {
      expect(OpportunityScorer.refuse(build(gross: 4, detour: 1, net: 9), now),
          OpportunityRefusal.savingNotReproducible);
    });

    test('Money cannot be constructed inconsistently', () {
      // The three figures are one type precisely so a caller cannot
      // supply a net that disagrees with the other two.
      final m = Money(gross: 4.0, detour: 1.5);
      expect(m.net, closeTo(2.5, 1e-9));
    });
  });

  group('nothing is ranked on money it does not have', () {
    test('an unpriceable opportunity sorts behind every priced one', () {
      final priced = build(stationId: 'p', gross: 1, detour: 0.5, net: 0.5);
      final unpriced = build(stationId: 'u');
      final ranked = OpportunityScorer.rank([unpriced, priced], now);
      expect(ranked.map((o) => o.stationId), ['p', 'u']);
    });

    test('even a tiny saving beats an unpriceable one', () {
      // Not because it is better, but because it is the only one of the
      // two we can actually argue for.
      final tiny = build(stationId: 'p', gross: 0.02, detour: 0.01, net: 0.01);
      final unpriced = build(stationId: 'u', distanceKm: 0.1);
      expect(OpportunityScorer.rank([unpriced, tiny], now).first.stationId,
          'p');
    });

    test('unpriceable ones order by the only fact they still carry', () {
      final near = build(stationId: 'near', distanceKm: 1);
      final far = build(stationId: 'far', distanceKm: 9);
      expect(OpportunityScorer.rank([far, near], now).map((o) => o.stationId),
          ['near', 'far']);
    });

    test('priced ones order by net saving, not by gross', () {
      // The one that looks better before the detour is not the one worth
      // driving to.
      final showy = build(stationId: 'showy', gross: 5, detour: 4.5, net: 0.5);
      final real = build(stationId: 'real', gross: 3, detour: 0.2, net: 2.8);
      expect(
          OpportunityScorer.rank([showy, real], now).first.stationId, 'real');
    });

    test('ties break stably, so the same inputs never reorder', () {
      final a = build(stationId: 'a', gross: 2, detour: 1, net: 1);
      final b = build(stationId: 'b', gross: 2, detour: 1, net: 1);
      expect(OpportunityScorer.rank([b, a], now).map((o) => o.stationId),
          ['a', 'b']);
    });
  });

  group('expiry is honoured, not merely recorded', () {
    test('a stale opportunity is dropped rather than fired late', () {
      final o = build(gross: 2, detour: 1, net: 1);
      final later = now.add(kOpportunityLifetime + const Duration(minutes: 1));
      expect(OpportunityScorer.refuse(o, later), OpportunityRefusal.expired);
      expect(OpportunityScorer.rank([o], later), isEmpty);
    });

    test('expiry is inclusive at the boundary', () {
      final o = build();
      expect(o.isExpiredAt(now.add(kOpportunityLifetime)), isTrue);
      expect(
          o.isExpiredAt(
              now.add(kOpportunityLifetime - const Duration(seconds: 1))),
          isFalse);
    });
  });

  group('the provider gates, and #4156 decides which gates apply', () {
    test('a provider with no prices is never an opportunity', () {
      expect(
        OpportunityScorer.refuse(build(confidence: DataConfidence.none), now),
        OpportunityRefusal.noProviderConfidence,
      );
    });

    test('a price older than a day is refused', () {
      expect(
        OpportunityScorer.refuse(
            build(priceAge: const DataValue.measured(Duration(hours: 30))),
            now),
        OpportunityRefusal.stalePrice,
      );
    });

    test('a provider that STAMPS no prices does not fail the freshness gate',
        () {
      // Nine of seventeen providers stamp nothing. Refusing every
      // opportunity in those countries because we cannot date a price
      // would be reading "unknown" as "stale" — the exact bug #4156
      // fixed in confidentPick.
      expect(
        OpportunityScorer.refuse(
          build(
            priceAge: const DataValue.unknown(
                reason: DataUnknownReason.notPublishedByProvider),
          ),
          now,
        ),
        isNull,
      );
    });

    test('nor does a provider that stamps prices and left THIS one blank',
        () {
      // A deliberate DIVERGENCE from `confidentPick`, and worth stating.
      // There, an undated row withholds the lead, because leading is the
      // app volunteering one answer over two others. Here the user
      // configured this alert and asked to be told; suppressing it
      // because we cannot date the price would answer a question they
      // did not ask with silence. The gap travels on the opportunity and
      // reaches the notification as a caveat instead.
      expect(
        OpportunityScorer.refuse(
          build(
            priceAge: const DataValue.unknown(
                reason: DataUnknownReason.notPublishedForThisItem),
          ),
          now,
        ),
        isNull,
      );
    });
  });

  group('the three existing kinds emit it', () {
    const priceAge = DataValue.measured(Duration(minutes: 20));

    test('a station+threshold alert names the user own number', () {
      final o = opportunityFromPriceAlert(
        alert: PriceAlert(
          id: 'a',
          stationId: 'de-1',
          stationName: 'Aral Mitte',
          fuelType: FuelType.e10,
          targetPrice: 1.70,
          createdAt: now,
        ),
        currentPrice: 1.64,
        distanceKm: 2,
        priceAge: priceAge,
        confidence: DataConfidence.high,
        now: now,
        money: Money(gross: 2.4, detour: 0.4),
      );
      expect(o.kind, OpportunityKind.favouriteStation);
      expect(o.reference, OpportunityReference.thresholdYouSet);
      expect(o.referencePrice, 1.70);
      expect(o.stationName, 'Aral Mitte');
      expect(o.netSaving, closeTo(2.0, 1e-9));
      expect(o.savingIsReproducible, isTrue);
      expect(OpportunityScorer.isEligible(o, now), isTrue);
    });

    test('a radius match keeps the station it is about', () {
      final o = opportunityFromRadiusMatch(
        alert: RadiusAlert(
          id: 'r',
          fuelType: FuelType.e10.apiValue,
          threshold: 1.70,
          centerLat: 48,
          centerLng: 2,
          radiusKm: 10,
          label: 'Home',
          createdAt: now,
        ),
        sample: StationPriceSample(
          stationId: 'fr-9',
          name: 'Total Nord',
          fuelType: FuelType.e10.apiValue,
          pricePerLiter: 1.61,
          lat: 48.01,
          lng: 2.01,
        ),
        distanceKm: 1.2,
        priceAge: priceAge,
        confidence: DataConfidence.high,
        now: now,
        money: Money(gross: 3.6, detour: 0.3),
      );
      expect(o.stationId, 'fr-9');
      expect(o.currentPrice, 1.61);
      expect(o.netSaving, closeTo(3.3, 1e-9));
    });

    test('a velocity event is about an AREA and carries no money', () {
      // A drop of N cents is not a saving until someone says how many
      // litres and how far. The detector knows neither, so it must not
      // pretend — and the scorer must not rank it as though it did.
      final o = opportunityFromVelocityEvent(
        event: const VelocityAlertEvent(
          fuelType: FuelType.e10,
          affectedStationIds: ['a', 'b', 'c'],
          maxDropCents: 7,
        ),
        priceAge: priceAge,
        confidence: DataConfidence.high,
        now: now,
        referencePrice: 1.72,
        currentPrice: 1.65,
      );
      expect(o.kind, OpportunityKind.localMovement);
      expect(o.stationId, isNull);
      expect(o.isPriceable, isFalse);
      expect(o.savingIsReproducible, isTrue);
      expect(OpportunityScorer.isEligible(o, now), isTrue,
          reason: 'unpriceable is not ineligible — it is merely not '
              'rankable on money');
    });

    test('all three survive one ranking together', () {
      // The point of the model: three reasons that used to be three
      // incomparable shapes now sort against each other.
      final ranked = OpportunityScorer.rank([
        build(stationId: 'movement'),
        build(stationId: 'big', gross: 5, detour: 1, net: 4),
        build(stationId: 'small', gross: 2, detour: 1, net: 1),
      ], now);
      expect(ranked.map((o) => o.stationId), ['big', 'small', 'movement']);
    });
  });
}
