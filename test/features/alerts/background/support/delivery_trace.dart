// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';

/// One notification a scan posted.
typedef PostedNotification = ({
  int id,
  String title,
  String body,
  String? payload,
  int sequence,
});

/// A delivery defect a kill or an interleaving can produce (#4162).
enum DeliveryDefect {
  /// B4 (#4333) — the same opportunity notified twice inside the budget's
  /// quiet window, because the process died between the post and the
  /// budget write.
  duplicateAfterKill,
}

/// Delivery defects that reproduce today, each a filed issue. The fix
/// removes its entry, and [kKnownDeliveryDefectsCeiling] goes down with it.
const Set<DeliveryDefect> kKnownDeliveryDefects = {};

/// The size [kKnownDeliveryDefects] may never exceed.
const int kKnownDeliveryDefectsCeiling = 0;

/// A [NotificationService] that records every post in order — "at most one
/// notification per opportunity per window" is checked against it.
class DeliveryTrace implements NotificationService {
  DeliveryTrace({this.onPost});

  /// Called right after a post was recorded — where a kill test captures
  /// the "shown, nothing else written yet" instant.
  void Function(PostedNotification post)? onPost;

  /// Called right before a post is recorded — the "about to be shown"
  /// instant, where only what precedes the post is on disk.
  void Function()? onBeforePost;

  final List<PostedNotification> posts = [];
  int _sequence = 0;

  /// When true, the next post throws instead (the channel refused it).
  bool throwOnPost = false;

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    onBeforePost?.call();
    if (throwOnPost) throw StateError('channel refused the post');
    final post = (
      id: id,
      title: title,
      body: body,
      payload: payload,
      sequence: _sequence++,
    );
    posts.add(post);
    onPost?.call(post);
  }

  /// Forget every post after [sequence] — they happened in a process the
  /// test has since "killed" at that instant.
  void truncateAfter(int sequence) =>
      posts.removeWhere((p) => p.sequence > sequence);

  /// Notification ids posted more than once.
  Set<int> get repeatedIds {
    final seen = <int>{};
    return {
      for (final p in posts)
        if (!seen.add(p.id)) p.id,
    };
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

/// A delivery reported as `posted` that the user never saw (#4162).
enum DeliveryMisreport {
  /// N2 (#4335) — notifications turned off for the app.
  revokedPermissionCountedPosted,

  /// N2 (#4335) — the price-alert channel disabled.
  disabledChannelCountedPosted,
}

/// Misreports that reproduce today, each a filed issue.
const Set<DeliveryMisreport> kKnownMisreportedDeliveries = {};

/// The size [kKnownMisreportedDeliveries] may never exceed.
const int kKnownMisreportedDeliveriesCeiling = 0;

/// Something the radius notification lost on its way through the budget.
enum EnvelopeDefect {
  /// N1 (#4334) — the payload that deep-links the tap was dropped.
  radiusPayloadDropped,

  /// N3 (#4334) — the id is per station, not per alert.
  radiusIdPerStation,
}

/// Envelope defects that reproduce today, each a filed issue.
const Set<EnvelopeDefect> kKnownEnvelopeDefects = {};

/// The size [kKnownEnvelopeDefects] may never exceed.
const int kKnownEnvelopeDefectsCeiling = 0;

/// Fails when [observed] holds a misreport that is not a known one.
void expectOnlyKnownMisreports(Iterable<DeliveryMisreport> observed) {
  expect(kKnownMisreportedDeliveries.length,
      lessThanOrEqualTo(kKnownMisreportedDeliveriesCeiling));
  final unexplained =
      observed.toSet().difference(kKnownMisreportedDeliveries);
  expect(unexplained, isEmpty,
      reason: 'delivery misreports that are not a filed, known defect');
}

/// Fails when [observed] holds an envelope defect that is not a known one.
void expectOnlyKnownEnvelopeDefects(Iterable<EnvelopeDefect> observed) {
  expect(kKnownEnvelopeDefects.length,
      lessThanOrEqualTo(kKnownEnvelopeDefectsCeiling));
  final unexplained = observed.toSet().difference(kKnownEnvelopeDefects);
  expect(unexplained, isEmpty,
      reason: 'envelope defects that are not a filed, known defect');
}

/// Fails when [observed] holds a defect that is not a known one.
void expectOnlyKnownDeliveryDefects(Iterable<DeliveryDefect> observed) {
  final unexplained = observed.toSet().difference(kKnownDeliveryDefects);
  expect(unexplained, isEmpty,
      reason: 'delivery defects that are not a filed, known defect');
}
