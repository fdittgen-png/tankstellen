// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/swipe_to_delete.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../ev/api.dart';
import '../../providers/charging_charts_provider.dart';
import '../../providers/charging_logs_provider.dart';
import 'charging_cost_trend_chart.dart';
import 'charging_efficiency_chart.dart';
import 'charging_log_card.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/error/error_localizer.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';

/// Body of the Charging tab on the Consumption screen.
///
/// Loads the charging-log list via [chargingLogsProvider] and renders
/// a [ChargingLogCard] per row. The list is oldest-first from the
/// store; we flip the order here so the newest session appears at the
/// top — matches the mental model of "what I most recently logged"
/// that the fuel list (sorted newest-first by [fillUpListProvider])
/// already uses.
class ChargingTab extends ConsumerWidget {
  final AsyncValue<List<ChargingLog>> async;
  final AppLocalizations l;

  const ChargingTab({super.key, required this.async, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      loading: () => const ShimmerStationList(),
      // #3989 — a localized error with a retry, not a raw `$e` in English.
      error: (e, _) => EmptyState(
        key: const Key('charging_error_state'),
        icon: Icons.error_outline,
        title: ErrorLocalizer.localize(e, l),
        actionLabel: l.retry,
        actionIcon: Icons.refresh,
        actionKey: const Key('charging_retry'),
        onAction: () => ref.invalidate(chargingLogsProvider),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return EmptyState(
            key: const Key('charging_empty_state'),
            icon: Icons.ev_station_outlined,
            title: l.noChargingLogsTitle,
            subtitle: l.noChargingLogsSubtitle,
          );
        }
        final ordered = logs.reversed.toList(growable: false);
        // #3615 — pull-to-refresh re-reads the charging-log store.
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(chargingLogsProvider),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: 8,
              bottom: 96 + MediaQuery.of(context).viewPadding.bottom,
            ),
            itemCount: ordered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Charts header — read the derived rollup providers so
                // they react to the same chargingLogsProvider we already
                // watched upstream.
                return const _ChargingChartsSection();
              }
              final log = ordered[index - 1];
              // #3682 — the shared swipe-to-delete carries the app-wide
              // delete confirmation.
              return SwipeToDelete(
                dismissKey: ValueKey('charging-${log.id}'),
                onDismissed: () {
                  final notifier = ref.read(chargingLogsProvider.notifier);
                  unawaited(notifier.remove(log.id));
                  // #3989 — the fuel tab's #3664 capture-and-restore undo:
                  // the swiped log is held here; Undo re-adds it under the
                  // same id (the store upserts), so nothing is lost for
                  // 10 seconds after a mis-swipe.
                  SnackBarHelper.showWithUndo(
                    context,
                    l.chargingLogDeletedUndoSnackbar,
                    onUndo: () => unawaited(notifier.add(log)),
                  );
                },
                child: ChargingLogCard(log: log),
              );
            },
          ),
        );
      },
    );
  }
}

/// Charts header rendered above the charging-log list (#582 phase 3).
///
/// Collapses nicely in landscape: both charts are fixed-height boxes
/// and sit inside the list's vertical scroll, so narrow widths just
/// squeeze the bars/points — they never clip.
class _ChargingChartsSection extends ConsumerWidget {
  const _ChargingChartsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cost = ref.watch(chargingMonthlyCostProvider);
    final efficiency = ref.watch(chargingMonthlyEfficiencyProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        key: const Key('charging_charts_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // #3989 — PanelCard + one focal number (this month's cost), the
          // visual grammar every other data card follows.
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.chargingCostTrendTitle, style: AppText.title(context)),
                if (_latest(cost) case final latest?)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: Text(
                      PriceFormatter.formatTotal(latest),
                      style: AppText.display(context),
                    ),
                  ),
                const SizedBox(height: Spacing.md),
                ChargingCostTrendChart(
                  key: const Key('charging_cost_trend_chart'),
                  monthlyCost: cost,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.chargingEfficiencyTitle, style: AppText.title(context)),
                if (_latest(efficiency) case final latest?)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: Text(
                      UnitFormatter.formatConsumption(latest, isEv: true),
                      style: AppText.display(context),
                    ),
                  ),
                const SizedBox(height: Spacing.md),
                ChargingEfficiencyChart(
                  key: const Key('charging_efficiency_chart'),
                  monthlyEfficiency: efficiency,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The most recent month that has a value — the card's focal number
/// (#3989). Null when every month is empty, so the card shows no number
/// rather than a fake zero.
double? _latest(Map<DateTime, double?> byMonth) {
  final months = byMonth.keys.toList()..sort();
  for (final m in months.reversed) {
    final v = byMonth[m];
    if (v != null) return v;
  }
  return null;
}
