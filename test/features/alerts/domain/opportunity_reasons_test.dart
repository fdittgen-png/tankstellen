// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_confidence.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_reasons.dart';
import 'package:tankstellen/features/alerts/presentation/opportunity_reason_text.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #4152 — every alert explains itself and carries a confidence.
///
/// Two promises. The user can tell WHY an alert appeared, from facts
/// that are already on the model rather than a sentence someone wrote at
/// the notification site. And the app can tell how far to trust its own
/// input, as a band derived from named tiers rather than a number that
/// implies a precision the inputs do not have.
void main() {
  _velocityReferenceTests();
  final now = DateTime.utc(2026, 9, 14, 12);

  Opportunity op({
    double? net = 3.0,
    double currentPrice = 1.60,
    double? referencePrice = 1.70,
    OpportunityReference reference = OpportunityReference.thresholdYouSet,
    double distanceKm = 2.4,
    DataValue<Duration> priceAge =
        const DataValue.measured(Duration(minutes: 30)),
    DataConfidence confidence = DataConfidence.high,
  }) =>
      Opportunity(
        kind: OpportunityKind.exceptionalLocalPrice,
        stationId: 's',
        fuelType: 'e10',
        currentPrice: currentPrice,
        reference: reference,
        referencePrice: referencePrice,
        grossSaving: net == null ? null : net + 0.5,
        detourCost: net == null ? null : 0.5,
        netSaving: net,
        distanceKm: distanceKm,
        priceAge: priceAge,
        confidence: confidence,
        detectedAt: now,
        expiresAt: now.add(const Duration(hours: 6)),
      );

  group('reasons are data, and every line traces to a field', () {
    test('a full opportunity explains itself in reading order', () {
      // What it saves, how it compares, what it costs to get there, and
      // only then the caveats. Leading with freshness would open every
      // alert with a hedge.
      final reasons = OpportunityReasons.of(op());
      expect(reasons.map((r) => r.runtimeType.toString()), [
        'NetSavingReason',
        'BelowReferenceReason',
        'DistanceReason',
        'PriceAgeReason',
      ]);
    });

    test('a reason with no data is ABSENT, never an empty bullet', () {
      final reasons = OpportunityReasons.of(
        op(net: null, referencePrice: null, distanceKm: 0),
      );
      expect(reasons.whereType<NetSavingReason>(), isEmpty);
      expect(reasons.whereType<BelowReferenceReason>(), isEmpty);
      expect(reasons.whereType<DistanceReason>(), isEmpty);
    });

    test('a reference ABOVE the current price is not a "below" line', () {
      // A threshold the price has not actually beaten would render as a
      // negative saving dressed as a positive one.
      expect(
        OpportunityReasons.of(op(currentPrice: 1.80, referencePrice: 1.70))
            .whereType<BelowReferenceReason>(),
        isEmpty,
      );
    });

    test('a provider that stamps nothing SAYS so, rather than going '
        'silent', () {
      // Trust rule 1: a missing input is stated, never defaulted.
      final reasons = OpportunityReasons.of(op(
        priceAge: const DataValue.unknown(
            reason: DataUnknownReason.notPublishedByProvider),
      ));
      expect(reasons.whereType<PriceAgeUnknownReason>(), hasLength(1));
    });

    test('a single missing stamp says nothing at all', () {
      // The provider DOES publish timestamps and left this row blank.
      // "Age unknown" would blame the source for a one-row gap.
      final reasons = OpportunityReasons.of(op(
        priceAge: const DataValue.unknown(
            reason: DataUnknownReason.notPublishedForThisItem),
      ));
      expect(reasons.whereType<PriceAgeUnknownReason>(), isEmpty);
      expect(reasons.whereType<PriceAgeReason>(), isEmpty);
    });

    test('a good source says nothing about itself', () {
      // A line asserting everything is fine is noise that trains the
      // reader to skip the list.
      expect(
        OpportunityReasons.of(op(confidence: DataConfidence.high))
            .whereType<ProviderConfidenceReason>(),
        isEmpty,
      );
      expect(
        OpportunityReasons.of(op(confidence: DataConfidence.medium))
            .whereType<ProviderConfidenceReason>(),
        hasLength(1),
      );
    });
  });

  group('the confidence band is derived from named tiers', () {
    ConfidenceInputs inputs({
      DataConfidence provider = DataConfidence.high,
      DataValue<Duration> age =
          const DataValue.measured(Duration(minutes: 30)),
      bool money = true,
      bool estimated = false,
      bool road = true,
    }) =>
        ConfidenceInputs(
          provider: provider,
          priceAge: age,
          moneyClaimed: money,
          consumptionIsEstimated: estimated,
          distanceIsRoad: road,
        );

    test('each tier stands on its own', () {
      expect(inputs().providerTier, AlertConfidence.high);
      expect(inputs(provider: DataConfidence.medium).providerTier,
          AlertConfidence.medium);
      expect(inputs(provider: DataConfidence.low).providerTier,
          AlertConfidence.low);
      expect(inputs(provider: DataConfidence.none).providerTier,
          AlertConfidence.low);

      expect(inputs().freshnessTier, AlertConfidence.high);
      expect(
          inputs(age: const DataValue.measured(Duration(hours: 9)))
              .freshnessTier,
          AlertConfidence.medium);

      expect(inputs(estimated: true).consumptionTier,
          AlertConfidence.medium);
      expect(inputs(road: false).distanceTier, AlertConfidence.medium);
    });

    test('the band is the WEAKEST tier — no weights, no blend', () {
      expect(OpportunityConfidence.of(inputs()), AlertConfidence.high);
      expect(
        OpportunityConfidence.of(inputs(provider: DataConfidence.low)),
        AlertConfidence.low,
      );
      expect(
        OpportunityConfidence.of(inputs(estimated: true)),
        AlertConfidence.medium,
      );
    });

    test('an unknown price age HEDGES, it does not sink the band', () {
      // Nine of seventeen providers stamp no prices. Treating that as
      // staleness would make every alert in those countries
      // low-confidence forever — the "unknown read as no" bug #4156
      // fixed elsewhere.
      final band = OpportunityConfidence.of(inputs(
        age: const DataValue.unknown(
            reason: DataUnknownReason.notPublishedByProvider),
      ));
      expect(band, AlertConfidence.medium);
      expect(OpportunityConfidence.mayNotify(band), isTrue);
    });

    test('consumption and distance only weaken a MONEY claim', () {
      // The correction that matters: a pure price threshold — "diesel is
      // below the number you set at your own station" — does not rest on
      // consumption or on a road distance. Letting them hedge it would
      // have made every alert in the app read "potential saving".
      final priceOnly = inputs(money: false, estimated: true, road: false);
      expect(priceOnly.consumptionTier, AlertConfidence.high);
      expect(priceOnly.distanceTier, AlertConfidence.high);
      expect(OpportunityConfidence.of(priceOnly), AlertConfidence.high);
    });

    test('low confidence may not interrupt, but is not discarded', () {
      expect(OpportunityConfidence.mayNotify(AlertConfidence.low), isFalse);
      expect(OpportunityConfidence.mayNotify(AlertConfidence.medium), isTrue);
      expect(OpportunityConfidence.mayNotify(AlertConfidence.high), isTrue);
    });

    test('an opportunity supplies what it knows and nothing it does not',
        () {
      // Consumption provenance and distance quality belong to the
      // profile and the routing, so they are NOT defaulted favourably.
      final derived = OpportunityConfidence.inputsFor(op());
      expect(derived.provider, DataConfidence.high);
      expect(derived.moneyClaimed, isTrue);
      expect(derived.distanceIsRoad, isFalse);
    });
  });

  group('the UI renders; it never composes', () {
    late AppLocalizations en;
    late AppLocalizations de;

    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      de = await AppLocalizations.delegate.load(const Locale('de'));
    });

    test('every reason variant renders, in both languages', () {
      final variants = <OpportunityReason>[
        const NetSavingReason(4.30),
        for (final r in OpportunityReference.values)
          BelowReferenceReason(perLitreDelta: 0.09, reference: r),
        const DistanceReason(2.8),
        const PriceAgeReason(Duration(minutes: 7)),
        const PriceAgeUnknownReason(),
        const ProviderConfidenceReason(DataConfidence.medium),
        const ProviderConfidenceReason(DataConfidence.low),
      ];
      for (final v in variants) {
        final text = opportunityReasonText(en, v);
        expect(text, isNotEmpty, reason: '$v');
        expect(opportunityReasonText(de, v), isNot(text),
            reason: '$v reads the same in German — it is a literal, not '
                'an ARB key');
      }
    });

    test('the whole list renders with no empty lines', () {
      final lines = opportunityReasonLines(en, op());
      expect(lines, hasLength(4));
      expect(lines.any((s) => s.trim().isEmpty), isFalse);
    });

    test('only MEDIUM qualifies the claim', () {
      // High says nothing: an alert announcing its own trustworthiness
      // is one the reader learns to distrust. Low never gets here.
      expect(alertConfidencePrefix(en, AlertConfidence.high), isNull);
      expect(alertConfidencePrefix(en, AlertConfidence.medium), isNotEmpty);
      expect(alertConfidencePrefix(en, AlertConfidence.low), isNull);
    });
  });
}

/// #4183 — an area-wide movement states no per-litre delta.
///
/// A `VelocityAlertEvent` carries the affected station ids and the
/// LARGEST drop among them. It does not say which station that was, nor
/// what that station charged before — so a (current, earlier) pair
/// composed from the cheapest current price plus the biggest drop would
/// describe no station at all, and `OpportunityReasons` would render it
/// as a confident "N ¢/L below what it was".
void _velocityReferenceTests() {
  Opportunity movement({double? referencePrice}) => Opportunity(
        kind: OpportunityKind.localMovement,
        fuelType: 'e10',
        currentPrice: 1.649,
        reference: OpportunityReference.priceEarlier,
        referencePrice: referencePrice,
        distanceKm: 0,
        priceAge: const DataValue.measured(Duration(minutes: 10)),
        confidence: DataConfidence.high,
        detectedAt: DateTime.utc(2026, 9, 15),
        expiresAt: DateTime.utc(2026, 9, 15, 6),
      );

  test('a movement with no numeric reference renders no below-reference line',
      () {
    final reasons = OpportunityReasons.of(movement());
    expect(reasons.whereType<BelowReferenceReason>(), isEmpty,
        reason: 'the comparison is categorical; a figure here would be '
            'true of no station');
  });

  test('a movement that DOES carry a coherent pair still renders one', () {
    // The capability is not removed — only the fabricated use of it.
    final reasons = OpportunityReasons.of(movement(referencePrice: 1.709));
    expect(reasons.whereType<BelowReferenceReason>().single.perLitreDelta,
        closeTo(0.06, 1e-9));
  });
}
