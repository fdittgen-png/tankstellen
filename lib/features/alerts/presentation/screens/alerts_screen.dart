// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
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

    // #2819 — two clearly-labelled sections (Station + Zone), each with a
    // count + an add affordance, alerts grouped inside one rounded card with
    // dense rows. Replaces the old layout where per-station alerts floated
    // unlabelled above a big divider (asymmetric with the labelled radius
    // section) and the screen wasted most of its vertical space.
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        const AlertStatisticsCard(),
        const SizedBox(height: 4),
        // ── Station alerts ──────────────────────────────────────────
        _SectionHeader(
          title: l10n?.alertsStationSectionTitle ?? 'Station alerts',
          count: alerts.length,
          addTooltip: l10n?.alertsStationAdd ?? 'Add a station alert',
          onAdd: () => SnackBarHelper.show(
            context,
            l10n?.noPriceAlertsHint ??
                'Create an alert from a station\'s detail page.',
          ),
        ),
        if (alerts.isEmpty)
          _SectionEmpty(
            icon: Icons.notifications_off_outlined,
            text: l10n?.noPriceAlertsHint ??
                'Create an alert from a station\'s detail page.',
          )
        else
          _GroupedAlertsCard(
            children: [
              for (final a in alerts)
                _AlertListTile(key: ValueKey(a.id), alert: a),
            ],
          ),
        const SizedBox(height: 12),
        // ── Zone / radius alerts (#578 phase 2) ─────────────────────
        _SectionHeader(
          title: l10n?.alertsRadiusSectionTitle ?? 'Radius alerts',
          count: radiusAsync.asData?.value.length ?? 0,
          addTooltip: l10n?.alertsRadiusAdd ?? 'Add radius alert',
          onAdd: () => RadiusAlertCreateSheet.show(context),
        ),
        radiusAsync.when(
          data: (radiusAlerts) {
            if (radiusAlerts.isEmpty) {
              return _RadiusEmptyState();
            }
            return _GroupedAlertsCard(
              children: [
                for (final a in radiusAlerts)
                  _RadiusAlertListTile(
                      key: ValueKey('radius-${a.id}'), alert: a),
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

/// One section's alerts, grouped inside a single rounded card with hairline
/// dividers between rows (#2819). `clipBehavior` keeps each row's
/// swipe-to-delete background inside the card's rounded corners.
class _GroupedAlertsCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupedAlertsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    // SectionCard (#923) clips to its rounded corners and carries the
    // canonical elevation/outline; padding zero keeps the rows full-bleed
    // so the hairline dividers span edge-to-edge.
    return SectionCard(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Compact inline empty row for a section with no alerts yet — far less
/// wasteful than a full-screen [EmptyState] inside a two-section layout.
class _SectionEmpty extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionEmpty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // SectionCard's default 16 px padding replaces the old inner Padding.
    return SectionCard(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
        color: DarkModeColors.error(context),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(alertProvider.notifier).removeAlert(alert.id);
        SnackBarHelper.show(context, l10n?.alertDeleted(alert.stationName) ?? 'Alert "${alert.stationName}" deleted');
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
            ref.read(alertProvider.notifier).toggleAlert(alert.id);
          },
        ),
      ),
    );
  }
}

/// A section header: title + count badge + an add button (#2819). Shared by
/// the Station and Zone sections so both read symmetrically — the key fix for
/// the old screen where the station alerts had no header at all.
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String addTooltip;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.addTooltip,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$title ($count)',
              style: theme.textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: addTooltip,
            onPressed: onAdd,
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
        color: DarkModeColors.error(context),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        // #2494 — mirror the per-station tile (:142): a past-tense
        // confirmation with an Undo that re-inserts the deleted alert,
        // rather than the old interrogative "Delete radius alert?" copy
        // shown *after* the deletion had already happened.
        //
        // Capture the (keep-alive) notifier here — this tile is removed
        // from the tree the moment it is dismissed, so `ref` becomes
        // unusable; the Undo callback must close over the notifier, not
        // re-read it through the dead tile's `ref`.
        final notifier = ref.read(radiusAlertsProvider.notifier);
        notifier.remove(alert.id);
        SnackBarHelper.showWithUndo(
          context,
          l10n?.radiusAlertDeleted(alert.label) ??
              'Radius alert "${alert.label}" deleted',
          onUndo: () => notifier.add(alert),
        );
      },
      child: ListTile(
        dense: true,
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
          '${FuelType.fromString(alert.fuelType).displayName} ≤ '
          '${PriceFormatter.formatPrice(alert.threshold)} '
          '· ${alert.radiusKm.round()} km',
        ),
        // #2117 — platform-adaptive switch glyph.
        trailing: Switch.adaptive(
          value: alert.enabled,
          onChanged: (_) {
            ref.read(radiusAlertsProvider.notifier).toggle(alert.id);
          },
        ),
      ),
    );
  }
}
