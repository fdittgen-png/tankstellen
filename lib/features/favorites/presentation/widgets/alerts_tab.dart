import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../alerts/providers/alert_provider.dart';

/// Tab showing the user's price alerts with swipe-to-delete and toggle support.
class AlertsTab extends StatelessWidget {
  const AlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer(builder: (context, ref, _) {
      final alerts = ref.watch(alertProvider);
      // The radius-alerts + statistics entry is always shown — it is
      // the only navigation path to the `/alerts` screen (#1701), so it
      // must be reachable whether or not the user has price alerts.
      final body = alerts.isEmpty
          ? EmptyState(
              icon: Icons.notifications_off_outlined,
              title: l10n?.noPriceAlerts ?? 'No price alerts',
              subtitle: l10n?.noPriceAlertsHint ??
                  'Create an alert from a station\'s detail page.',
            )
          : _priceAlertsList(context, ref, l10n);
      return Column(
        children: [
          const _RadiusAlertsEntry(),
          Expanded(child: body),
        ],
      );
    });
  }

  Widget _priceAlertsList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    // Re-read here (cheap, idempotent) so the helper carries no
    // explicit alert-model type — keeping favorites/presentation off a
    // direct import of the alerts feature's data layer.
    final alerts = ref.watch(alertProvider);
    return Column(
        children: [
          HelpBanner(
            storageKey: StorageKeys.helpBannerAlerts,
            icon: Icons.notifications_active_outlined,
            message: l10n?.helpBannerAlerts ??
                'Set a price threshold for a station. You\'ll be notified when prices drop below it. Checks run every 30 minutes.',
          ),
          Expanded(
            child: ListView.builder(
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          // Swipe left to delete alert
          return Dismissible(
            key: ValueKey(alert.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Colors.red,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n?.delete ?? 'Delete',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.delete, color: Colors.white, size: 20),
                ],
              ),
            ),
            onDismissed: (_) {
              ref.read(alertProvider.notifier).removeAlert(alert.id);
              SnackBarHelper.show(
                  context,
                  l10n?.alertDeleted(alert.stationName) ??
                      'Alert "${alert.stationName}" deleted');
            },
            child: ListTile(
              leading: Icon(
                alert.isActive
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: alert.isActive
                    ? FuelColors.forType(alert.fuelType)
                    : Colors.grey,
              ),
              title: Text(alert.stationName),
              subtitle: Text(
                '${alert.fuelType.displayName} \u2264 ${PriceFormatter.formatPrice(alert.targetPrice)}',
                style: TextStyle(
                    color: alert.isActive
                        ? FuelColors.forType(alert.fuelType)
                        : Colors.grey),
              ),
              trailing: Switch(
                value: alert.isActive,
                onChanged: (_) =>
                    ref.read(alertProvider.notifier).toggleAlert(alert.id),
              ),
              // Tap to open station detail (shows price history)
              onTap: () => context.push('/station/${alert.stationId}'),
            ),
          );
        },
      ),
          ),
        ],
      );
  }
}

/// Tappable entry on the Alerts tab that opens the radius-alerts +
/// statistics screen at `/alerts` (#1701).
///
/// `/alerts` (`AlertsScreen` — radius alerts + `AlertStatisticsCard`)
/// had no `context.go`/`push` anywhere, so the whole radius-alerts
/// feature was unreachable. This entry is the navigation path; it sits
/// above the price-alert list and shows in the empty state too, so it
/// is always reachable.
class _RadiusAlertsEntry extends StatelessWidget {
  const _RadiusAlertsEntry();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: InkWell(
        key: const Key('radiusAlertsEntry'),
        onTap: () => context.push('/alerts'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.radar, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.radiusAlertsEntryTitle ??
                          'Radius alerts & statistics',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n?.radiusAlertsEntrySubtitle ??
                          'Get notified when prices drop near you',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
