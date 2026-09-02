// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_screen.dart';

/// #3762 — the live-recording and stop-summary body sections of
/// `_TripRecordingScreenState`, split out as a `part` mixin under the
/// #1680 file-length decomposition. Move-only: behaviour preserved,
/// every member verbatim from trip_recording_screen.dart.
mixin _TripRecordingBodySections on _TripRecordingEventHandlers {
  // Owned by the State (abstract — the State's concrete method
  // satisfies this implicitly): the summary view's confirm-and-pop
  // action stays in trip_recording_screen.dart.
  void _onSave();

  Widget _buildRecording(
    BuildContext context,
    AppLocalizations l,
    TripRecordingState state,
  ) {
    // #2548 — staged save-progress: while `stop()` runs, the screen stays
    // mounted in the transient `saving` phase showing the inline
    // TripSaveProgress card (the "wrapping up" bookend to the start
    // "warming up") until `_stopped` flips it to the summary.
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

  Widget _buildSummary(
    BuildContext context,
    AppLocalizations l,
    StoppedTripResult r,
  ) {
    final s = r.summary;
    final liters = s.fuelLitersConsumed;
    // #3576 — no measured fuel: fall back to the persisted GPS-physics
    // estimate the live view showed all drive, `~`-prefixed (estimate
    // convention shared with the recording screen), instead of a dash.
    final estLiters = s.estimatedFuelLitersConsumed;
    final estAvg = s.estimatedAvgLPer100Km;
    final endKm = r.endOdometerKm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricCard(
          icon: Icons.route,
          label: l.tripMetricDistance,
          value: UnitFormatter.formatDistance(s.distanceKm, fractionDigits: 2),
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.local_gas_station,
          label: l.tripMetricFuelUsed,
          value: liters != null
              ? '${UnitFormatter.formatDecimal(liters, fractionDigits: 2)} L'
              : estLiters != null
                  ? '~${UnitFormatter.formatDecimal(estLiters, fractionDigits: 2)} L'
                  : '—',
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.eco,
          label: l.tripMetricAvgConsumption,
          value: s.avgLPer100Km != null
              ? UnitFormatter.formatConsumption(s.avgLPer100Km!, isEv: false)
              : estAvg != null
                  ? '~${UnitFormatter.formatConsumption(estAvg, isEv: false)}'
                  : '—',
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.speed,
          label: l.tripMetricOdometer,
          value: endKm == null
              ? '—'
              : UnitFormatter.formatDistance(endKm, fractionDigits: 0),
        ),
        const Spacer(),
        // #3582 — the trip is ALREADY saved by `stop()` (#1185); this
        // sheet is a confirmation, not a gate. Say so, offer Done, and
        // make the secondary action an HONEST delete of the saved entry
        // (the old "Discard" reset the UI but silently kept the trip).
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l.tripSummaryAutoSaved,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        FilledButton.icon(
          key: const Key('tripSaveButton'),
          onPressed: _onSave,
          icon: const Icon(Icons.check),
          label: Text(l.tripSummaryDone),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('tripDiscardButton'),
          onPressed: _onDeleteSavedTrip,
          child: Text(l.tripSummaryDelete),
        ),
      ],
    );
  }
}
