// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// One attention budget across every alert kind (#4151, epic #4148).
///
/// Each kind suppressed itself: `radius_alert_dedup` and the velocity
/// cooldown. Each is correct on its own terms and neither knows the
/// other exists, so two kinds could fire inside a minute with both
/// having passed their own check.
///
/// **Correction to this doc's first version**, which also named
/// `background_scan_dedup_store`. That store is not a per-kind
/// suppressor: it is a scan-TRIGGER cooldown, stopping a second OS
/// wakeup (WorkManager, the widget refresh, `BGAppRefreshTask`) from
/// re-fetching prices seconds after the first. Its own doc says it
/// "does NOT replace the per-alert throttles". It sits upstream of
/// everything here and this policy neither replaces nor touches it.
///
/// One thing `radius_alert_dedup` has that this policy does not: its
/// 12 h window — the same 12 h as [BudgetPolicy.perStationQuiet] — has
/// an escape hatch, allowing a re-fire when the cheapest match dropped
/// further by at least `priceDropEpsilon`. "Tell me when it gets even
/// cheaper" is a capability, not a duplicate rule, and folding radius
/// into [BudgetPolicy.perStationQuiet] without it would remove it
/// (#4183).
///
/// `alert_delivery_sla` pins the contract — **1-3 per day, ≤3-4 h
/// latency, never next-day** — and nothing enforced it.
///
/// Pure functions over a state value the caller loads and stores, so the
/// whole policy is testable without Hive, without a notification channel
/// and without a clock of its own.
///
/// ## The failure this is built to avoid
///
/// A budget that spends the day's quota on a mediocre opportunity at
/// 08:00 and silently drops the best one at 17:00 is worse than no
/// budget. Two defences, and neither is a guess:
///
///  1. **Rank within the window, do not serve first-come.** Every
///     candidate from one scan is decided together and the best one
///     wins. A cheap station found first does not get the slot merely
///     for being first.
///  2. **A floor, so mediocrity cannot spend a slot at all.** Below
///     [BudgetPolicy.minNetSaving] an interruption costs more than it
///     returns, so it never competes for the quota in the first place.
///
/// The window is one scan cycle and nothing is HELD for a later one.
/// Holding would trade latency for quality, and the SLA above does not
/// have latency to spare — a held opportunity is how "never next-day"
/// gets broken by a well-meaning optimisation.
///
/// ## Nothing is lost
///
/// [BudgetOutcome.demoted] carries every candidate that did not become a
/// notification, each with the reason. They belong in the in-app feed:
/// suppressed means "not a push", never "discarded".
library;

import 'package:meta/meta.dart';

import 'opportunity.dart';
import 'opportunity_confidence.dart';
import 'opportunity_scorer.dart';

/// Why an opportunity did not become a notification.
///
/// Every demotion is nameable. "Why didn't I get an alert" must have an
/// answer, and a budget whose decisions cannot be explained is one
/// nobody can tune or trust.
enum BudgetRefusal {
  /// The day's cap is already spent.
  dailyCapReached,

  /// Another notification went out too recently.
  tooSoonAfterLast,

  /// Worth less than an interruption costs.
  savingBelowFloor,

  /// The user was already told about this station and fuel, by whichever
  /// detector found it first.
  alreadyToldRecently,

  /// A better opportunity in the same scan took the slot.
  outrankedInWindow,

  /// Too weakly supported to arrive uninvited (#4152). NOT discarded:
  /// the in-app feed is where the user came looking, and a weak signal
  /// is still worth having when they asked for it.
  confidenceTooLow,

  /// The scorer refused it outright — expired, untrustworthy provider,
  /// or a saving that does not reconcile.
  ineligible,
}

/// The knobs, in one place, with a defence for each.
@immutable
class BudgetPolicy {
  const BudgetPolicy({
    this.maxPerDay = 3,
    this.minInterval = const Duration(hours: 2),
    this.minNetSaving = 1.0,
    this.perStationQuiet = const Duration(hours: 12),
  });

  /// The top of `alert_delivery_sla`'s 1-3 per day. A cap, not a target:
  /// nothing tries to reach it.
  final int maxPerDay;

  /// Minimum spacing between any two notifications, across ALL kinds.
  /// Two hours lets the cap be reached inside a waking day while making
  /// a burst impossible.
  final Duration minInterval;

  /// Below this, in currency, an interruption costs more than it
  /// returns. Applies only where a saving could be computed — an
  /// opportunity with no money attached is not cheap, it is unmeasured,
  /// and refusing it on a floor it cannot be compared to would silently
  /// disable the kinds that never carry one.
  final double minNetSaving;

  /// How long after telling someone about a station we stay quiet about
  /// it, no matter which detector finds it next. The cross-detector
  /// rule the three per-kind stores could not express between them.
  final Duration perStationQuiet;
}

/// What the budget needs to know about what has already gone out.
///
/// A value object the caller loads and persists. Keeping it out of this
/// file is deliberate: the policy is pure and testable, and the storage
/// is a detail that differs between the foreground and the background
/// isolate.
@immutable
class BudgetState {
  const BudgetState({
    this.recentNotifications = const [],
    this.lastToldByStationFuel = const {},
  });

  /// When notifications went out, most recent order not required.
  final List<DateTime> recentNotifications;

  /// `'<stationId>:<fuelType>'` → when the user was last told.
  final Map<String, DateTime> lastToldByStationFuel;

  /// The key [lastToldByStationFuel] is keyed on. Null for an
  /// opportunity about an area rather than a station — a movement
  /// cannot be deduplicated per station because it is not about one.
  static String? keyFor(Opportunity o) =>
      o.stationId == null ? null : '${o.stationId}:${o.fuelType}';

  int notificationsSince(DateTime cutoff) =>
      recentNotifications.where((t) => t.isAfter(cutoff)).length;

  DateTime? get lastNotification {
    DateTime? latest;
    for (final t in recentNotifications) {
      if (latest == null || t.isAfter(latest)) latest = t;
    }
    return latest;
  }

  /// The state after [at], having notified about [o].
  BudgetState recording(Opportunity o, DateTime at) {
    final key = keyFor(o);
    return BudgetState(
      recentNotifications: [...recentNotifications, at],
      lastToldByStationFuel: {
        ...lastToldByStationFuel,
        ?key: at,
      },
    );
  }

  /// Drops entries older than [keepFor], so the stored state cannot grow
  /// without bound on a device that has been running for a year.
  BudgetState pruned(DateTime now, {Duration keepFor = const Duration(days: 2)}) {
    final cutoff = now.subtract(keepFor);
    return BudgetState(
      recentNotifications:
          recentNotifications.where((t) => t.isAfter(cutoff)).toList(),
      lastToldByStationFuel: {
        for (final e in lastToldByStationFuel.entries)
          if (e.value.isAfter(cutoff)) e.key: e.value,
      },
    );
  }
}

/// One demoted candidate and why.
@immutable
class DemotedOpportunity {
  const DemotedOpportunity(this.opportunity, this.reason);
  final Opportunity opportunity;
  final BudgetRefusal reason;

  @override
  String toString() => '${opportunity.stationId}: ${reason.name}';
}

/// What one scan cycle produced.
@immutable
class BudgetOutcome {
  const BudgetOutcome({this.notify, this.demoted = const []});

  /// The one opportunity worth interrupting for, or null.
  final Opportunity? notify;

  /// Everything else, with its reason. Destined for the in-app feed —
  /// suppressed is not discarded.
  final List<DemotedOpportunity> demoted;

  bool get isQuiet => notify == null;
}

/// The single place that decides whether something becomes a
/// notification.
abstract final class OpportunityBudget {
  /// Decide one scan cycle's worth of [candidates] together.
  static BudgetOutcome decide({
    required Iterable<Opportunity> candidates,
    required BudgetState state,
    required DateTime now,
    BudgetPolicy policy = const BudgetPolicy(),
    ConfidenceInputs Function(Opportunity)? confidenceInputs,
  }) {
    final demoted = <DemotedOpportunity>[];
    final eligible = <Opportunity>[];

    for (final o in candidates) {
      final refusal = _refuse(o, state, now, policy, confidenceInputs);
      if (refusal != null) {
        demoted.add(DemotedOpportunity(o, refusal));
      } else {
        eligible.add(o);
      }
    }

    if (eligible.isEmpty) return BudgetOutcome(demoted: demoted);

    // Rank the survivors together — first-come would let a cheap find
    // take the slot from a better one in the same scan.
    eligible.sort(OpportunityScorer.compare);
    final winner = eligible.first;
    for (final o in eligible.skip(1)) {
      demoted.add(DemotedOpportunity(o, BudgetRefusal.outrankedInWindow));
    }
    return BudgetOutcome(notify: winner, demoted: demoted);
  }

  /// Why [o] cannot be a notification right now, or null.
  ///
  /// Order matters only for which reason gets reported; every one of
  /// these is disqualifying on its own.
  static BudgetRefusal? _refuse(
    Opportunity o,
    BudgetState state,
    DateTime now,
    BudgetPolicy policy,
    ConfidenceInputs Function(Opportunity)? confidenceInputs,
  ) {
    if (!OpportunityScorer.isEligible(o, now)) {
      return BudgetRefusal.ineligible;
    }
    // #4152 — a weakly supported alert may not arrive uninvited. The
    // inputs come from the caller because two of the four (consumption
    // provenance, road-vs-crow-flies) belong to the profile and the
    // routing rather than to the opportunity; defaulting them to the
    // favourable value here would quietly inflate the band, which is
    // the one direction this must never fail in.
    final inputs = confidenceInputs?.call(o) ??
        OpportunityConfidence.inputsFor(o);
    if (!OpportunityConfidence.mayNotify(
        OpportunityConfidence.of(inputs))) {
      return BudgetRefusal.confidenceTooLow;
    }
    // The floor first: a mediocre opportunity must not even compete for
    // the quota, or it can spend a slot the day's best one needed.
    final net = o.netSaving;
    if (net != null && net < policy.minNetSaving) {
      return BudgetRefusal.savingBelowFloor;
    }
    final key = BudgetState.keyFor(o);
    if (key != null) {
      final told = state.lastToldByStationFuel[key];
      if (told != null &&
          now.difference(told) < policy.perStationQuiet) {
        return BudgetRefusal.alreadyToldRecently;
      }
    }
    final last = state.lastNotification;
    if (last != null && now.difference(last) < policy.minInterval) {
      return BudgetRefusal.tooSoonAfterLast;
    }
    if (state.notificationsSince(now.subtract(const Duration(days: 1))) >=
        policy.maxPerDay) {
      return BudgetRefusal.dailyCapReached;
    }
    return null;
  }
}
