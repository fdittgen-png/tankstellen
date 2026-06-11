// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/services/approach_detector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../domain/driving_coaching.dart';
import '../../providers/trip_recording_provider.dart';
import 'trip_recording_pip_price_layout.dart';

/// The compact view rendered when the OS shrinks the app into a
/// Picture-in-Picture tile (#2068 — replaces the prior dense
/// one-row layout from #1977 with a single huge L/100 km figure).
///
/// Layout (top→bottom): huge L/100 km figure, the unit caption, then a
/// compact `distance · duration` secondary row. The whole stack is scaled
/// down uniformly by one outer `FittedBox` so it never clips the small
/// 2:1 tile (#2620).
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
  /// the price layouts to pick the right price column off the station.
  /// Falls back to E10 when null.
  final FuelType? fuelType;

  /// #2661 — nearest priced radar station off the polling fallback (the
  /// `nearestStationRadarProvider`, resolved by the banner). When set AND no
  /// in-radius / leaving hit is active, the tile leads with this station's
  /// price + km instead of consumption — surfacing the radar EARLIER than the
  /// (smaller) geo-fence flip. Null falls back to the consumption layout.
  final Station? radarStation;

  /// Great-circle distance to [radarStation] in metres (the radar km line +
  /// the proximity bar). Null hides the caption.
  final double? radarDistanceMeters;

  /// Radar radius in metres (`profile.approachRadiusKm * 1000`) — the
  /// proximity fill bar's "indicated radius" (#2661). Null collapses the bar.
  final double? radiusMeters;

  /// Invoked when the user taps the tile body (#2964) — the host wires this
  /// to bring the app back to the foreground in full screen. Wired by the
  /// PiP host (the banner) for every layout; null leaves the body
  /// non-tappable (plain previews / widget tests without a PiP host).
  final VoidCallback? onBodyTap;

  const TripRecordingPipView({
    super.key,
    required this.state,
    required this.backgroundColor,
    required this.foregroundColor,
    this.approachState,
    this.fuelType,
    this.radarStation,
    this.radarDistanceMeters,
    this.radiusMeters,
    this.onBodyTap,
  });

  @override
  Widget build(BuildContext context) {
    final fuel = fuelType ?? FuelType.e10;
    // #2084 — in-radius / leaving wins: lead with the locked target's price
    // (metres caption).
    final approach = approachState;
    if (approach is ApproachInRadius || approach is ApproachLeaving) {
      final station = approach is ApproachInRadius
          ? approach.station
          : (approach as ApproachLeaving).lastStation;
      final dist = approach is ApproachInRadius
          ? approach.distanceMeters
          : null;
      return TripRecordingPipPriceLayout(
        station: station,
        fuel: fuel,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        distanceMeters: dist,
        kmCaption: false,
        radiusMeters: radiusMeters,
        onBodyTap: onBodyTap,
      );
    }

    // #2661 — still approaching: if the radar found a nearest priced station,
    // lead with ITS price + km (the radar surfaces earlier than the fence).
    final radar = radarStation;
    if (radar != null) {
      return TripRecordingPipPriceLayout(
        station: radar,
        fuel: fuel,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        distanceMeters: radarDistanceMeters,
        kmCaption: true,
        radiusMeters: radiusMeters,
        onBodyTap: onBodyTap,
      );
    }

    // Nothing priced in range yet → consumption fallback (never blank).
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
    final raw = (live != null && !paused)
        ? formatInstantConsumption(live)
        : null;
    // #2390 — GPS-only live estimate (null on OBD2 trips + during the
    // estimator's warm-up). The OBD2 `raw` figure always wins over it.
    final gpsEstimate = (live != null && !paused)
        ? live.gpsEstimatedLPer100Km
        : null;

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
      bigCaption = l.tripRecordingPipEstConsumptionCaption;
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
      bigCaption = l.tripRecordingPipEstConsumptionCaption;
      isEstimate = true;
      secondaryRow = [
        if (distance != null && distance >= 0.1)
          '${distance.toStringAsFixed(1)} km',
        if (elapsed != null) _fmtElapsed(elapsed),
      ];
    } else {
      // No data at all (shouldn't happen during an active recording,
      // but render a sane fallback rather than crashing).
      bigFigure = '0:00';
      bigCaption = l.tripRecordingPipElapsedCaption;
      secondaryRow = const <String>[];
    }

    // #2393 — on the GPS-estimate branch the figure + caption carry an
    // approximate-explanation tooltip (long-press) and accessibility
    // label; OBD2-measured branches render the bare figure (real value,
    // no estimate disclaimer).
    final estimateInfo = isEstimate ? (l.tripRecordingEstimatedInfo) : null;
    Widget figureBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // #2620 — plain Text; the outer `_pipStack` FittedBox scales the
        // WHOLE stack (figure + caption + secondary row) so nothing clips.
        Text(
          bigFigure,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w800,
            fontSize: 64,
            height: 1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
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

    return _pipStack(
      l: l,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              l.tripBannerPaused,
              style: TextStyle(
                color: foregroundColor.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Shared PiP host: scales the WHOLE content stack down uniformly so the
  /// figure + caption + secondary row ALWAYS fit the small 2:1 tile without
  /// clipping (#2620). The single outer FittedBox(scaleDown) measures the
  /// column's full intrinsic size and shrinks it on both axes; Center keeps
  /// it optically centred when it already fits.
  ///
  /// #2964 — when [onBodyTap] is wired the whole tile becomes a tap target
  /// that brings the app back to the foreground in full screen (the user
  /// expects a tap on the floating window to restore full screen). Null
  /// leaves the body non-tappable (previews / widget tests without a host).
  Widget _pipStack({required Widget child, required AppLocalizations l}) {
    final body = Material(
      color: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
      ),
    );
    final onTap = onBodyTap;
    if (onTap == null) return body;
    final label = l.pipTapToRestore;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: body,
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

  /// Format an elapsed [Duration] so it reads as a duration, not a clock
  /// time (#2094 — `"14:12"` next to the system clock read as a time of
  /// day). Shapes: `"42s"` under a minute, `"14m 12s"` under an hour,
  /// `"1h 14m"` at an hour-plus (seconds drop — they're noise at that
  /// scale).
  static String _fmtElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h >= 1) return '${h}h ${m}m';
    if (d.inMinutes >= 1) return '${m}m ${s}s';
    return '${s}s';
  }
}
