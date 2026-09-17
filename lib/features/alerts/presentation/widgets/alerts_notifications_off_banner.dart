// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_delivery.dart';
import '../../../../core/notifications/notification_providers.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/alert_notifications_blocked_provider.dart';

/// "Notifications are off" on the alerts screen, with a way to fix it
/// (#4335).
///
/// A user with alerts and notifications turned off used to see nothing at
/// all: the scans ran, found prices below the target, and every post
/// vanished — while the budget counted each one as delivered. This is the
/// recovery surface `NotificationService` promised and nothing built.
///
/// Renders nothing unless the OS says price alerts cannot be posted (see
/// [alertNotificationsBlockedProvider]). Re-reads when the app comes back
/// to the foreground, so returning from the settings clears it.
class AlertsNotificationsOffBanner extends ConsumerStatefulWidget {
  const AlertsNotificationsOffBanner({super.key});

  @override
  ConsumerState<AlertsNotificationsOffBanner> createState() =>
      _AlertsNotificationsOffBannerState();
}

class _AlertsNotificationsOffBannerState
    extends ConsumerState<AlertsNotificationsOffBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(alertNotificationsBlockedProvider);
    }
  }

  Future<void> _openSettings() async {
    final service = ref.read(notificationServiceProvider);
    if (service is NotificationDeliveryProbe) {
      await (service as NotificationDeliveryProbe).openNotificationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = ref.watch(alertNotificationsBlockedProvider).value;
    if (blocked == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('alerts-notifications-off-banner'),
      padding: const EdgeInsets.fromLTRB(
          Spacing.lg, 0, Spacing.lg, Spacing.md),
      child: InfoCard(
        icon: Icons.notifications_off_outlined,
        iconColor: theme.colorScheme.error,
        title: l10n.alertsNotificationsOffTitle,
        expandTitle: true,
        body: blocked == NotificationDelivery.suppressedChannel
            ? l10n.alertsNotificationsOffChannelBody
            : l10n.alertsNotificationsOffPermissionBody,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const ValueKey('alerts-notifications-off-open-settings'),
              onPressed: () => unawaited(_openSettings()),
              child: Text(l10n.alertsNotificationsOffOpenSettings),
            ),
          ),
        ],
      ),
    );
  }
}
