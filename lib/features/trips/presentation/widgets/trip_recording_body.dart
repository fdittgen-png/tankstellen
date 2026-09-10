// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/providers/consumption_display_provider.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../driving_score/api.dart';
import '../../../fill_ups/api.dart';
import '../../../vehicle/api.dart';
import '../../providers/trip_recording_provider.dart';
import 'broken_map_widgets.dart';
import 'minimal_drive_summary.dart';
import 'recording/live_band_header.dart';
import 'recording/recording_metric_grid.dart';
import 'recording/recording_status_strip.dart';
import 'trip_radar_card.dart';
import 'trip_recording_landscape_body.dart';
import 'trip_save_progress.dart';
import 'trip_start_progress.dart';

/// The recording screen's body: the live-drive column, the landscape
/// two-zone split, and the connecting / saving progress states.
///
/// #4037 (epic #4032) — this was a `part` mixin on the screen's State
/// (`_TripRecordingBodySections`), sharing its private scope for no
/// reason: it reads the recording state and `ref`, and writes nothing.
/// As a `ConsumerWidget` it takes what it needs as parameters, and its
/// own private helper stays private to this file.
class TripRecordingBody extends ConsumerWidget {
  const TripRecordingBody({super.key, required this.state});

  /// The recording state the screen already watched — passed in rather
  /// than re-watched so the body and the screen's title can never
  /// disagree about the phase.
  final TripRecordingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // #2548 — staged save-progress: while `stop()` runs, the screen stays
    // mounted in the transient `saving` phase showing the inline
    // TripSaveProgress card (the "wrapping up" bookend to the start
    // "warming up"); #3963 — when it resolves the screen pops straight
    // back to the Trajets list with the trip already in it.
    if (state.isSaving) {
      return Center(
        child: TripSaveProgress(
          stage: state.saveStage ?? TripSaveStage.finalizingSummary,
        ),
      );
    }

    // #2274 concern 2 — start-now-connect-later: the screen is pushed
    // immediately in the connecting phase while the BLE connect + prime
    // run underneath. Render the inline progress card (the same one the
    // trajets tab used to show) until the first live sample flips the
    // phase to recording. Centred so it reads as a "warming up" state
    // rather than an empty metrics column.
    if (state.isConnecting) {
      return Center(
        child: TripStartProgress(
          key: const Key('tripRecordingConnectingProgress'),
          stage: state.connectStage ?? TripStartStage.connectingAdapter,
          // #3335 — let the user bail out of a stuck/slow init: reset to idle
          // (the coordinator's pre-start guard tears down any link that lands
          // after this) and leave the recording screen so they can retry.
          onCancel: () {
            ref.read(tripRecordingProvider.notifier).cancelConnecting();
            if (Navigator.canPop(context)) Navigator.of(context).pop();
          },
        ),
      );
    }

    final r = state.live;

    // #1423 phase 5 — when the active vehicle's broken-MAP belief is
    // at or above 0.9, hard-disable the live L/100 km derived from
    // MAP-fallback fuel-rate and fall back to the receipt-derived
    // average for that vehicle. The chip below the value surfaces in
    // the 0.7-0.9 band as a disclaimer.
    final belief = readActiveVehicleBelief(ref);
    final band = belief == null
        ? BrokenMapBand.silent
        : brokenMapBandFor(belief.pointEstimate);
    // #2391 — the Avg card owns the measured-vs-GPS-estimate decision
    // (`~` prefix + maturity badge for GPS-only) itself; the screen only
    // resolves the broken-MAP hard-disable override (receipt-derived
    // per-vehicle average) and hands it through.
    final brokenMapOverride = band == BrokenMapBand.hardDisable
        ? (_receiptDerivedLPer100Km(ref) ?? '—')
        : null;

    // #2903 — in LANDSCAPE the driver is driving: swap the scrolling
    // portrait list for the glanceable, zero-touch two-zone split (live
    // feedback left, trip + radar right) so every key metric is visible
    // at once, large and high-contrast, with no scrolling. Orientation
    // is read the same way the shell / favorites / search screens do
    // (`MediaQuery.orientation`). Portrait is unchanged below.
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    if (isLandscape) {
      return TripRecordingLandscapeBody(
        reading: r,
        brokenMapOverride: brokenMapOverride,
        unit: ref.watch(consumptionDisplaySettingProvider).unit, // #3883
      );
    }

    // #3916 (Epic #3914) — driver-first column: the hero (the ONE live
    // consumption figure + speed + coaching cues) leads, the OBD2 / GPS
    // status strip sits directly under it, then the compact trip-figures
    // grid (with the consumption card + its fuel-source badge), and the
    // closest-station radar last. #2380 — the column scrolls rather than
    // overflowing on small phones / large text scales.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // #3959 — the band-coloured efficiency header the app-wide strip
          // used to be: on the form, not above every screen.
          const LiveBandHeader(),
          const MinimalDriveSummary(),
          const SizedBox(height: 8),
          const RecordingStatusStrip(),
          const SizedBox(height: 8),
          RecordingMetricGrid(
            reading: r,
            brokenMapOverride: brokenMapOverride,
            unit: ref.watch(consumptionDisplaySettingProvider).unit, // #3883
          ),
          const BrokenMapDisclaimerChip(),
          const SizedBox(height: 8),
          // #2380 radar card (price + station + closeness bar), now below
          // the figures. See [TripRadarCard] for the data sources.
          const TripRadarCard(),
          // #3432 — live eco-nudge SnackBars (rate-limited in the pure
          // engine; screen-mounted, so structurally foreground-only).
          const EcoNudgeListener(),
        ],
      ),
    );
  }

  /// #1423 phase 5 — receipt-derived L/100 km for the active vehicle,
  /// formatted to one decimal. Returns null when there isn't enough
  /// fill-up history to compute one (single tank or no closed plein-
  /// to-plein window). Used to fill the live-Avg metric while the
  /// broken-MAP belief is in the hard-disable band.
  String? _receiptDerivedLPer100Km(WidgetRef ref) {
    try {
      final active = ref.watch(activeVehicleProfileProvider);
      if (active == null) return null;
      final fills = ref
          .watch(fillUpListProvider)
          .where((f) => f.vehicleId == active.id)
          .toList();
      if (fills.length < 2) return null;
      final stats = ConsumptionStats.fromFillUps(fills);
      final avg = stats.avgConsumptionL100km;
      if (avg == null) return null;
      return UnitFormatter.formatConsumption(avg, isEv: false);
    } catch (e, st) {
      // A malformed fill-up set must not crash the summary card —
      // but log the cause rather than hiding it silently (#1682).
      logFailure(
        e,
        st,
        where: 'TripRecordingScreen: consumption summary calc failed',
      );
      return null;
    }
  }
}
