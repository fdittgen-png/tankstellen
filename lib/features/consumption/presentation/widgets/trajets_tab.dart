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
import 'maintenance_suggestion_card.dart';
import 'monthly_insights_card.dart';
import 'obd2_adapter_picker.dart';
import 'recording_start_coordinator.dart';
import 'edit_virtual_trajet_sheet.dart';
import 'shared_trips_section.dart';
import 'trajet_row.dart';

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
  /// #2274 — owns the pre-warm (concern 3) + start-now-connect-later
  /// (concern 2) orchestration. Extracted into its own object so this
  /// widget stays under the 400-line cap (#1680).
  final RecordingStartCoordinator _starter = RecordingStartCoordinator();

  @override
  void initState() {
    super.initState();
    // #2274 concern 3 — kick the BLE pre-warm after the first frame so
    // it never competes with the tab's initial layout, and read
    // providers off a post-frame callback where `ref` is safe to use.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _starter.maybePrewarm(ref));
  }

  @override
  void dispose() {
    _starter.dispose();
    super.dispose();
  }

  Future<void> _onStartRecording() async {
    // #2274 concern 2 — re-entrancy guard. A connecting start is already
    // in flight (the recording screen is up in its connecting view), so
    // ignore a second CTA tap. The visible progress now lives on the
    // recording screen rather than an inline card on this tab.
    if (ref.read(tripRecordingProvider).isConnecting) return;
    final notifier = ref.read(tripRecordingProvider.notifier);
    // #2025 — when the user has disabled "Require OBD2 for trip
    // recording" in feature management, bypass the adapter picker
    // and start a GPS-only trajet immediately. The recording screen
    // displays distance + speed from Geolocator; engine fields stay
    // null and the persisted trip carries `kind: TripKind.gpsOnly`.
    final flags = ref.read(enabledFeaturesProvider);
    final obd2Required = flags.contains(Feature.obd2Optional);
    if (!obd2Required) {
      await notifier.startGpsOnly();
      if (!mounted) return;
      await Navigator.of(context).push<TripSaveResult?>(
        MaterialPageRoute(
          builder: (_) => const TripRecordingScreen(),
        ),
      );
      return;
    }
    // A trajet already running in the background — just jump back into
    // the live recording screen without re-connecting.
    if (ref.read(tripRecordingProvider).isActive) {
      await Navigator.of(context).push<TripSaveResult?>(
        MaterialPageRoute(
          builder: (_) => const TripRecordingScreen(),
        ),
      );
      return;
    }
    // #2274 concern 2 — start-now-connect-later. Enter the transient
    // connecting phase and push the recording screen IMMEDIATELY (just
    // like the GPS-only path above), then run the connect + prime in the
    // background with the inline TripStartProgress resolving in-place on
    // the recording screen. The user lands in the recording mode at once
    // and the activity is foreground+active before they can leave to
    // Maps (which makes the onUserLeaveHint auto-PiP — concern 4 — fire
    // reliably). Previously the connect blocked here and the screen only
    // pushed after connect+prime completed.
    notifier.enterConnecting();
    // Fire the connect concurrently — do NOT await before pushing, or
    // the screen wouldn't open until the connect finished (the old
    // behaviour). The coordinator owns its own error surfacing + teardown.
    unawaited(_starter.connectAndStart(
      ref,
      notifier: notifier,
      isMounted: () => mounted,
      openPicker: () {
        // #1188 — silent `connectByMac` fast path for a paired adapter;
        // the picker opens the modal sheet only when that fails. Plumbing
        // both the MAC + display name lets it surface a concrete fallback
        // snackbar ("Couldn't reach 'X' …") rather than a generic one.
        final activeVehicle = ref.read(activeVehicleProfileProvider);
        return showObd2AdapterPicker(
          context,
          pinnedMac: activeVehicle?.obd2AdapterMac,
          pinnedAdapterName: activeVehicle?.obd2AdapterName,
        );
      },
      onConnectionError: (error) {
        // Only an OBD2 connection error carries user-facing copy; other
        // failures are logged by the coordinator and stay silent.
        if (error is Obd2ConnectionError && mounted) {
          SnackBarHelper.showError(
              context, error.localizedMessage(AppLocalizations.of(context)));
        }
      },
    ));
    await Navigator.of(context).push<TripSaveResult?>(
      MaterialPageRoute(
        builder: (_) => const TripRecordingScreen(),
      ),
    );
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

    // When a trip is already recording in the background (#1237), the
    // CTA changes shape: same `_onStartRecording` handler — which jumps
    // back into the live recording screen — but a different label + icon
    // so the user understands tapping returns them to the live trip
    // rather than starting a new one.
    final recordingState = ref.watch(tripRecordingProvider);
    final isRecordingActive = recordingState.isActive;
    // #2274 concern 2 — while a start is connecting, the recording
    // screen is already foreground showing the inline progress; reflect
    // that on the CTA too so a glance at the tab matches.
    final isConnecting = recordingState.isConnecting;
    // #1951 — the record CTA floats bottom-right (matching the
    // Carburant tab's "Ajouter un plein" FAB) instead of sitting at
    // the top. `heroTag: null` — it is positioned inside the body, so
    // it must not contend for a screen-level FAB hero tag.
    final recordFab = FloatingActionButton.extended(
      key: const Key('trajets_start_recording_button'),
      heroTag: null,
      onPressed: isConnecting ? null : _onStartRecording,
      icon: Icon(
        isRecordingActive || isConnecting
            ? Icons.visibility
            : Icons.fiber_manual_record,
      ),
      label: Text(
        isConnecting
            ? (l?.tripStartProgressConnectingAdapter ??
                'Connecting to OBD2 adapter…')
            : isRecordingActive
                ? (l?.trajetsResumeRecordingButton ?? 'Resume recording')
                : (l?.trajetsStartRecordingButton ?? 'Start recording'),
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
                : () => context.push('/trip/${entry.id}'),
          );
        },
      );

      // #2018 — landscape / tablet split: left = monthly-insights
      // + maintenance suggestions, right = trajets list. Narrow screens
      // fall back to a single column with the same vertical order.
      // #2374 — the "View all on map" action moved to the AppBar.
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

