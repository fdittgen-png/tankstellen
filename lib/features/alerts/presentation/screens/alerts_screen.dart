import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/price_alert.dart';
import '../../domain/entities/radius_alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/radius_alerts_provider.dart';
import '../widgets/alert_statistics_card.dart';
import '../widgets/radius_alert_create_sheet.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsAsyncProvider);
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n?.priceAlerts ?? 'Price Alerts',
      bodyPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      body: alertsAsync.when(
        data: (alerts) => _AlertsBody(alerts: alerts),
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

/// Splits the data branch out so the radius section can hook into the
/// same scroll view as the per-station list. Keeping it a separate
/// `ConsumerWidget` lets each section drive its own provider watch
/// without forcing a full rebuild when the other half changes.
class _AlertsBody extends ConsumerWidget {
  final List<PriceAlert> alerts;

  const _AlertsBody({required this.alerts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final radiusAsync = ref.watch(radiusAlertsProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const AlertStatisticsCard(),
        // ── Per-station alerts ──────────────────────────────────────
        if (alerts.isEmpty)
          EmptyState(
            icon: Icons.notifications_off_outlined,
            title: l10n?.noPriceAlerts ?? 'No price alerts',
            subtitle: l10n?.noPriceAlertsHint ??
                'Create an alert from a station\'s detail page.',
          )
        else
          ...alerts.map((a) => _AlertListTile(key: ValueKey(a.id), alert: a)),
        const Divider(height: 32),
        // ── Radius alerts (#578 phase 2) ────────────────────────────
        _RadiusSectionHeader(
          count: radiusAsync.asData?.value.length ?? 0,
        ),
        radiusAsync.when(
          data: (radiusAlerts) {
            if (radiusAlerts.isEmpty) {
              return _RadiusEmptyState();
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final a in radiusAlerts)
                  _RadiusAlertListTile(key: ValueKey('radius-${a.id}'), alert: a),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => ServiceChainErrorWidget(
            error: error,
            stackTrace: stackTrace,
            searchContext:
                l10n?.alertsLoadErrorTitle ?? "Couldn't load your alerts",
            onRetry: () => ref.invalidate(radiusAlertsProvider),
          ),
        ),
      ],
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
          '${alert.fuelType.displayName} ≤ ${PriceFormatter.formatPrice(alert.targetPrice)}',
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

/// Header row for the radius-alerts section: title + count + add
/// button. Separated out so its tap target is trivially testable and
/// so the parent body stays short enough to read at a glance.
class _RadiusSectionHeader extends StatelessWidget {
  final int count;

  const _RadiusSectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${l10n?.alertsRadiusSectionTitle ?? 'Radius alerts'} ($count)',
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: l10n?.alertsRadiusAdd ?? 'Add radius alert',
            onPressed: () => RadiusAlertCreateSheet.show(context),
          ),
        ],
      ),
    );
  }
}

class _RadiusEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: EmptyState(
        icon: Icons.location_searching,
        title: l10n?.alertsRadiusEmptyTitle ?? 'No radius alerts yet',
        actionLabel: l10n?.alertsRadiusEmptyCta ?? 'Create a radius alert',
        onAction: () => RadiusAlertCreateSheet.show(context),
      ),
    );
  }
}

class _RadiusAlertListTile extends ConsumerWidget {
  final RadiusAlert alert;

  const _RadiusAlertListTile({super.key, required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Dismissible(
      key: ValueKey('radius-${alert.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(radiusAlertsProvider.notifier).remove(alert.id);
        SnackBarHelper.show(
          context,
          l10n?.alertsRadiusDeleteConfirm ?? 'Delete radius alert?',
        );
      },
      child: ListTile(
        leading: Icon(
          Icons.location_searching,
          color: alert.enabled ? theme.colorScheme.primary : Colors.grey,
        ),
        title: Text(
          alert.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${alert.fuelType} ≤ '
          '${PriceFormatter.formatPrice(alert.threshold)} '
          '· ${alert.radiusKm.round()} km',
        ),
        trailing: Switch(
          value: alert.enabled,
          onChanged: (_) {
            ref.read(radiusAlertsProvider.notifier).toggle(alert.id);
          },
        ),
      ),
    );
  }
}
