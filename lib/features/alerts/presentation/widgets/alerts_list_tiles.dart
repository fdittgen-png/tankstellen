// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/widgets/swipe_to_delete.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/price_alert.dart';
import '../../domain/entities/radius_alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/radius_alerts_provider.dart';

/// Row widgets of the alerts page (#3905 — split out of
/// `alerts_screen.dart` so [AlertsBody] can be reused by the Favorites
/// "Price alerts" tab and the standalone `/alerts` route).

/// One per-station price alert: swipe-to-delete, toggle switch, and a
/// tap that opens the station's detail page (price history) — the
/// behaviour the former Favorites tab list had (#1701 / #3905).
class AlertListTile extends ConsumerWidget {
  final PriceAlert alert;

  const AlertListTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // #3682 — the shared swipe-to-delete carries the app-wide delete
    // confirmation.
    return SwipeToDelete(
      dismissKey: ValueKey(alert.id),
      onDismissed: () {
        unawaited(ref.read(alertProvider.notifier).removeAlert(alert.id));
        SnackBarHelper.show(context, l10n.alertDeleted(alert.stationName));
      },
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.notifications_active,
          color: alert.isActive ? theme.colorScheme.primary : Colors.grey,
        ),
        title: Text(
          alert.stationName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${alert.fuelType.displayName} ≤ ${PriceFormatter.formatPrice(alert.targetPrice)}',
        ),
        // #2117 — platform-adaptive switch glyph.
        trailing: Switch.adaptive(
          value: alert.isActive,
          onChanged: (_) {
            unawaited(ref.read(alertProvider.notifier).toggleAlert(alert.id));
          },
        ),
        // Tap to open station detail (shows price history).
        onTap: () => StationDetailRoute(alert.stationId).push<void>(context),
      ),
    );
  }
}

/// One zone / radius alert row (#578 phase 2): swipe-to-delete with an
/// Undo snackbar, plus the enabled toggle.
class RadiusAlertListTile extends ConsumerWidget {
  final RadiusAlert alert;

  const RadiusAlertListTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // #3682 — the shared swipe-to-delete carries the app-wide delete
    // confirmation.
    return SwipeToDelete(
      dismissKey: ValueKey('radius-${alert.id}'),
      onDismissed: () {
        // #2494 — mirror the per-station tile: a past-tense
        // confirmation with an Undo that re-inserts the deleted alert,
        // rather than the old interrogative "Delete radius alert?" copy
        // shown *after* the deletion had already happened.
        //
        // Capture the (keep-alive) notifier here — this tile is removed
        // from the tree the moment it is dismissed, so `ref` becomes
        // unusable; the Undo callback must close over the notifier, not
        // re-read it through the dead tile's `ref`.
        final notifier = ref.read(radiusAlertsProvider.notifier);
        unawaited(notifier.remove(alert.id));
        SnackBarHelper.showWithUndo(
          context,
          l10n.radiusAlertDeleted(alert.label),
          onUndo: () => notifier.add(alert),
        );
      },
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.location_searching,
          color: alert.enabled ? theme.colorScheme.primary : Colors.grey,
        ),
        title: Text(alert.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${FuelType.fromString(alert.fuelType).displayName} ≤ '
          '${PriceFormatter.formatPrice(alert.threshold)} '
          '· ${alert.radiusKm.round()} km',
        ),
        // #2117 — platform-adaptive switch glyph.
        trailing: Switch.adaptive(
          value: alert.enabled,
          onChanged: (_) {
            unawaited(ref.read(radiusAlertsProvider.notifier).toggle(alert.id));
          },
        ),
      ),
    );
  }
}
