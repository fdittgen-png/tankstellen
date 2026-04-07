import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/fuel_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
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
      if (alerts.isEmpty) {
        return EmptyState(
          icon: Icons.notifications_off_outlined,
          title: l10n?.noPriceAlerts ?? 'No price alerts',
          subtitle: l10n?.noPriceAlertsHint ??
              'Create an alert from a station\'s detail page.',
        );
      }
      return ListView.builder(
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Delete',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.delete, color: Colors.white, size: 20),
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
      );
    });
  }
}
