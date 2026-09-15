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
import '../../../core/constants/field_names.dart';
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
/// Used by the velocity path, where one event produces exactly one post,
/// so the correspondence is trivial. The radius path pairs inside its own
/// loop instead: a grouped event with no matches would shorten the
/// opportunity list and, under the length check below, silently strip the
/// copy from every OTHER candidate too.
///
/// When the counts disagree the extras travel with NO copy, so the
/// dispatcher renders them from their kind if they ever win. Never a
/// mismatched pairing: putting one finding's text on another's numbers is
/// the one outcome that would be worse than plain copy.
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

/// The freshness of a background-scanned price.
///
/// #4186 — the background scan's flattened price map now carries the
/// provider's stamp ([TankerkoenigFields.priceUpdatedAt]), so this can
/// finally answer the question instead of reporting "the provider left
/// this row blank" for eight providers that had in fact published one.
/// That was the background twin of #4189, where the same stamp was
/// formatted for display and the instant thrown away.
///
/// [stampedAt] is null where the provider publishes nothing, and
/// `ProviderCapability.priceAge` reads that as
/// `notPublishedByProvider` — which stands the freshness gate down with
/// a caveat rather than blocking. A stamp in the future is a broken
/// feed, not a fresh price, and yields no age.
DataValue<Duration> priceAgeForScannedRow(
  ProviderCapability? capability, {
  DateTime? stampedAt,
  DateTime? now,
}) {
  if (capability == null) {
    return const DataValue.unknown(
        reason: DataUnknownReason.notPublishedByProvider);
  }
  if (stampedAt == null || now == null) return capability.priceAge(null);
  final age = now.difference(stampedAt);
  return capability.priceAge(age.isNegative ? null : age);
}

/// The provider's stamp on one row of the background price map, or null.
DateTime? scannedRowStamp(Map<String, dynamic>? row) {
  final raw = row?[TankerkoenigFields.priceUpdatedAt];
  return raw is String ? DateTime.tryParse(raw) : null;
}
