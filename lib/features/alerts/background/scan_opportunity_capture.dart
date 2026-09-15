// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Turning what the legacy runners WOULD have posted into candidates for
/// the budget (#4183).
///
/// `VelocityAlertRunner` and `RadiusAlertRunner` each own a notifier, a
/// dedup store and a copy builder. Rewriting them into detect-only
/// classes would be the largest edit in this issue and would land on the
/// two paths with the most existing tests — and #4149's rule stands:
/// "a migration that loses somebody's alerts is worse than the primitive
/// model it replaces".
///
/// So they keep running exactly as they do, against a notifier that
/// CAPTURES instead of posting. What they produced becomes an
/// [OpportunityCandidate] carrying their own copy verbatim, and the
/// budget makes the one interrupt decision it exists to make.
///
/// Three things this preserves that a rewrite would have had to
/// re-derive:
///
///  * the radius runner's **grouped** notification — one per alert over
///    N stations, with its multi-line body;
///  * its **price-drop escape hatch**, which re-fires inside the 12 h
///    window when the cheapest match dropped further (a capability, not
///    a duplicate rule — see `opportunity_budget.dart`);
///  * the velocity cooldown and its per-area semantics.
///
/// ## The one ordering caveat, stated rather than hidden
///
/// Those runners write their dedup state when THEY decide to fire. If
/// the budget then refuses, the dedup has recorded a fire that never
/// reached anyone, so the same finding stays suppressed for its window.
/// It is bounded — the budget only refuses when something better went
/// out or the day's cap is spent, which is roughly when not re-offering
/// it is right anyway — but it is a real seam in the wrong order, and it
/// is the reason those two runners eventually want the detect/notify
/// split the per-station one got here (#4185).
library;

import '../../../core/notifications/notification_service.dart';
import '../../../core/domain/data_value.dart';
import '../../../core/services/provider_capability.dart';
import '../domain/opportunity.dart';
import 'opportunity_dispatcher.dart';
import 'opportunity_notification_copy.dart';

/// One notification a legacy runner tried to post.
class CapturedNotification {
  const CapturedNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String? payload;

  NotificationCopy get copy => (title: title, body: body);
}

/// A [NotificationService] that records instead of posting.
///
/// Every other member is a no-op rather than a throw: these runners call
/// `initialize()` and may call `cancelNotification`, and a capture seam
/// that threw on an unrelated call would turn a refactor into a crash in
/// a background isolate.
class CapturingNotificationService implements NotificationService {
  final List<CapturedNotification> captured = [];

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    captured.add(CapturedNotification(
        id: id, title: title, body: body, payload: payload));
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

/// Pair [opportunities] with the copy their runner built, by position.
///
/// The runners emit their events and their notifications in the same
/// order, which is the only correspondence available without threading
/// an id through two third-party-shaped runner APIs. When the counts
/// disagree — a runner that grouped several findings into one post — the
/// extra opportunities travel with NO copy, so the dispatcher renders
/// them from their kind if they ever win. Never a mismatched pairing:
/// putting one finding's text on another's numbers is the one outcome
/// that would be worse than plain copy.
List<OpportunityCandidate> pairWithCapturedCopy(
  List<Opportunity> opportunities,
  List<CapturedNotification> captured,
) =>
    [
      for (var i = 0; i < opportunities.length; i++)
        OpportunityCandidate(
          opportunities[i],
          copy: i < captured.length && opportunities.length == captured.length
              ? captured[i].copy
              : null,
        ),
    ];

/// The freshness of a background-scanned price, as far as we can say.
///
/// The background price map is a flat `id → {status, e5, e10, …}` shape
/// with no per-row timestamp — `StationPrices` does not carry one, so
/// the polled path has none to pass on. For a provider that publishes
/// no stamps at all ([ProviderCapability.priceTimestamp] false) this is
/// exactly right: `notPublishedByProvider`.
///
/// For a provider that DOES stamp, this reports
/// `notPublishedForThisItem`, which is not quite the truth — the
/// provider published one and this path did not carry it. It is
/// recorded here rather than papered over, and it makes no claim
/// either way: `OpportunityScorer` only gates on a `Measured` age, and
/// #4152's reason list deliberately renders NOTHING for
/// `notPublishedForThisItem`. So the label is internal and produces no
/// user-visible statement. Carrying the stamp through `StationPrices`
/// is #4186.
DataValue<Duration> priceAgeForScannedRow(ProviderCapability? capability) =>
    capability?.priceAge(null) ??
    const DataValue.unknown(
        reason: DataUnknownReason.notPublishedByProvider);
