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
import '../../../core/notifications/notification_delivery.dart';
import '../../../core/notifications/notification_service.dart';
import '../data/budget_state_store.dart';
import '../data/opportunity_feed_store.dart';
import '../data/opportunity_watch_store.dart';
import '../domain/opportunity.dart';
import '../domain/opportunity_budget.dart';
import '../domain/opportunity_confidence.dart';
import 'notification_templates.dart';
import 'opportunity_notification_copy.dart';

/// Where a notification goes and what it opens (#4334): the id that
/// decides whether it replaces an earlier one on the shade, and the
/// payload its tap deep-links through.
typedef NotificationEnvelope = ({int id, String? payload});

/// One candidate, plus the copy its detector already built when it has
/// better copy than a single opportunity can produce. See the library
/// doc for the radius case this exists for.
@immutable
class OpportunityCandidate {
  const OpportunityCandidate(
    this.opportunity, {
    this.copy,
    this.onNotified,
    this.envelope,
  });

  final Opportunity opportunity;

  /// Used verbatim when non-null. Null means "render me from the kind".
  final NotificationCopy? copy;

  /// #4334 — the id and payload the detector built, posted as they are.
  /// Null means the per-station id scheme and no deep link
  /// ([OpportunityDispatcher.notificationIdFor]).
  ///
  /// The radius runner's notification is one per ALERT
  /// (`'radius:<alertId>'`) and its tap opens the cheapest station. #4183
  /// dropped both on the way through the budget: taps stopped opening the
  /// station, the same alert with a new cheapest station stacked a second
  /// notification, and two alerts sharing a cheapest station overwrote
  /// each other.
  final NotificationEnvelope? envelope;

  /// #4185 — run ONLY for the candidate whose notification actually went
  /// out, and only after it did. This is where a detector's dedup /
  /// cooldown row belongs: written before the budget has spoken, it says
  /// "we told you" about something the user was never told.
  final Future<void> Function()? onNotified;
}

/// What one dispatch did.
@immutable
class DispatchOutcome {
  const DispatchOutcome({
    this.delivery,
    required this.recorded,
    required this.demotions,
    this.notifiedOpportunity,
  });

  /// What became of the winner's notification (#4162) — null when nothing
  /// was attempted: the budget refused everything, or the winner could not
  /// be rendered.
  final NotificationDelivery? delivery;

  /// Whether a notification actually went out.
  bool get notified => delivery?.wasPosted ?? false;

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
    this.watch = const OpportunityWatchStore(),
  });

  final OpportunityFeedStore feed;
  final BudgetStateStore budgetState;
  final BudgetPolicy policy;

  /// #4154 — which kinds the user asked to hear about. Read here rather
  /// than through a provider: this runs in a background isolate.
  final OpportunityWatchStore watch;

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
    // #4333 — a reservation a killed run never committed. Ambiguous: the
    // OS may have shown it. Its slot stays spent (at most once).
    final ambiguous = await budgetState.resolvePending(now);
    if (ambiguous != null) {
      log.info(
          'a delivery reserved at ${ambiguous.at.toIso8601String()} was '
          'never committed; its slot stays spent',
          tag: 'OpportunityDispatcher');
    }

    if (candidates.isEmpty) {
      return const DispatchOutcome(recorded: 0, demotions: []);
    }

    final prebuilt = <Opportunity, NotificationCopy>{
      for (final c in candidates) c.opportunity: ?c.copy,
    };
    // #4185 — so the winner's detector can record what was SENT.
    final byOpportunity = <Opportunity, OpportunityCandidate>{
      for (final c in candidates) c.opportunity: c,
    };

    final state = budgetState.read();
    final watched = watch.read();
    var outcome = OpportunityBudget.decide(
      candidates: [for (final c in candidates) c.opportunity],
      state: state,
      now: now,
      policy: policy,
      confidenceInputs: confidenceInputs,
      // #4154 — an unwatched kind is refused, and still recorded.
      watched: watched.contains,
    );

    NotificationDelivery? delivery;
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
      } else if (await _blocked(notifier) case final blocked?) {
        // #4335 — the OS would show nothing: a revoked permission or a
        // disabled channel, where `show` returns normally anyway. No slot
        // is reserved, no detector cooldown written, and `lastTriggeredAt`
        // is not told — but the finding stays in the feed.
        delivery = blocked;
        outcome = BudgetOutcome(demoted: [
          DemotedOpportunity(winner, BudgetRefusal.ineligible),
          ...outcome.demoted,
        ]);
      } else {
        // #4333 — the slot is on disk BEFORE the post, with a marker that
        // says so. A process killed after the post can no longer leave the
        // budget unaware and re-notify on the next wake (B4).
        final reserved = state.recording(winner, now);
        final envelope = byOpportunity[winner]?.envelope ??
            (id: notificationIdFor(winner), payload: null);
        await budgetState.write(reserved, now, pending: (
          id: envelope.id,
          key: BudgetState.keyFor(winner),
          at: now,
        ));
        delivery = await _notify(winner, copy, envelope, notifier);
        if (delivery.wasPosted) {
          await budgetState.write(reserved, now); // commit
          // #4185 — the dedup / cooldown write, now that a notification
          // really went out. Never for a refused candidate: that is the
          // suppression this issue exists to remove. It stays after the
          // post: a detector's rows cannot be released, and a kill between
          // the post and here is covered by the reserved slot above.
          await byOpportunity[winner]?.onNotified?.call();
        } else {
          // The channel refused it. Not a budget decision, so the slot is
          // released — but the finding is still real and still recorded.
          await budgetState.write(state, now); // release
          outcome = BudgetOutcome(demoted: [
            DemotedOpportunity(winner, BudgetRefusal.ineligible),
            ...outcome.demoted,
          ]);
        }
      }
    }

    await feed.recordScan(outcome, now);

    final posted = delivery?.wasPosted ?? false;
    return DispatchOutcome(
      delivery: delivery,
      notifiedOpportunity: posted ? outcome.notify : null,
      recorded: outcome.demoted.length + (posted ? 1 : 0),
      demotions: outcome.demoted,
    );
  }

  /// The notification id for [o]: the id scheme the per-station runner
  /// used, so an existing notification for a station is replaced rather
  /// than stacked.
  static int notificationIdFor(Opportunity o) =>
      (o.stationId ?? o.kind.name).hashCode;

  /// Ask the notifier's OS whether a price alert would reach the user
  /// (#4335). A notifier that cannot answer is not a probe and is treated
  /// as clear; a probe that throws is [NotificationDelivery.failed].
  Future<NotificationDelivery?> _blocked(NotificationService notifier) async {
    if (notifier is! NotificationDeliveryProbe) return null;
    final NotificationDeliveryProbe probe = notifier as NotificationDeliveryProbe;
    try {
      return await probe.blockedDelivery(NotificationChannelKind.priceAlerts);
    } on Object catch (e, st) {
      log.error(e, st, layer: ErrorLayer.background, context: const {
        'where': 'OpportunityDispatcher._blocked',
      });
      return NotificationDelivery.failed;
    }
  }

  /// Show one notification and say what became of it — the one producer of
  /// [NotificationDelivery] for price alerts (#4162).
  ///
  /// Never throws: a notification channel that rejects a post must not
  /// take the scan down with it, and the finding is recorded either way.
  Future<NotificationDelivery> _notify(
    Opportunity o,
    NotificationCopy copy,
    NotificationEnvelope envelope,
    NotificationService notifier,
  ) async {
    try {
      await notifier.showPriceAlert(
        id: envelope.id,
        title: copy.title,
        body: copy.body,
        payload: envelope.payload,
      );
      return NotificationDelivery.posted;
    } on Object catch (e, st) {
      log.error(e, st, layer: ErrorLayer.background, context: {
        'where': 'OpportunityDispatcher._notify',
        'kind': o.kind.name,
      });
      return NotificationDelivery.failed;
    }
  }
}
