// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_budget.dart';

/// #4154 — the switches decide INTERRUPTION, never discovery.
///
/// The distinction this file exists to pin: an unwatched kind is
/// *refused*, not dropped. It still reaches the feed with its reason,
/// because the engine found it and the user can still come looking. A
/// migration that loses somebody's alerts is worse than the primitive
/// model it replaced (#4149).
void main() {
  final now = DateTime.utc(2026, 9, 15, 12);

  Opportunity opportunity({
    required OpportunityKind kind,
    String stationId = 'de-a',
    double net = 3.8,
  }) =>
      Opportunity(
        kind: kind,
        stationId: stationId,
        stationName: 'ARAL',
        fuelType: 'e10',
        currentPrice: 1.649,
        reference: OpportunityReference.localMedian,
        referencePrice: 1.729,
        grossSaving: net + 0.4,
        detourCost: 0.4,
        netSaving: net,
        distanceKm: 3.2,
        priceAge: const DataValue.measured(Duration(minutes: 12)),
        confidence: DataConfidence.high,
        detectedAt: now,
        expiresAt: now.add(const Duration(hours: 6)),
      );

  test('an unwatched kind is refused with notWatched — and still recorded',
      () {
    final outcome = OpportunityBudget.decide(
      candidates: [opportunity(kind: OpportunityKind.localMovement)],
      state: const BudgetState(),
      now: now,
      watched: (k) => k != OpportunityKind.localMovement,
    );

    expect(outcome.isQuiet, isTrue, reason: 'nothing interrupts the user');
    expect(outcome.demoted, hasLength(1),
        reason: 'suppressed means "not a push", never "discarded"');
    expect(outcome.demoted.single.reason, BudgetRefusal.notWatched);
    expect(outcome.demoted.single.opportunity.kind,
        OpportunityKind.localMovement);
  });

  test('a watched kind still competes and can win', () {
    final outcome = OpportunityBudget.decide(
      candidates: [opportunity(kind: OpportunityKind.bestStopNow)],
      state: const BudgetState(),
      now: now,
      watched: (k) => k == OpportunityKind.bestStopNow,
    );

    expect(outcome.notify?.kind, OpportunityKind.bestStopNow);
    expect(outcome.demoted, isEmpty);
  });

  test('the unwatched one loses to the watched one WITHOUT stealing its '
      'refusal reason', () {
    final outcome = OpportunityBudget.decide(
      candidates: [
        opportunity(kind: OpportunityKind.localMovement, stationId: 'de-quiet'),
        opportunity(
            kind: OpportunityKind.bestStopNow, stationId: 'de-loud', net: 9.0),
      ],
      state: const BudgetState(),
      now: now,
      watched: (k) => k != OpportunityKind.localMovement,
    );

    expect(outcome.notify?.stationId, 'de-loud');
    final quiet = outcome.demoted.singleWhere(
        (d) => d.opportunity.stationId == 'de-quiet');
    expect(quiet.reason, BudgetRefusal.notWatched,
        reason: 'it was never in the running to be outranked');
  });

  test('a null predicate watches every kind — callers that do not read the '
      'setting behave exactly as before', () {
    for (final kind in OpportunityKind.values) {
      final outcome = OpportunityBudget.decide(
        candidates: [opportunity(kind: kind)],
        state: const BudgetState(),
        now: now,
      );
      expect(
          outcome.demoted.where((d) => d.reason == BudgetRefusal.notWatched),
          isEmpty,
          reason: '$kind must not be refused when nothing asked it to be');
    }
  });
}
