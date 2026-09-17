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
const Set<DeliveryDefect> kKnownDeliveryDefects = {
  DeliveryDefect.duplicateAfterKill, // #4333 B4
};

/// The size [kKnownDeliveryDefects] may never exceed.
const int kKnownDeliveryDefectsCeiling = 1;

/// A [NotificationService] that records every post in order — "at most one
/// notification per opportunity per window" is checked against it.
class DeliveryTrace implements NotificationService {
  DeliveryTrace({this.onPost});

  /// Called right after a post was recorded — where a kill test captures
  /// the "shown, nothing else written yet" instant.
  void Function(PostedNotification post)? onPost;

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

/// Fails when [observed] holds a defect that is not a known one.
void expectOnlyKnownDeliveryDefects(Iterable<DeliveryDefect> observed) {
  final unexplained = observed.toSet().difference(kKnownDeliveryDefects);
  expect(unexplained, isEmpty,
      reason: 'delivery defects that are not a filed, known defect');
}
