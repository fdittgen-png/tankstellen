// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_budget.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_confidence.dart';

/// #4151 — one attention budget across every alert kind.
///
/// Three kinds each suppressed themselves correctly and none knew the
/// others existed, so three notifications could go out inside a minute
/// with every one having passed its own check. `alert_delivery_sla`
/// pins 1-3 per day; nothing enforced it.
///
/// The test that matters most is the last group: the SLA as an
/// executable contract rather than a sentence in a memory file.
void main() {
  final now = DateTime.utc(2026, 9, 14, 12);

  Opportunity op({
    String? stationId = 's',
    double? net = 3.0,
    double distanceKm = 2,
    String fuel = 'e10',
    OpportunityKind kind = OpportunityKind.exceptionalLocalPrice,
    DataConfidence confidence = DataConfidence.high,
    DateTime? detectedAt,
  }) {
    final t = detectedAt ?? now;
    return Opportunity(
      kind: kind,
      stationId: stationId,
      fuelType: fuel,
      currentPrice: 1.60,
      reference: OpportunityReference.thresholdYouSet,
      referencePrice: 1.70,
      grossSaving: net == null ? null : net + 0.5,
      detourCost: net == null ? null : 0.5,
      netSaving: net,
      distanceKm: distanceKm,
      priceAge: const DataValue.measured(Duration(minutes: 30)),
      confidence: confidence,
      detectedAt: t,
      expiresAt: t.add(const Duration(hours: 6)),
    );
  }

  group('the best one wins the slot, never the first one found', () {
    test('a scan emits exactly one notification', () {
      final out = OpportunityBudget.decide(
        candidates: [op(stationId: 'a'), op(stationId: 'b'), op(stationId: 'c')],
        state: const BudgetState(),
        now: now,
      );
      expect(out.notify, isNotNull);
      expect(out.demoted, hasLength(2));
    });

    test('a cheap find does not take the slot from a better one', () {
      // The whole reason the budget ranks a window instead of serving
      // first-come.
      final out = OpportunityBudget.decide(
        candidates: [
          op(stationId: 'meh', net: 1.20),
          op(stationId: 'great', net: 8.00),
          op(stationId: 'ok', net: 2.50),
        ],
        state: const BudgetState(),
        now: now,
      );
      expect(out.notify!.stationId, 'great');
    });

    test('the losers are demoted, not discarded', () {
      // Suppressed means "not a push". Everything still reaches the
      // in-app feed with a reason attached.
      final out = OpportunityBudget.decide(
        candidates: [op(stationId: 'a', net: 5), op(stationId: 'b', net: 2)],
        state: const BudgetState(),
        now: now,
      );
      expect(out.demoted.single.opportunity.stationId, 'b');
      expect(out.demoted.single.reason, BudgetRefusal.outrankedInWindow);
    });

    test('every demotion carries a nameable reason', () {
      // "Why didn't I get an alert" must have an answer.
      final out = OpportunityBudget.decide(
        candidates: [
          op(stationId: 'poor', net: 0.10),
          op(stationId: 'dead', confidence: DataConfidence.none),
          op(stationId: 'fine', net: 5),
        ],
        state: const BudgetState(),
        now: now,
      );
      expect(out.notify!.stationId, 'fine');
      final reasons = {
        for (final d in out.demoted) d.opportunity.stationId: d.reason,
      };
      expect(reasons['poor'], BudgetRefusal.savingBelowFloor);
      expect(reasons['dead'], BudgetRefusal.ineligible);
    });
  });

  group('mediocrity cannot spend the day quota', () {
    test('below the floor it never even competes', () {
      final out = OpportunityBudget.decide(
        candidates: [op(net: 0.40)],
        state: const BudgetState(),
        now: now,
      );
      expect(out.isQuiet, isTrue);
      expect(out.demoted.single.reason, BudgetRefusal.savingBelowFloor);
    });

    test('an UNPRICED opportunity is not refused on a floor it has no '
        'figure for', () {
      // It is not cheap, it is unmeasured. Refusing it here would
      // silently disable every kind that never carries money — the
      // velocity detector above all.
      final out = OpportunityBudget.decide(
        candidates: [op(net: null, kind: OpportunityKind.localMovement)],
        state: const BudgetState(),
        now: now,
      );
      expect(out.notify, isNotNull);
    });
  });

  group('one budget, not three', () {
    test('a second notification too soon is refused whatever found it', () {
      final state = const BudgetState().recording(
        op(stationId: 'earlier'),
        now.subtract(const Duration(minutes: 30)),
      );
      final out = OpportunityBudget.decide(
        candidates: [op(stationId: 'other', net: 9)],
        state: state,
        now: now,
      );
      expect(out.demoted.single.reason, BudgetRefusal.tooSoonAfterLast);
    });

    test('the same station is quiet across DETECTORS, not just within one',
        () {
      // The cross-kind rule the three per-kind stores could not express
      // between them: a radius alert told the user about this station,
      // so the favourite-station alert does not tell them again.
      final state = const BudgetState().recording(
        op(stationId: 'shared', kind: OpportunityKind.exceptionalLocalPrice),
        now.subtract(const Duration(hours: 3)),
      );
      final out = OpportunityBudget.decide(
        candidates: [
          op(stationId: 'shared', kind: OpportunityKind.favouriteStation),
        ],
        state: state,
        now: now,
      );
      expect(out.demoted.single.reason, BudgetRefusal.alreadyToldRecently);
    });

    test('a different FUEL at the same station is a different thing', () {
      final state = const BudgetState().recording(
        op(stationId: 'shared', fuel: 'e10'),
        now.subtract(const Duration(hours: 3)),
      );
      final out = OpportunityBudget.decide(
        candidates: [op(stationId: 'shared', fuel: FuelType.diesel.apiValue)],
        state: state,
        now: now,
      );
      expect(out.notify, isNotNull);
    });

    test('an area-wide movement is not deduplicated per station', () {
      // It is not about a station, so there is no station to be quiet
      // about.
      final state = const BudgetState().recording(
        op(stationId: null, kind: OpportunityKind.localMovement),
        now.subtract(const Duration(hours: 3)),
      );
      expect(state.lastToldByStationFuel, isEmpty);
    });

    test('the daily cap counts across every kind', () {
      var state = const BudgetState();
      for (var i = 3; i >= 1; i--) {
        state = state.recording(
            op(stationId: 'past$i'), now.subtract(Duration(hours: i * 3)));
      }
      final out = OpportunityBudget.decide(
        candidates: [op(stationId: 'fresh', net: 20)],
        state: state,
        now: now,
      );
      expect(out.demoted.single.reason, BudgetRefusal.dailyCapReached);
    });
  });

  group('the SLA is a test, not a sentence in a memory file', () {
    test('a day of opportunities never exceeds 3 notifications', () {
      // Every ten minutes for 24 h, all of them excellent and all at
      // different stations — the adversarial case for a cap.
      var state = const BudgetState();
      var fired = 0;
      final day = DateTime.utc(2026, 9, 14);
      for (var m = 0; m < 24 * 60; m += 10) {
        final t = day.add(Duration(minutes: m));
        final out = OpportunityBudget.decide(
          candidates: [op(stationId: 'st$m', net: 12, detectedAt: t)],
          state: state,
          now: t,
        );
        if (out.notify != null) {
          fired++;
          state = state.recording(out.notify!, t).pruned(t);
        }
      }
      expect(fired, lessThanOrEqualTo(3),
          reason: 'alert_delivery_sla: 1-3 per day, across ALL kinds');
    });

    test('and still delivers — a quiet budget is also a broken one', () {
      var state = const BudgetState();
      var fired = 0;
      final day = DateTime.utc(2026, 9, 14);
      for (var m = 0; m < 24 * 60; m += 10) {
        final t = day.add(Duration(minutes: m));
        final out = OpportunityBudget.decide(
          candidates: [op(stationId: 'st$m', net: 12, detectedAt: t)],
          state: state,
          now: t,
        );
        if (out.notify != null) {
          fired++;
          state = state.recording(out.notify!, t).pruned(t);
        }
      }
      expect(fired, greaterThanOrEqualTo(1),
          reason: 'a budget that never fires satisfies the cap and fails '
              'the user — the SLA floor is 1, not 0');
    });

    test('nothing is ever held for a later cycle', () {
      // Holding trades latency for quality and the SLA has none to
      // spare: "never next-day" is how a well-meaning optimisation
      // breaks it. A refused opportunity is demoted NOW, not queued.
      final state = const BudgetState()
          .recording(op(stationId: 'x'), now.subtract(const Duration(minutes: 5)));
      final out = OpportunityBudget.decide(
        candidates: [op(stationId: 'held', net: 50)],
        state: state,
        now: now,
      );
      expect(out.notify, isNull);
      expect(out.demoted, hasLength(1),
          reason: 'it left the pipeline as demoted rather than staying in '
              'it as pending');
    });

    test('the cap is a rolling day, not a calendar one', () {
      // Three at 23:00 must not free three more at 00:01.
      var state = const BudgetState();
      // 22:00, 20:00, 18:00 — spaced so the min-interval is NOT the
      // binding constraint at 00:01, or this would pass for the wrong
      // reason and stop testing the cap at all.
      final late = DateTime.utc(2026, 9, 14, 22);
      for (var i = 0; i < 3; i++) {
        state = state.recording(
            op(stationId: 'n$i'), late.subtract(Duration(hours: i * 2)));
      }
      final justAfterMidnight = DateTime.utc(2026, 9, 15, 0, 1);
      final out = OpportunityBudget.decide(
        // Detected NOW, not twelve hours ago — otherwise this measures
        // expiry rather than the cap it means to.
        candidates: [
          op(stationId: 'new', net: 20, detectedAt: justAfterMidnight),
        ],
        state: state,
        now: justAfterMidnight,
      );
      expect(out.demoted.single.reason, BudgetRefusal.dailyCapReached);
    });
  });

  group('#4152 — a weak alert may not arrive uninvited', () {
    test('low confidence is refused, and NAMED', () {
      final out = OpportunityBudget.decide(
        candidates: [op(net: 9)],
        state: const BudgetState(),
        now: now,
        confidenceInputs: (_) => const ConfidenceInputs(
          provider: DataConfidence.low,
          priceAge: DataValue.measured(Duration(minutes: 5)),
        ),
      );
      expect(out.isQuiet, isTrue);
      expect(out.demoted.single.reason, BudgetRefusal.confidenceTooLow);
    });

    test('it is demoted, not discarded — the feed still gets it', () {
      // The user came looking in the in-app feed; a weak signal is
      // still worth having when they asked for it. It simply may not
      // interrupt.
      final out = OpportunityBudget.decide(
        candidates: [op(stationId: 'weak', net: 9)],
        state: const BudgetState(),
        now: now,
        confidenceInputs: (_) => const ConfidenceInputs(
          provider: DataConfidence.none,
          priceAge: DataValue.measured(Duration(minutes: 5)),
        ),
      );
      expect(out.demoted.single.opportunity.stationId, 'weak');
    });

    test('medium confidence still notifies', () {
      final out = OpportunityBudget.decide(
        candidates: [op(net: 9)],
        state: const BudgetState(),
        now: now,
        confidenceInputs: (_) => const ConfidenceInputs(
          provider: DataConfidence.medium,
          priceAge: DataValue.measured(Duration(minutes: 5)),
        ),
      );
      expect(out.notify, isNotNull);
    });

    test('a high-confidence one outranks a weak one that scores better',
        () {
      // The weak one is refused before the ranking, so a bigger number
      // behind worse data never wins.
      final out = OpportunityBudget.decide(
        candidates: [op(stationId: 'weak', net: 40), op(stationId: 'good', net: 2)],
        state: const BudgetState(),
        now: now,
        confidenceInputs: (o) => ConfidenceInputs(
          provider: o.stationId == 'weak'
              ? DataConfidence.low
              : DataConfidence.high,
          priceAge: const DataValue.measured(Duration(minutes: 5)),
        ),
      );
      expect(out.notify!.stationId, 'good');
    });
  });

  group('the state cannot grow without bound', () {
    test('pruning drops what no rule can still consult', () {
      var state = const BudgetState();
      state = state.recording(op(stationId: 'old'),
          now.subtract(const Duration(days: 5)));
      state = state.recording(op(stationId: 'recent'),
          now.subtract(const Duration(hours: 1)));
      final pruned = state.pruned(now);
      expect(pruned.recentNotifications, hasLength(1));
      expect(pruned.lastToldByStationFuel.keys, ['recent:e10']);
    });
  });
}
