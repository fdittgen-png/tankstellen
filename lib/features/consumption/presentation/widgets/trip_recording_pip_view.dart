// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/services/approach_detector.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/driving_coaching.dart';
import '../../providers/trip_recording_provider.dart';

/// The compact view rendered when the OS shrinks the app into a
/// Picture-in-Picture tile (#2068 — replaces the prior dense
/// one-row layout from #1977 with a single huge L/100 km figure).
///
/// Layout:
///
/// ```
/// ┌──────────────────────┐
/// │       5.8            │  ← `displayLarge`-sized L/100 km
/// │     L/100 km         │  ← `labelMedium` unit caption
/// │  12.4 km · 8:32      │  ← compact distance + duration row
/// └──────────────────────┘
/// ```
///
/// On a GPS-only trajet (no OBD2 fuel-rate samples) the big figure is
/// the live physics estimate rendered as `~X.X L/100 km` once the
/// estimator has warmed up (#2390 / Epic #2385) — the leading `~` flags
/// it an estimate per ADR 0012. Before the estimate lands (warm-up) the
/// hero stays consumption-FRAMED — a bare `~` under the same "est.
/// L/100 km" caption (#2601) — so the per-100 km figure always leads;
/// distance and elapsed are demoted to the secondary row, never the hero.
///
/// The widget is paint-only — it does not own the recording state.
/// The caller passes in the live [TripRecordingState] and a band
/// palette (background / foreground) that's already been resolved for
/// the current consumption band.
class TripRecordingPipView extends StatelessWidget {
  final TripRecordingState state;
  final Color backgroundColor;
  final Color foregroundColor;

  /// Optional approach-detector state (#2084 / Epic #2065). When set
  /// to [ApproachInRadius] or [ApproachLeaving], the PiP tile flips
  /// from the default huge-L/100-km layout to a huge-price layout
  /// for the driver's fuel type — see [_buildApproachPriceLayout].
  /// Null in every other state collapses to the existing layout.
  final ApproachState? approachState;

  /// Driver's preferred fuel type — resolved by the caller from
  /// (vehicle's fuel, falling back to profile's preferred). Used by
  /// the approach-price layout to pick the right price column off
  /// the in-radius station. Falls back to E10 when null.
  final FuelType? fuelType;

  const TripRecordingPipView({
    super.key,
    required this.state,
    required this.backgroundColor,
    required this.foregroundColor,
    this.approachState,
    this.fuelType,
  });

  @override
  Widget build(BuildContext context) {
    // #2084 — approach mode wins over the default L/100 km view.
    final approach = approachState;
    if (approach is ApproachInRadius || approach is ApproachLeaving) {
      return _buildApproachPriceLayout(context, approach!);
    }

    return _buildDefaultLayout(context);
  }

  /// Default PiP layout (no approach radius hit) — the hero slot is
  /// **always consumption** (#2601): measured L/100 km, a live estimate,
  /// or a warm-up placeholder. The user repeatedly asked for the per-100
  /// km figure to lead, so elapsed (and distance) never take the hero —
  /// they live in the secondary row. Three consumption states, in order:
  ///
  /// 1. **OBD2 live fuel rate** → huge L/100 km (or L/h on idle).
  /// 2. **GPS-only live estimate** (#2390) → huge **`~X.X`** under the
  ///    dedicated localized **`est. L/100 km`** caption (#2393), distinct
  ///    from the OBD2 branch's bare `L/100 km`. The leading `~` (a literal
  ///    glyph) marks it an estimate per ADR 0012; the figure block carries
  ///    the approximate-explanation tooltip + a11y label. The value comes
  ///    from `gpsEstimatedLPer100Km` (moving GPS-only trajet, warmed up).
  /// 3. **Warm-up — no rate, estimate not landed** (#2601) → a bare **`~`**
  ///    placeholder under the same `est. L/100 km` caption (`~` already
  ///    reads as "modelled" per ADR 0012, so it reuses the estimate
  ///    tooltip + semantics).
  ///
  /// All three demote distance (when ≥ 0.1 km) + elapsed to the secondary
  /// row. A final `else` crash-guard renders a sane fallback if no live
  /// reading exists at all (shouldn't happen during an active recording).
  Widget _buildDefaultLayout(BuildContext context) {
    final l = AppLocalizations.of(context);
    final live = state.live;
    final paused = state.phase == TripRecordingPhase.paused;
    final distance = live?.distanceKmSoFar;
    final elapsed = live?.elapsed;

    // Resolve OBD2-derived live L/100 km (or L/h at idle).
    final raw = (live != null && !paused) ? formatInstantConsumption(live) : null;
    // #2390 — GPS-only live estimate (null on OBD2 trips + during the
    // estimator's warm-up). The OBD2 `raw` figure always wins over it.
    final gpsEstimate =
        (live != null && !paused) ? live.gpsEstimatedLPer100Km : null;

    final String bigFigure;
    final String bigCaption;
    final List<String> secondaryRow;
    // #2393 — true only on the GPS-estimate branch: drives the localized
    // "est." caption + the approximate-explanation tooltip / semantics
    // label. OBD2-measured branches stay false (the figure is real).
    var isEstimate = false;

    if (raw != null) {
      // Branch 1 — OBD2 live consumption is the most informative.
      bigFigure = _stripUnit(raw);
      bigCaption = _unitOf(raw);
      secondaryRow = [
        if (distance != null) '${distance.toStringAsFixed(1)} km',
        if (elapsed != null) _fmtElapsed(elapsed),
      ];
    } else if (gpsEstimate != null) {
      // Branch 2 (#2390) — GPS-only live estimate: huge `~X.X`. The
      // caption is the dedicated localized "est. L/100 km" marker
      // (#2393) so the value reads distinctly from the OBD2-measured
      // "L/100 km"; the leading `~` carries the same meaning visually.
      bigFigure = '~${gpsEstimate.toStringAsFixed(1)}';
      bigCaption = l?.tripRecordingPipEstConsumptionCaption ?? 'est. L/100 km';
      isEstimate = true;
      secondaryRow = [
        if (distance != null) '${distance.toStringAsFixed(1)} km',
        if (elapsed != null) _fmtElapsed(elapsed),
      ];
    } else if (live != null && !paused) {
      // Branch 3 (#2601) — pre-estimate warm-up: no OBD2 rate, GPS
      // estimate not landed yet. Keep the hero consumption-FRAMED (never
      // lead with elapsed). Placeholder glyph under the same "est.
      // L/100 km" caption; demote distance + elapsed to the secondary
      // row like the measured branches.
      bigFigure = '~';
      bigCaption = l?.tripRecordingPipEstConsumptionCaption ?? 'est. L/100 km';
      isEstimate = true;
      secondaryRow = [
        if (distance != null && distance >= 0.1) '${distance.toStringAsFixed(1)} km',
        if (elapsed != null) _fmtElapsed(elapsed),
      ];
    } else {
      // No data at all (shouldn't happen during an active recording,
      // but render a sane fallback rather than crashing).
      bigFigure = '0:00';
      bigCaption = l?.tripRecordingPipElapsedCaption ?? 'elapsed';
      secondaryRow = const <String>[];
    }

    // #2393 — on the GPS-estimate branch the figure + caption carry an
    // approximate-explanation tooltip (long-press) and accessibility
    // label; OBD2-measured branches render the bare figure (real value,
    // no estimate disclaimer).
    final estimateInfo = isEstimate
        ? (l?.tripRecordingEstimatedInfo ??
            'Estimated value (~) — modelled from GPS speed, not measured.')
        : null;
    Widget figureBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            bigFigure,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
              fontSize: 64,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          bigCaption,
          style: TextStyle(
            color: foregroundColor.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
    if (estimateInfo != null) {
      figureBlock = Tooltip(
        message: estimateInfo,
        child: Semantics(label: estimateInfo, child: figureBlock),
      );
    }

    return Material(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              figureBlock,
              if (secondaryRow.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < secondaryRow.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: TextStyle(
                              color: foregroundColor.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Text(
                        secondaryRow[i],
                        style: TextStyle(
                          color: foregroundColor.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (paused) ...[
                const SizedBox(height: 4),
                Text(
                  l?.tripBannerPaused ?? 'Paused',
                  style: TextStyle(
                    color: foregroundColor.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Approach-radius layout (#2084 / Epic #2065): huge price for the
  /// driver's fuel type at the targeted station + station name +
  /// distance underneath. Active when `approachState is
  /// ApproachInRadius` OR `ApproachLeaving` (Leaving keeps the price
  /// visible through the 5 s grace before the overlay collapses
  /// back to L/100 km).
  Widget _buildApproachPriceLayout(
    BuildContext context,
    ApproachState approach,
  ) {
    final l = AppLocalizations.of(context);
    final station = approach is ApproachInRadius
        ? approach.station
        : (approach as ApproachLeaving).lastStation;
    final distanceMeters =
        approach is ApproachInRadius ? approach.distanceMeters : null;
    final fuel = fuelType ?? FuelType.e10;
    final price = station.priceFor(fuel);

    final priceText = price != null
        ? PriceFormatter.formatPrice(price)
        : '—';
    final fuelLabel = fuel.displayName;

    // #2601 — tap the approach-price tile to navigate to the station in
    // the user's maps app (reuses NavigationUtils #2546). Only this layout
    // is tappable; the default L/100 km layout stays non-tappable.
    final navigateLabel = l?.navigate ?? 'Navigate';
    return Tooltip(
      message: navigateLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => NavigationUtils.openInMaps(
          station.lat,
          station.lng,
          label: station.navLabel,
        ),
        child: Material(
          color: backgroundColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      priceText,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 56,
                        height: 1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fuelLabel,
                    style: TextStyle(
                      color: foregroundColor.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    station.name.isNotEmpty ? station.name : station.brand,
                    style: TextStyle(
                      color: foregroundColor.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (distanceMeters != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      l?.approachStationDistance(
                              distanceMeters.toStringAsFixed(0)) ??
                          '${distanceMeters.toStringAsFixed(0)} m',
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Strip the trailing unit token from
  /// [formatInstantConsumption]'s output. The function returns either
  /// `"5.8 L/100"` (driving) or `"1.2 L/h"` (idle). We render the
  /// figure + unit on separate lines so the figure can grow huge.
  static String _stripUnit(String raw) {
    final idx = raw.indexOf(' ');
    return idx < 0 ? raw : raw.substring(0, idx);
  }

  /// Return just the unit suffix from `formatInstantConsumption`'s
  /// output. Appends `" km"` to the "L/100" variant so the user reads
  /// "L/100 km" — matching the standard unit caption.
  static String _unitOf(String raw) {
    if (raw.contains('L/100')) return 'L/100 km';
    if (raw.contains('L/h')) return 'L/h';
    return '';
  }

  /// Format an elapsed [Duration] so it reads as a duration, not a
  /// clock time (#2094). Pre-#2094 returned `"14:12"` which on a PiP
  /// tile next to the system clock could be mistaken for 14:12 of
  /// the day. New shapes:
  ///
  /// - Under 1 minute → `"42s"`.
  /// - Under 1 hour → `"14m 12s"`.
  /// - 1 hour or more → `"1h 14m"` (seconds drop — at hour-plus
  ///   scale the second precision is noise).
  static String _fmtElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h >= 1) return '${h}h ${m}m';
    if (d.inMinutes >= 1) return '${m}m ${s}s';
    return '${s}s';
  }
}
