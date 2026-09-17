// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/widgets/service_status_banner.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/help_banner.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/price_alert.dart';
import '../../domain/entities/radius_alert.dart';
import '../../providers/alert_notifications_blocked_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/opportunity_feed_provider.dart';
import '../../providers/radius_alerts_provider.dart';
import 'alert_station_picker_sheet.dart';
import 'alert_statistics_card.dart';
import 'alerts_best_effort_note.dart';
import 'alerts_last_checked_footer.dart';
import 'alerts_list_tiles.dart';
import 'alerts_notifications_off_banner.dart';
import 'alerts_section_chrome.dart';
import 'opportunity_feed_section.dart';
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
        // #4154 — the feed is a plain read of a row the background scan
        // writes, so a pull re-reads what the last scan left.
        ref.invalidate(opportunityFeedProvider);
        // #4335 — and the OS notification settings may have changed.
        ref.invalidate(alertNotificationsBlockedProvider);
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
        // #4154 — the engine runs whether or not the user configured
        // anything, so its findings belong here too — but ONLY when it
        // has some. #3951 collapsed this branch to one [EmptyState] and
        // one primary action on purpose, and a second empty state
        // stacked above it is exactly the chrome that decision removed.
        if (ref.watch(opportunityFeedProvider).isNotEmpty) ...[
          SectionHeader(title: l10n.opportunitiesSectionTitle),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: OpportunityFeedSection(hideWhenEmpty: true),
          ),
          const SizedBox(height: Spacing.lg),
        ],
        EmptyState(
          icon: Icons.notifications_none_outlined,
          title: l10n.alertsEmptyTitle,
          subtitle: l10n.alertsEmptySubtitle,
          // #2857 — the same favorite-station picker the section header's
          // "+" opens; on selection it shows the same [StationAlertCreateSheet]
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
        // #4335 — first, when the OS will not let any of these alerts
        // reach the user: everything below is moot until that is fixed.
        const AlertsNotificationsOffBanner(),
        // The one-time swipe/toggle tip the Favorites tab used to show
        // above its list — kept with the list it explains.
        if (alerts.isNotEmpty)
          HelpBanner(
            storageKey: StorageKeys.helpBannerAlerts,
            icon: Icons.notifications_active_outlined,
            message: l10n.helpBannerAlerts,
          ),
        // ── Opportunities (#4154) ───────────────────────────────────
        // First, because this is what HAPPENED. The two lists below are
        // what the user SET UP, and a screen that leads with
        // configuration asks them to remember what they asked for.
        //
        // Only when there is something, though: this is still a
        // configuration screen, and an empty note above the lists the
        // user came for buries them for no gain. The empty state lands
        // with the screen restructure, where the feed IS the screen.
        if (ref.watch(opportunityFeedProvider).isNotEmpty) ...[
          SectionHeader(title: l10n.opportunitiesSectionTitle),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: OpportunityFeedSection(hideWhenEmpty: true),
          ),
          const SizedBox(height: Spacing.lg),
        ],
        const AlertStatisticsCard(),
        // ── Station alerts ──────────────────────────────────────────
        SectionHeader(
          title: l10n.alertsStationSectionTitle,
          count: alerts.length,
          addTooltip: l10n.alertsStationAdd,
          onAdd: () => AlertStationPickerSheet.addStationAlert(context, ref),
        ),
        if (alerts.isEmpty)
          SectionEmpty(
            icon: Icons.notifications_off_outlined,
            text: l10n.noPriceAlertsHint,
          )
        else
          GroupedAlertsCard(
            children: [
              for (final a in alerts)
                AlertListTile(key: ValueKey(a.id), alert: a),
            ],
          ),
        const SizedBox(height: Spacing.lg),
        // ── Zone / radius alerts (#578 phase 2) ─────────────────────
        SectionHeader(
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
            return GroupedAlertsCard(
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
