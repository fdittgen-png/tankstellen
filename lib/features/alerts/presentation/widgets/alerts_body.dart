// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/price_alert.dart';
import '../../domain/entities/radius_alert.dart';
import '../../providers/alert_provider.dart';
import '../../providers/radius_alerts_provider.dart';
import 'alert_station_picker_sheet.dart';
import 'alert_statistics_card.dart';
import 'alerts_best_effort_note.dart';
import 'alerts_last_checked_footer.dart';
import 'alerts_list_tiles.dart';
import 'radius_alert_create_sheet.dart';

/// The alerts page content — stats strip, station-alert section,
/// zone-alert section and the last-checked footer — as ONE reusable
/// widget (#3905).
///
/// Rendered directly by the Favorites "Price alerts" tab AND by the
/// standalone `/alerts` route (kept for deep links). Before #3905 the
/// tab showed its own duplicate empty state plus a "Radius alerts &
/// statistics" card that opened a second, near-identical screen; the
/// user had to go through two screens to reach the zone-alert form.
///
/// #3951 (Epic #3947) — the empty state collapses the chrome: with zero
/// alerts of either kind there is no 0·0·0 stats strip, no "(0)" section
/// header and no help banner — one [EmptyState], one primary action.
class AlertsBody extends ConsumerWidget {
  const AlertsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsAsyncProvider);
    final l10n = AppLocalizations.of(context);

    return alertsAsync.when(
      data: (alerts) => _AlertsList(alerts: alerts),
      loading: () => const ShimmerStationList(),
      error: (error, stackTrace) => ServiceChainErrorWidget(
        error: error,
        stackTrace: stackTrace,
        searchContext: l10n.alertsLoadErrorTitle,
        onRetry: () {
          // Invalidate both the underlying notifier and the async
          // wrapper so the read is retried from scratch.
          ref.invalidate(alertProvider);
          ref.invalidate(alertsAsyncProvider);
        },
      ),
    );
  }
}

/// The data branch: the radius section hooks into the same scroll view
/// as the per-station list. A separate `ConsumerWidget` lets each
/// section drive its own provider watch without forcing a full rebuild
/// when the other half changes.
class _AlertsList extends ConsumerWidget {
  final List<PriceAlert> alerts;

  const _AlertsList({required this.alerts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radiusAsync = ref.watch(radiusAlertsProvider);

    // #3951 — decide between the collapsed empty state and the sectioned
    // layout only once BOTH kinds are known. While the zone list is still
    // loading (first read, no previous value) keep the shimmer rather
    // than flashing an empty state that a moment later fills with rows;
    // a pull-to-refresh keeps its previous value and never lands here.
    if (alerts.isEmpty) {
      if (radiusAsync.isLoading && !radiusAsync.hasValue) {
        return const ShimmerStationList();
      }
      final radiusAlerts = radiusAsync.asData?.value;
      if (radiusAlerts != null && radiusAlerts.isEmpty) {
        return _Refreshable(ref: ref, child: const _AlertsEmptyState());
      }
    }
    return _Refreshable(
      ref: ref,
      child: _AlertsSections(alerts: alerts, radiusAsync: radiusAsync),
    );
  }
}

/// #3615 — pull-to-refresh re-evaluates both alert sections; shared by
/// the sectioned layout and the empty state so a user can always pull
/// to re-read the stores.
class _Refreshable extends StatelessWidget {
  final WidgetRef ref;
  final Widget child;

  const _Refreshable({required this.ref, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(alertsAsyncProvider);
        ref.invalidate(radiusAlertsProvider);
      },
      child: child,
    );
  }
}

/// The zero-alert state (#3951): ONE [EmptyState], ONE primary action
/// (the station-alert picker) and the zone-alert entry as a secondary
/// text button so it stays reachable without competing. The disclosures
/// ([AlertsLastCheckedFooter], [AlertsBestEffortNote]) stay below — they
/// are honesty, not chrome.
class _AlertsEmptyState extends ConsumerWidget {
  const _AlertsEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
      children: [
        EmptyState(
          icon: Icons.notifications_none_outlined,
          title: l10n.alertsEmptyTitle,
          subtitle: l10n.alertsEmptySubtitle,
          // #2857 — the same favorite-station picker the section header's
          // "+" opens; on selection it shows the same [CreateAlertDialog]
          // the station-detail app bar uses.
          actionLabel: l10n.alertsStationAdd,
          actionIcon: Icons.add_alert_outlined,
          actionKey: const Key('alerts_empty_add_station'),
          onAction: () => AlertStationPickerSheet.addStationAlert(context, ref),
        ),
        Center(
          child: TextButton.icon(
            key: const Key('alerts_empty_add_radius'),
            onPressed: () => RadiusAlertCreateSheet.show(context),
            icon: const Icon(Icons.location_searching),
            label: Text(l10n.alertsRadiusAdd),
          ),
        ),
        const AlertsLastCheckedFooter(),
        const AlertsBestEffortNote(),
      ],
    );
  }
}

/// The sectioned layout, rendered as soon as at least one alert of
/// either kind exists: stats strip, then the Station and Zone sections
/// (#2819), each with a count + an add affordance, alerts grouped inside
/// one rounded card with dense rows.
class _AlertsSections extends ConsumerWidget {
  final List<PriceAlert> alerts;
  final AsyncValue<List<RadiusAlert>> radiusAsync;

  const _AlertsSections({required this.alerts, required this.radiusAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xxl),
      children: [
        // The one-time swipe/toggle tip the Favorites tab used to show
        // above its list — kept with the list it explains.
        if (alerts.isNotEmpty)
          HelpBanner(
            storageKey: StorageKeys.helpBannerAlerts,
            icon: Icons.notifications_active_outlined,
            message: l10n.helpBannerAlerts,
          ),
        const AlertStatisticsCard(),
        // ── Station alerts ──────────────────────────────────────────
        _SectionHeader(
          title: l10n.alertsStationSectionTitle,
          count: alerts.length,
          addTooltip: l10n.alertsStationAdd,
          onAdd: () => AlertStationPickerSheet.addStationAlert(context, ref),
        ),
        if (alerts.isEmpty)
          _SectionEmpty(
            icon: Icons.notifications_off_outlined,
            text: l10n.noPriceAlertsHint,
          )
        else
          _GroupedAlertsCard(
            children: [
              for (final a in alerts)
                AlertListTile(key: ValueKey(a.id), alert: a),
            ],
          ),
        const SizedBox(height: Spacing.lg),
        // ── Zone / radius alerts (#578 phase 2) ─────────────────────
        _SectionHeader(
          title: l10n.alertsRadiusSectionTitle,
          count: radiusAsync.asData?.value.length ?? 0,
          addTooltip: l10n.alertsRadiusAdd,
          onAdd: () => RadiusAlertCreateSheet.show(context),
        ),
        radiusAsync.when(
          data: (radiusAlerts) {
            if (radiusAlerts.isEmpty) {
              return const _RadiusEmptyState();
            }
            return _GroupedAlertsCard(
              children: [
                for (final a in radiusAlerts)
                  RadiusAlertListTile(
                    key: ValueKey('radius-${a.id}'),
                    alert: a,
                  ),
              ],
            );
          },
          loading: () => const ShimmerStationList(count: 2),
          error: (error, stackTrace) => ServiceChainErrorWidget(
            error: error,
            stackTrace: stackTrace,
            searchContext: l10n.alertsLoadErrorTitle,
            onRetry: () => ref.invalidate(radiusAlertsProvider),
          ),
        ),
        // #3147 — "last checked" footer: surfaces the dedup store's
        // last-completed-scan stamp so a user can verify the background
        // scan actually runs (the alert-SLA field check).
        const AlertsLastCheckedFooter(),
        // #3169 — iOS-only honest disclosure: background alert delivery
        // on iPhone is best-effort (OS-budgeted), never Android-grade.
        // Renders nothing on other platforms.
        const AlertsBestEffortNote(),
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
      margin: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.sm),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.sm,
        Spacing.xl,
        Spacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: Spacing.lg),
          Expanded(child: Text(text, style: AppText.label(context))),
        ],
      ),
    );
  }
}

/// A section header: title + count + an add button (#2819). Shared by
/// the Station and Zone sections so both read symmetrically. #3951 — the
/// " (n)" suffix is dropped at zero: a "(0)" is chrome for an absence.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.md,
        Spacing.md,
        Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count > 0 ? '$title ($count)' : title,
              style: AppText.title(context),
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
  const _RadiusEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      child: EmptyState(
        icon: Icons.location_searching,
        title: l10n.alertsRadiusEmptyTitle,
        actionLabel: l10n.alertsRadiusEmptyCta,
        onAction: () => RadiusAlertCreateSheet.show(context),
      ),
    );
  }
}
