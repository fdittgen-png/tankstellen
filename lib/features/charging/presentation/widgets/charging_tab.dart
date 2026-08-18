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
      error: (e, _) => Center(child: Text('Failed to load charging logs: $e')),
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
                  unawaited(
                    ref.read(chargingLogsProvider.notifier).remove(log.id),
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
    final theme = Theme.of(context);
    final cost = ref.watch(chargingMonthlyCostProvider);
    final efficiency = ref.watch(chargingMonthlyEfficiencyProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        key: const Key('charging_charts_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.chargingCostTrendTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  ChargingCostTrendChart(
                    key: const Key('charging_cost_trend_chart'),
                    monthlyCost: cost,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.chargingEfficiencyTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  ChargingEfficiencyChart(
                    key: const Key('charging_efficiency_chart'),
                    monthlyEfficiency: efficiency,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
