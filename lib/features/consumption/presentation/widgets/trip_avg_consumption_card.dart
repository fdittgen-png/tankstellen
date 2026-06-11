// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/gps_calibration_matrix.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../../obd2/api.dart';
import 'gps_matrix_maturity_badge.dart';

/// Live **Average consumption** card for the trip-recording screen
/// (#2391 / Epic #2385 — GPS-only live fuel consumption).
///
/// One card, three honest display modes — chosen by the data shape, not
/// a feature flag (a hybrid trip whose OBD2 dropped mid-drive falls into
/// the GPS branch until the adapter reconnects, which matches the
/// driver's mental model "I have no measured fuel-rate right now"):
///
///  1. **Broken-MAP override** ([brokenMapOverride] non-null) — the
///     host screen has hard-disabled the live MAP-derived figure and
///     resolved a receipt-derived per-vehicle average instead. Shown
///     verbatim, no `~`, no maturity badge (it isn't a GPS estimate).
///  2. **Measured (OBD2)** — [TripLiveReading.liveAvgLPer100Km] is
///     non-null: a real fuel-rate signal. Rendered plainly, **no** `~`
///     and **no** maturity badge — measured data carries full
///     confidence and must never be mistaken for an estimate.
///  3. **GPS-only estimate** — no measured signal but
///     [TripLiveReading.gpsEstimatedAvgLPer100Km] is non-null: the
///     calibrated physics road-load running average. Rendered with a
///     leading `~` (per ADR 0012/0013 — `~` marks every model-imputed
///     figure as an estimate) **plus** the [GpsMatrixMaturityBadge] so
///     the driver reads it with the matching confidence (cold →
///     warming → converged), and an info tooltip explaining the band.
///
/// Before the estimator warms up (too few moving samples) every figure
/// is null, so the card shows a muted `—` placeholder and no badge —
/// graceful, never a fabricated number.
class TripAvgConsumptionCard extends ConsumerWidget {
  const TripAvgConsumptionCard({
    super.key,
    required this.live,
    this.brokenMapOverride,
  });

  /// The current live reading, or null before the first fix lands.
  final TripLiveReading? live;

  /// Pre-resolved receipt-derived L/100 km string when the active
  /// vehicle's broken-MAP belief is in the hard-disable band; null in
  /// every other band. When non-null it wins over both the measured
  /// and the GPS-estimated branches (the host screen owns this
  /// resolution so the widget stays free of fill-up-history reads).
  final String? brokenMapOverride;

  /// Leading estimate marker — a literal glyph, not translatable.
  // i18n-ignore: ADR 0012 estimate marker, language-neutral
  static const String _tilde = '~';

  /// The single source of truth for the average's display value and
  /// whether it is a GPS-only estimate, given a [live] reading and an
  /// optional [brokenMapOverride]. Mode selection (see class doc):
  /// override → measured → estimate → placeholder.
  ///
  /// Extracted so an alternate presentation — e.g. the #2903 landscape
  /// 2×2 grid tile, which renders the average as a big centred figure
  /// rather than this label/value Row — reuses the exact same decision
  /// instead of duplicating it.
  static ({String value, bool isEstimate}) resolveDisplay(
    TripLiveReading? live, {
    String? brokenMapOverride,
  }) {
    final measured = live?.liveAvgLPer100Km;
    final estimated = live?.gpsEstimatedAvgLPer100Km;
    final override = brokenMapOverride;
    if (override != null) {
      return (value: override, isEstimate: false);
    } else if (measured != null) {
      return (
        value: UnitFormatter.formatConsumption(measured, isEv: false),
        isEstimate: false,
      );
    } else if (estimated != null) {
      return (
        value:
            '$_tilde${UnitFormatter.formatConsumption(estimated, isEv: false)}',
        isEstimate: true,
      );
    }
    return (value: '—', isEstimate: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = live;

    // Mode selection (override → measured → estimate) lives in the
    // shared resolver so the landscape grid tile stays in sync.
    final display = resolveDisplay(r, brokenMapOverride: brokenMapOverride);
    final value = display.value;
    final isEstimate = display.isEstimate;

    // The maturity badge + estimate tooltip only ride along the GPS
    // estimate branch; the active vehicle's calibration matrix drives
    // which tier (cold/warming/converged) shows. A null vehicle/matrix
    // cold-starts so a fresh install still shows an honest "cold" badge.
    final matrix = isEstimate ? _resolveMatrix(ref) : null;

    final trailing = <Widget>[
      if (isEstimate)
        Tooltip(
          key: const Key('tripAvgEstimateTooltip'),
          message: l?.tripAvgGpsEstimateTooltip ??
              'GPS estimate (~) — no fuel sensor on this trip. The figure '
                  'is modelled from speed + your vehicle\'s calibration; '
                  'accuracy improves as the matrix matures.',
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      if (matrix != null) ...[
        const SizedBox(width: 6),
        GpsMatrixMaturityBadge(matrix: matrix),
        const SizedBox(width: 8),
      ],
      Text(
        value,
        key: const Key('tripAvgConsumptionValue'),
        style: theme.textTheme.titleLarge
            ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    ];

    return Card(
      key: const Key('tripAvgConsumptionCard'),
      margin: EdgeInsets.zero,
      // #2764 — an explicit Row (not a ListTile title/trailing split):
      // ListTile hands the wide trailing Row (tooltip + badge + value)
      // its full intrinsic width, squeezing the label to ~1 char so it
      // wrapped one letter per line. The label now lives in an
      // `Expanded` that ellipsizes, and the trailing keeps its min width.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.eco, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l?.tripMetricAvgConsumption ?? 'Avg',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: trailing,
            ),
          ],
        ),
      ),
    );
  }

  /// The active vehicle's [GpsCalibrationMatrix], cold-starting when the
  /// vehicle has none yet (or no vehicle / provider graph is wired —
  /// the read is guarded so a test harness without the vehicle providers
  /// still renders an honest cold badge rather than throwing).
  GpsCalibrationMatrix _resolveMatrix(WidgetRef ref) {
    try {
      final vehicle = ref.watch(activeVehicleProfileProvider);
      return vehicle?.gpsCalibration ?? GpsCalibrationMatrix.coldStart();
    } catch (_) {
      return GpsCalibrationMatrix.coldStart();
    }
  }
}
