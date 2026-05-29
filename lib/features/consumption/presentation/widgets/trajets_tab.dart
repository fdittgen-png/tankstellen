// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/responsive_search_layout.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/obd2/obd2_connection_errors.dart';
import '../../data/trip_history_repository.dart';
import '../../domain/services/monthly_insights_aggregator.dart';
import '../../providers/trip_history_provider.dart';
import '../../providers/trip_recording_provider.dart';
import '../obd2_connection_error_l10n.dart';
import '../screens/trip_recording_screen.dart';
import '../screens/trajets_map_screen.dart';
import 'maintenance_suggestion_card.dart';
import 'monthly_insights_card.dart';
import 'obd2_adapter_picker.dart';
import 'shared_trips_section.dart';
import 'trajet_row.dart';
import 'trip_start_progress.dart';
import '../../../../core/logging/error_logger.dart';

/// Trajets tab body on the Consumption screen (#889).
///
/// Top of the tab shows a primary "Start recording" CTA that kicks
/// off [TripRecording.startTrip]. The rest is a list of past trips
/// from [tripHistoryListProvider], filtered to the active vehicle
/// when one is available (otherwise every logged trip is shown).
///
/// Tap a row -> pushes `/trip/:id` (placeholder detail screen lives
/// in #890's full impl; #889 lands the route so the tap works).
class TrajetsTab extends ConsumerStatefulWidget {
  /// Id of the active vehicle. When non-null, the trip list is
  /// filtered down to trips recorded against this vehicle. When null
  /// (no active vehicle), the list still renders every persisted
  /// trip — avoids an empty Trajets tab just because the user hasn't
  /// flipped their active vehicle.
  final String? vehicleId;

  const TrajetsTab({super.key, this.vehicleId});

  @override
  ConsumerState<TrajetsTab> createState() => _TrajetsTabState();
}

class _TrajetsTabState extends ConsumerState<TrajetsTab> {
  /// Non-null while the start flow is running. Drives the inline
  /// [TripStartProgress] card that replaces the disabled button so
  /// the user gets visible feedback during the silent BLE-connect /
  /// odometer-read window instead of staring at a frozen screen.
  TripStartStage? _startStage;

  bool get _starting => _startStage != null;

  Future<void> _onStartRecording() async {
    if (_starting) return;
    setState(() => _startStage = TripStartStage.connectingAdapter);
    try {
      final notifier = ref.read(tripRecordingProvider.notifier);
      // #2025 — when the user has disabled "Require OBD2 for trip
      // recording" in feature management, bypass the adapter picker
      // and start a GPS-only trajet immediately. The recording screen
      // displays distance + speed from Geolocator; engine fields stay
      // null and the persisted trip carries `kind: TripKind.gpsOnly`.
      final flags = ref.read(enabledFeaturesProvider);
      final obd2Required = flags.contains(Feature.obd2Optional);
      if (!obd2Required) {
        final outcome = await notifier.startGpsOnly();
        if (!mounted) return;
        await Navigator.of(context).push<TripSaveResult?>(
          MaterialPageRoute(
            builder: (_) => const TripRecordingScreen(),
          ),
        );
        // `outcome` is informational here — the recording screen
        // handles both the freshly-started and already-active cases
        // the same way (its build reads from the provider).
        if (outcome == StartTripOutcome.alreadyActive) return;
        return;
      }
      final outcome = await notifier.startTrip();
      if (!mounted) return;
      if (outcome == StartTripOutcome.alreadyActive) {
        // A trajet is already running in the background — just jump
        // into the recording screen without re-connecting.
        await Navigator.of(context).push<TripSaveResult?>(
          MaterialPageRoute(
            builder: (_) => const TripRecordingScreen(),
          ),
        );
        return;
      }
      // `started` would only happen if we'd handed a service in — we
      // didn't. `needsPicker` is the expected path here: surface the
      // picker, then hand the resulting service back to the provider
      // (same pattern as AddFillUpScreen).
      //
      // #1188 — when the active vehicle has an adapter paired, the
      // picker takes a silent fast path: it tries `connectByMac` and
      // only opens the modal sheet when the connect fails. Plumbing
      // both the MAC and the display name lets the picker surface a
      // concrete fallback snackbar ("Couldn't reach 'X' …") rather
      // than a generic message.
      final activeVehicle = ref.read(activeVehicleProfileProvider);
      final service = await showObd2AdapterPicker(
        context,
        pinnedMac: activeVehicle?.obd2AdapterMac,
        pinnedAdapterName: activeVehicle?.obd2AdapterName,
      );
      if (service == null || !mounted) return;
      setState(() => _startStage = TripStartStage.readingVehicleData);
      await notifier.start(service);
      if (!mounted) return;
      setState(() => _startStage = TripStartStage.startingRecording);
      await Navigator.of(context).push<TripSaveResult?>(
        MaterialPageRoute(
          builder: (_) => const TripRecordingScreen(),
        ),
      );
    } on Obd2ConnectionError catch (e, st) { // ignore: unused_catch_stack
      if (mounted) {
        SnackBarHelper.showError(
            context, e.localizedMessage(AppLocalizations.of(context)));
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'TrajetsTab._onStartRecording'}));
    } finally {
      if (mounted) setState(() => _startStage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final trips = ref.watch(tripHistoryListProvider);
    final vehicles = ref.watch(vehicleProfileListProvider);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    // Filter to the active vehicle when one is set (#889). Keep every
    // trip when there is no active vehicle so the tab isn't silently
    // empty just because the profile selector hasn't been used.
    final filteredUnsorted = widget.vehicleId == null
        ? trips.toList(growable: false)
        : trips
            .where((t) =>
                t.vehicleId == null || t.vehicleId == widget.vehicleId)
            .toList(growable: false);
    // Defensive sort: `TripHistoryRepository.loadAll` already returns
    // newest-first, but we don't want to assume the provider was
    // populated by the repo path (tests, future sync sources). Sort
    // by `startedAt` descending here so the UI contract is tab-level.
    final filtered = List<TripHistoryEntry>.from(filteredUnsorted)
      ..sort((a, b) {
        final ax = a.summary.startedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bx = b.summary.startedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bx.compareTo(ax);
      });

    final stage = _startStage;
    // When a trip is already recording in the background (#1237), the
    // CTA changes shape: same `_onStartRecording` handler — which
    // routes through `StartTripOutcome.alreadyActive` and pushes the
    // existing recording screen — but a different label + icon so the
    // user understands tapping returns them to the live trip rather
    // than starting a new one.
    final isRecordingActive = ref.watch(tripRecordingProvider).isActive;
    // #1951 — the record CTA floats bottom-right (matching the
    // Carburant tab's "Ajouter un plein" FAB) instead of sitting at
    // the top. `heroTag: null` — it is positioned inside the body, so
    // it must not contend for a screen-level FAB hero tag.
    final recordFab = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: stage == null
          ? FloatingActionButton.extended(
              key: const Key('trajets_start_recording_button'),
              heroTag: null,
              onPressed: _onStartRecording,
              icon: Icon(
                isRecordingActive
                    ? Icons.visibility
                    : Icons.fiber_manual_record,
              ),
              label: Text(
                isRecordingActive
                    ? (l?.trajetsResumeRecordingButton ?? 'Resume recording')
                    : (l?.trajetsStartRecordingButton ?? 'Start recording'),
              ),
            )
          : TripStartProgress(
              key: const Key('trajets_start_progress'),
              stage: stage,
            ),
    );

    final Widget content;
    if (filtered.isEmpty) {
      // No owned trips — still surface any trips shared WITH the user
      // (#2240) below the empty-state so a recipient who hasn't recorded
      // anything themselves isn't left staring at "No trips yet". The
      // EmptyState's topBiased layout uses Spacer (flex), so it must sit
      // in a bounded-height Expanded, not a scroll view.
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: EmptyState(
              key: const Key('trajets_empty_state'),
              icon: Icons.route_outlined,
              title: l?.trajetsEmptyStateTitle ?? 'No trips yet',
              subtitle: l?.trajetsEmptyStateBody ??
                  'Tap Start recording to begin logging your drives.',
              topBiased: true,
            ),
          ),
          const SharedTripsSection(),
        ],
      );
    } else {
      // Aggregate the (already vehicle-filtered) trips into the
      // monthly-insights summary. Aggregator is pure + cheap; running
      // it on every rebuild keeps the card in lock-step with the
      // visible trip list.
      final monthlySummary =
          aggregateMonthlyInsights(filtered, DateTime.now());
      final bottomInset = 88 + MediaQuery.of(context).viewPadding.bottom;

      final trajetsList = ListView.builder(
        key: const Key('trajets_list'),
        padding: EdgeInsets.only(top: 4, bottom: bottomInset),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final entry = filtered[index];
          final vehicle = entry.vehicleId == null
              ? activeVehicle
              : vehicles
                      .where((v) => v.id == entry.vehicleId)
                      .firstOrNull ??
                  activeVehicle;
          return TrajetRow(
            entry: entry,
            vehicle: vehicle,
            l: l,
            theme: theme,
            onTap: () => context.push('/trip/${entry.id}'),
          );
        },
      );

      // #2030 — "View all on map" action. Discoverable inline (one
      // tap reaches it) and lands the user on a new screen that
      // overlays every visible trajet's polyline + offers an
      // aggregate GPX export.
      final mapAction = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            key: const Key('trajets_view_all_on_map'),
            icon: const Icon(Icons.map_outlined),
            label: Text(
              l?.trajetsViewAllOnMap ?? 'View all on map',
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TrajetsMapScreen(
                    tripIds:
                        filtered.map((e) => e.id).toList(growable: false),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // #2018 + #2030 — landscape / tablet split: left = monthly-insights
      // + maintenance suggestions + "view all on map" action, right =
      // trajets list. Narrow screens fall back to a single column with
      // the same vertical order.
      if (isWideScreen(context)) {
        content = Row(
          children: [
            // 2:3 flex on landscape so the trajets list (the dense
            // data) gets more room than the mostly-static insights
            // panel. Prior 1:1 split wasted half the screen on the
            // sparse left side per the 2026-05-24 screenshots.
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: 4, bottom: bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MonthlyInsightsCard(summary: monthlySummary),
                    const MaintenanceSuggestionList(),
                    mapAction,
                    const SharedTripsSection(),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(flex: 3, child: trajetsList),
          ],
        );
      } else {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MonthlyInsightsCard(summary: monthlySummary),
            const MaintenanceSuggestionList(),
            mapAction,
            const SharedTripsSection(),
            Expanded(child: trajetsList),
          ],
        );
      }
    }

    return Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          right: 12,
          bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: recordFab,
          ),
        ),
      ],
    );
  }
}

