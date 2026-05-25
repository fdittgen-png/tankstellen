// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/services/approach_detector.dart';
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
/// When the trip carries no OBD2 fuel-rate samples (GPS-only trajet,
/// or before the OBD2 stream produces the first reading), the figure
/// renders as `~` followed by a placeholder. The `~` prefix flags the
/// number as an estimate when the GPS-matrix estimator (#F of Epic
/// #2055) lands — until then the placeholder is a literal dash.
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

    final l = AppLocalizations.of(context);
    final live = state.live;
    final paused = state.phase == TripRecordingPhase.paused;
    final distance = live?.distanceKmSoFar;
    final elapsed = live?.elapsed;

    // The L/100 km figure: prefer the OBD2-derived instantaneous
    // consumption when available, else render the GPS-only placeholder.
    // `formatInstantConsumption` returns "5.8 L/100" or "1.2 L/h"
    // (idle) — strip the trailing unit so we can render it ourselves
    // in a smaller font below the figure.
    final raw = (live != null && !paused) ? formatInstantConsumption(live) : null;
    final figure = raw != null ? _stripUnit(raw) : '~';
    final unit = raw != null ? _unitOf(raw) : 'L/100 km';

    return Material(
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
                  figure,
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
                unit,
                style: TextStyle(
                  color: foregroundColor.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (distance != null)
                    Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  if (distance != null && elapsed != null)
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
                  if (elapsed != null)
                    Text(
                      _fmtElapsed(elapsed),
                      style: TextStyle(
                        color: foregroundColor.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
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

    return Material(
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

  static String _fmtElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }
}
