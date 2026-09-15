// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The single place a scan decides what becomes a notification (#4183).
///
/// Before this, three runners each decided on their own that they were
/// worth an interruption — the station+threshold runner, the radius
/// runner and the velocity detector — and three cooldowns cannot make one
/// budget. `alert_delivery_sla` pins the contract at **1-3 per day,
/// ≤3-4 h latency, never next-day**; with three independent rules that
/// was a coincidence of thresholds rather than a property of the system.
///
/// The pipeline the epic (#4148) describes, end to end:
///
///     detect → score → explain → budget → notify
///                                    ↘ feed
///
/// The runners now only **detect**, emitting [Opportunity]. This takes
/// the union, ranks it ([OpportunityScorer]), spends at most one slot
/// ([OpportunityBudget]) and writes **everything** — the notified one and
/// every refusal with its reason — to [OpportunityFeedStore].
///
/// ## Nothing is lost, and that is checkable
///
/// #4151 promised that a demotion is not a deletion. Here that becomes a
/// write: the feed keeps the refused ones, so "why didn't I get an alert"
/// has an answer a user can open rather than one in a log file nobody
/// has. A dispatch that notified nobody still records what it found.
///
/// ## Why a detector may supply its own copy
///
/// The radius runner fires ONE GROUPED notification per alert — "Berlin:
/// 5 stations ≤ 1.699 €" over a five-line body — while [Opportunity] is
/// per-station by design (#4149 kept that grouping where it was). A
/// single opportunity therefore cannot reproduce that text, and rendering
/// it from one would demote a five-station roll-up to "ARAL Berlin: 1
/// stations ≤ 1.699 €".
///
/// So [OpportunityCandidate] carries optional pre-built copy, used
/// verbatim when present. The dispatcher decides WHETHER to interrupt;
/// a detector that already knows how to say it best still says it. #4149
/// was a migration, not a rewrite — "none of them changes when an alert
/// fires" — and quietly changing what one SAYS would have been the same
/// kind of unannounced change.
///
/// ## Runs in a background isolate
///
/// No `BuildContext`, no Riverpod container, and no clock of its own —
/// `now` is a parameter, like every piece of the domain it drives. It
/// never throws: a scan that cannot write its feed must still finish, and
/// a scan that cannot notify must still record.
library;

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/notifications/notification_service.dart';
import '../data/budget_state_store.dart';
import '../data/opportunity_feed_store.dart';
import '../domain/opportunity.dart';
import '../domain/opportunity_budget.dart';
import '../domain/opportunity_confidence.dart';
import 'notification_templates.dart';
import 'opportunity_notification_copy.dart';

/// One candidate, plus the copy its detector already built when it has
/// better copy than a single opportunity can produce. See the library
/// doc for the radius case this exists for.
@immutable
class OpportunityCandidate {
  const OpportunityCandidate(this.opportunity, {this.copy});

  final Opportunity opportunity;

  /// Used verbatim when non-null. Null means "render me from the kind".
  final NotificationCopy? copy;
}

/// What one dispatch did.
@immutable
class DispatchOutcome {
  const DispatchOutcome({
    required this.notified,
    required this.recorded,
    required this.demotions,
    this.notifiedOpportunity,
  });

  /// Whether a notification actually went out. False when the budget
  /// refused everything AND when the winner could not be rendered.
  final bool notified;

  /// The one that was sent, when one was. Callers need it to record
  /// what they told the user about — `PriceAlert.lastTriggeredAt` is
  /// user-visible and must mean "you were told", not "we considered it".
  final Opportunity? notifiedOpportunity;

  /// How many entries reached the feed — the notified one plus every
  /// refusal.
  final int recorded;

  /// Why each candidate did not become a notification, in the budget's
  /// order. Returned as well as stored so the scan journal can carry a
  /// summary without re-reading the feed.
  final List<DemotedOpportunity> demotions;
}

/// Ranks, budgets, notifies and records one scan's candidates.
class OpportunityDispatcher {
  const OpportunityDispatcher({
    this.feed = const OpportunityFeedStore(),
    this.budgetState = const BudgetStateStore(),
    this.policy = const BudgetPolicy(),
  });

  final OpportunityFeedStore feed;
  final BudgetStateStore budgetState;
  final BudgetPolicy policy;

  /// Three decimals, matching what the per-station runner has always
  /// shown. Not a locale format: this runs where there is no locale, and
  /// #2306's whole design is that only VALUES are interpolated here.
  static String defaultPrice(double v) => v.toStringAsFixed(3);

  static String defaultDistance(double v) => v.toStringAsFixed(1);

  /// Decide, notify and record.
  ///
  /// [notifier] is already initialized by the caller — the runners share
  /// one across a scan, and initializing per dispatch would re-register
  /// the channel on every wakeup.
  Future<DispatchOutcome> dispatch({
    required List<OpportunityCandidate> candidates,
    required DateTime now,
    required NotificationService notifier,
    required BackgroundNotificationTemplates templates,
    String Function(double)? priceOf,
    String Function(double)? distanceOf,
    String? Function(Opportunity)? currencyOf,
    ConfidenceInputs Function(Opportunity)? confidenceInputs,
  }) async {
    if (candidates.isEmpty) {
      return const DispatchOutcome(
          notified: false, recorded: 0, demotions: []);
    }

    final prebuilt = <Opportunity, NotificationCopy>{
      for (final c in candidates) c.opportunity: ?c.copy,
    };

    final state = budgetState.read();
    var outcome = OpportunityBudget.decide(
      candidates: [for (final c in candidates) c.opportunity],
      state: state,
      now: now,
      policy: policy,
      confidenceInputs: confidenceInputs,
    );

    var notified = false;
    if (outcome.notify case final winner?) {
      final copy = prebuilt[winner] ??
          OpportunityNotificationCopy.render(
            winner,
            templates,
            priceOf: priceOf ?? defaultPrice,
            distanceOf: distanceOf ?? defaultDistance,
            currency: currencyOf?.call(winner),
          );
      if (copy == null) {
        // The winner cannot be stated without inventing a field it does
        // not carry. It stays in the feed with a reason rather than
        // becoming a notification naming a station id — and, crucially,
        // it does NOT spend the budget slot.
        log.debug(
            'winner ${winner.stationId} has no renderable copy '
            '(${winner.kind.name}); recording, not sending',
            tag: 'OpportunityDispatcher');
        outcome = BudgetOutcome(demoted: [
          DemotedOpportunity(winner, BudgetRefusal.ineligible),
          ...outcome.demoted,
        ]);
      } else {
        notified = await _notify(winner, copy, notifier);
        if (notified) {
          await budgetState.write(state.recording(winner, now), now);
        } else {
          // The channel refused it. Not a budget decision, so the slot is
          // not spent — but the finding is still real and still recorded.
          outcome = BudgetOutcome(demoted: [
            DemotedOpportunity(winner, BudgetRefusal.ineligible),
            ...outcome.demoted,
          ]);
        }
      }
    }

    await feed.recordScan(outcome, now);

    return DispatchOutcome(
      notified: notified,
      notifiedOpportunity: notified ? outcome.notify : null,
      recorded: outcome.demoted.length + (notified ? 1 : 0),
      demotions: outcome.demoted,
    );
  }

  /// Show one notification. Returns whether it went out.
  ///
  /// Never throws: a notification channel that rejects a post must not
  /// take the scan down with it, and the finding is recorded either way.
  Future<bool> _notify(
    Opportunity o,
    NotificationCopy copy,
    NotificationService notifier,
  ) async {
    try {
      await notifier.showPriceAlert(
        // Same id scheme the per-station runner used, so an existing
        // notification for a station is replaced rather than stacked.
        id: (o.stationId ?? o.kind.name).hashCode,
        title: copy.title,
        body: copy.body,
      );
      return true;
    } on Object catch (e, st) {
      log.error(e, st, layer: ErrorLayer.background, context: {
        'where': 'OpportunityDispatcher._notify',
        'kind': o.kind.name,
      });
      return false;
    }
  }
}
