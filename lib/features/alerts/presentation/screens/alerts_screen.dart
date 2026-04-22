import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/price_alert.dart';
import '../../providers/alert_provider.dart';
import '../widgets/alert_statistics_card.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsAsyncProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.priceAlerts ?? 'Price Alerts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n?.tooltipBack ?? 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: alertsAsync.when(
        data: (alerts) => alerts.isEmpty
            ? EmptyState(
                icon: Icons.notifications_off_outlined,
                title: l10n?.noPriceAlerts ?? 'No price alerts',
                subtitle: l10n?.noPriceAlertsHint ??
                    'Create an alert from a station\'s detail page.',
              )
            : ListView.builder(
                itemCount: alerts.length + 1,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const AlertStatisticsCard();
                  }
                  final alert = alerts[index - 1];
                  return _AlertListTile(key: ValueKey(alert.id), alert: alert);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ServiceChainErrorWidget(
          error: error,
          stackTrace: stackTrace,
          searchContext:
              l10n?.alertsLoadErrorTitle ?? "Couldn't load your alerts",
          onRetry: () {
            // Invalidate both the underlying notifier and the async
            // wrapper so the read is retried from scratch.
            ref.invalidate(alertProvider);
            ref.invalidate(alertsAsyncProvider);
          },
        ),
      ),
    );
  }
}

class _AlertListTile extends ConsumerWidget {
  final PriceAlert alert;

  const _AlertListTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Dismissible(
      key: ValueKey(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(alertProvider.notifier).removeAlert(alert.id);
        SnackBarHelper.show(context, l10n?.alertDeleted(alert.stationName) ?? 'Alert "${alert.stationName}" deleted');
      },
      child: ListTile(
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
          '${alert.fuelType.displayName} \u2264 ${PriceFormatter.formatPrice(alert.targetPrice)}',
        ),
        trailing: Switch(
          value: alert.isActive,
          onChanged: (_) {
            ref.read(alertProvider.notifier).toggleAlert(alert.id);
          },
        ),
      ),
    );
  }
}
