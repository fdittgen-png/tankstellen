// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/trip_history_repository.dart';
import '../../../fill_ups/api.dart';
import '../../providers/trip_history_provider.dart';
import 'edit_virtual_trajet_sheet.dart';
import 'shared_trips_section.dart';
import 'trajet_row.dart';

/// Trajets tab body on the Consumption screen (#889).
///
/// A scrollable list of past trips from [tripHistoryListProvider],
/// filtered to the active vehicle when one is available (otherwise every
/// logged trip is shown). The "Start / Resume recording" FAB lives in the
/// [PageScaffold.floatingActionButton] slot (`TrajetsRecordFab`, #2494),
/// not in this body — so the list reserves [kFabScrollClearance] at the
/// bottom for it.
///
/// Tap a row -> pushes `/trip/:id` (or the edit sheet for a virtual
/// reconciliation trajet, #2444).
class TrajetsTab extends ConsumerWidget {
  /// Id of the active vehicle. When non-null, the trip list is
  /// filtered down to trips recorded against this vehicle. When null
  /// (no active vehicle), the list still renders every persisted
  /// trip — avoids an empty Trajets tab just because the user hasn't
  /// flipped their active vehicle.
  final String? vehicleId;

  const TrajetsTab({super.key, this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final trips = ref.watch(tripHistoryListProvider);
    final vehicles = ref.watch(vehicleProfileListProvider);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    // Filter to the active vehicle when one is set (#889). Keep every
    // trip when there is no active vehicle so the tab isn't silently
    // empty just because the profile selector hasn't been used.
    final filteredUnsorted = vehicleId == null
        ? trips.toList(growable: false)
        : trips
              .where((t) => t.vehicleId == null || t.vehicleId == vehicleId)
              .toList(growable: false);
    // Defensive sort: `TripHistoryRepository.loadAll` already returns
    // newest-first, but we don't want to assume the provider was
    // populated by the repo path (tests, future sync sources). Sort
    // by `startedAt` descending here so the UI contract is tab-level.
    final filtered = List<TripHistoryEntry>.from(filteredUnsorted)
      ..sort((a, b) {
        final ax =
            a.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bx =
            b.summary.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bx.compareTo(ax);
      });

    if (filtered.isEmpty) {
      // No owned trips — still surface any trips shared WITH the user
      // (#2240) below the empty-state so a recipient who hasn't recorded
      // anything themselves isn't left staring at "No trips yet". The
      // EmptyState's topBiased layout uses Spacer (flex), so it must sit
      // in a bounded-height Expanded, not a scroll view.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: EmptyState(
              key: const Key('trajets_empty_state'),
              icon: Icons.route_outlined,
              title: l.trajetsEmptyStateTitle,
              subtitle: l.trajetsEmptyStateBody,
              topBiased: true,
            ),
          ),
          const SharedTripsSection(),
        ],
      );
    }

    // Aggregate the (already vehicle-filtered) trips into the
    // monthly-insights summary. Aggregator is pure + cheap; running
    // it on every rebuild keeps the card in lock-step with the
    // visible trip list.
    // #3918 — litres re-expressed at the active vehicle's current gain.
    final monthlySummary = aggregateMonthlyInsights(filtered, DateTime.now(),
        vehicle: activeVehicle);
    // #2494 — bottom padding clears the floating record FAB hosted by
    // PageScaffold. The Scaffold lifts the FAB clear of the system inset,
    // so we must NOT add `viewPadding.bottom` on top (the old hand-rolled
    // Stack double-counted it).
    const bottomInset = kFabScrollClearance;

    Widget rowFor(BuildContext context, TripHistoryEntry entry) {
      final vehicle = entry.vehicleId == null
          ? activeVehicle
          : vehicles.where((v) => v.id == entry.vehicleId).firstOrNull ??
                activeVehicle;
      return TrajetRow(
        entry: entry,
        vehicle: vehicle,
        l: l,
        theme: theme,
        // #2444 — a virtual reconciliation trajet opens the
        // dedicated edit sheet (it has no recorded path / samples
        // to show on the trip-detail screen); a real trip routes
        // to its detail page as before.
        onTap: entry.summary.isVirtual
            ? () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => EditVirtualTrajetSheet(entry: entry),
                )
            : () => TripDetailRoute(entry.id).push<void>(context),
      );
    }

    final trajetsList = ListView.builder(
      key: const Key('trajets_list'),
      padding: const EdgeInsets.only(top: 4, bottom: bottomInset),
      itemCount: filtered.length,
      itemBuilder: (context, index) => rowFor(context, filtered[index]),
    );

    // #2018 — landscape / tablet split: left = monthly-insights
    // + maintenance suggestions, right = trajets list. Narrow screens
    // fall back to a single column with the same vertical order.
    // #2374 — the "View all on map" action moved to the AppBar.
    // #2530 — routed through the shared ResponsiveMasterDetail scaffold so
    // the breakpoint + foldable-hinge + 1:1 (medium) / 2:3 (expanded)
    // ratios live in ONE place. (`isWideScreen` == screenSizeOf != compact,
    // so the wide branch only ever hits the medium/expanded wrapper paths.)
    if (isWideScreen(context)) {
      return ResponsiveMasterDetail(
        master: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 4, bottom: bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonthlyInsightsCard(summary: monthlySummary),
              // #3648 — the recordings-vs-pump tank report (#3616) lives
              // on the Trajets tab now: everything recording-derived is
              // Trajets-only per directive; Carburant stays fill-and-tank.
              const TankReportCard(),
              const MaintenanceSuggestionList(),
              const SharedTripsSection(),
            ],
          ),
        ),
        detail: trajetsList,
      );
    }
    // Field report: the pinned cards left only a sliver of the screen
    // scrolling. ONE scroll view now carries cards AND rows — the same
    // whole-page scroll every other tab has (the wide split already
    // scrolls both panes).
    return ListView.builder(
      key: const Key('trajets_list'),
      padding: const EdgeInsets.only(top: 4, bottom: bottomInset),
      itemCount: filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonthlyInsightsCard(summary: monthlySummary),
              // #3648 — see the wide branch above.
              const TankReportCard(),
              const MaintenanceSuggestionList(),
              const SharedTripsSection(),
            ],
          );
        }
        return rowFor(context, filtered[index - 1]);
      },
    );
  }
}
