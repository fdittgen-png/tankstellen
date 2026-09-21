// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/notifications/notification_delivery.dart';
import '../../../core/notifications/notification_providers.dart';

part 'alert_notifications_blocked_provider.g.dart';

/// Why a price alert could not reach the user right now, or null (#4335).
///
/// Only the two answers a user can act on are surfaced —
/// [NotificationDelivery.suppressedPermission] and
/// [NotificationDelivery.suppressedChannel]. A probe that cannot answer
/// ([NotificationDelivery.failed]) is not reported as "notifications are
/// off": that would tell the user something nobody knows. The dispatcher
/// still fails closed on it; this banner stays silent.
///
/// Re-read on demand (the banner invalidates it when the app resumes, so
/// coming back from the system settings clears it).
@riverpod
Future<NotificationDelivery?> alertNotificationsBlocked(Ref ref) async {
  final service = ref.watch(notificationServiceProvider);
  if (service is! NotificationDeliveryProbe) return null;
  final probe = service as NotificationDeliveryProbe;
  final blocked =
      await probe.blockedDelivery(NotificationChannelKind.priceAlerts);
  return blocked != null && blocked.wasSuppressed ? blocked : null;
}
