// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../../core/services/approach_detector.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/radar_closeness.dart';
import '../../../core/utils/station_extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';
import '../providers/trip_recording_provider.dart';
import 'driving_coaching.dart';

/// Which layout the iOS Live Activity leads with (#3170) — mirrors the
/// Android PiP tile's two faces (`TripRecordingPipView`): the default
/// consumption hero while driving, flipping to the station-price lead
/// whenever the Fuel Station Radar / approach detector has a target.
enum LiveActivityMode { recording, approach }

/// One immutable, fully-FORMATTED snapshot of what the iOS Live Activity
/// (lock screen + Dynamic Island) should show (#3170).
///
/// Every user-facing string is resolved on the Dart side (ARB pipeline /
/// the same format masks the PiP tile uses) so the Swift views stay
/// dumb renderers — the extension has no access to the app's ARB
/// catalogue, and pre-formatted strings keep the two surfaces in
/// lock-step with zero duplicated formatting logic.
@immutable
class LiveActivityContent {
  final LiveActivityMode mode;
  final bool paused;

  /// Wall-clock trip start (epoch ms, rounded to the second) — the Swift
  /// side renders a NATIVELY ticking elapsed timer off this
  /// (`Text(timerInterval:)`), so the elapsed readout never needs a
  /// channel update. Rounded so back-computing `now - elapsed` on every
  /// recorder emit doesn't jitter the content equality.
  final int startedAtEpochMs;

  /// Consumption hero ("5.8" / "~7.1" / the bare "~" warm-up glyph) +
  /// its caption ("L/100 km" / "est. L/100 km" / "L/h") — same three
  /// branches as the PiP default layout (#2601).
  final String bigFigure;
  final String bigCaption;
  final bool isEstimate;

  /// `"12.3 km"` once the trip covered ≥ 0.1 km, else null.
  final String? distanceText;

  /// Localized "Paused" chip label — always carried so a mid-flight
  /// pause never needs a string the activity doesn't have.
  final String pausedLabel;

  // Approach-mode fields (null in recording mode).
  final String? stationName;
  final String? priceText;
  final String? fuelLabel;
  final String? stationDistanceText;

  /// Radar closeness fill (0..1, fuller = closer) per the canonical
  /// [RadarCloseness.fillFor] scale. Null collapses the bar.
  final double? progress;

  const LiveActivityContent({
    required this.mode,
    required this.paused,
    required this.startedAtEpochMs,
    required this.bigFigure,
    required this.bigCaption,
    required this.isEstimate,
    required this.distanceText,
    required this.pausedLabel,
    this.stationName,
    this.priceText,
    this.fuelLabel,
    this.stationDistanceText,
    this.progress,
  });

  /// The channel payload (`tankstellen/live_activity` start/update args).
  /// Keys mirror `TripActivityAttributes.ContentState` in
  /// `ios/TankstellenWidget/TripActivityAttributes.swift` — keep the two
  /// in lock-step.
  Map<String, Object?> toChannelMap() => <String, Object?>{
        'mode': mode.name,
        'paused': paused,
        'startedAtEpochMs': startedAtEpochMs,
        'bigFigure': bigFigure,
        'bigCaption': bigCaption,
        'isEstimate': isEstimate,
        'distanceText': distanceText,
        'pausedLabel': pausedLabel,
        'stationName': stationName,
        'priceText': priceText,
        'fuelLabel': fuelLabel,
        'stationDistanceText': stationDistanceText,
        'progress': progress,
      };

  @override
  bool operator ==(Object other) =>
      other is LiveActivityContent &&
      other.mode == mode &&
      other.paused == paused &&
      other.startedAtEpochMs == startedAtEpochMs &&
      other.bigFigure == bigFigure &&
      other.bigCaption == bigCaption &&
      other.isEstimate == isEstimate &&
      other.distanceText == distanceText &&
      other.pausedLabel == pausedLabel &&
      other.stationName == stationName &&
      other.priceText == priceText &&
      other.fuelLabel == fuelLabel &&
      other.stationDistanceText == stationDistanceText &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(
        mode,
        paused,
        startedAtEpochMs,
        bigFigure,
        bigCaption,
        isEstimate,
        distanceText,
        pausedLabel,
        stationName,
        priceText,
        fuelLabel,
        stationDistanceText,
        progress,
      );
}

/// Build the Live Activity content for one trip/approach snapshot, or
/// null when no trip is active (→ the coordinator ends the activity).
///
/// Mirrors `TripRecordingPipView`'s precedence exactly (#2084 / #2661):
///
/// 1. **In-radius / leaving** → station-price lead with a metres caption
///    + the closeness fill.
/// 2. **Polling radar hit** ([radarStation]) → station-price lead with a
///    kilometres caption (the radar surfaces earlier than the fence).
/// 3. **Otherwise** → the consumption hero (OBD2 L/100 km → GPS `~`
///    estimate → warm-up `~`), same branch order as the PiP (#2601).
///
/// [l] is nullable with the project-wide `l?.key ?? 'English'` fallback
/// convention so a harness without the l10n graph still renders.
LiveActivityContent? buildLiveActivityContent({
  required TripRecordingState state,
  required ApproachState? approach,
  required Station? radarStation,
  required FuelType fuel,
  required double? radiusMeters,
  required AppLocalizations? l,
  required DateTime now,
}) {
  if (!state.isActive) return null;

  final live = state.live;
  final paused = state.phase == TripRecordingPhase.paused;
  // Round to the second so per-emit recomputation doesn't jitter equality.
  final startedAtEpochMs =
      ((now.millisecondsSinceEpoch - (live?.elapsed.inMilliseconds ?? 0)) ~/
              1000) *
          1000;
  final pausedLabel = l?.tripBannerPaused ?? 'Paused';
  final distance = live?.distanceKmSoFar;
  final distanceText = (distance != null && distance >= 0.1)
      ? '${distance.toStringAsFixed(1)} km'
      : null;

  // Resolve the consumption hero (shared by both modes — the approach
  // layouts keep it so the island's expanded view can show it secondary).
  final raw = (live != null && !paused) ? formatInstantConsumption(live) : null;
  final gpsEstimate =
      (live != null && !paused) ? live.gpsEstimatedLPer100Km : null;
  final String bigFigure;
  final String bigCaption;
  var isEstimate = false;
  if (raw != null) {
    final idx = raw.indexOf(' ');
    bigFigure = idx < 0 ? raw : raw.substring(0, idx);
    bigCaption = raw.contains('L/100') ? 'L/100 km' : 'L/h';
  } else if (gpsEstimate != null) {
    bigFigure = '~${gpsEstimate.toStringAsFixed(1)}';
    bigCaption = l?.tripRecordingPipEstConsumptionCaption ?? 'est. L/100 km';
    isEstimate = true;
  } else {
    // Warm-up / paused — keep the hero consumption-framed (#2601).
    bigFigure = '~';
    bigCaption = l?.tripRecordingPipEstConsumptionCaption ?? 'est. L/100 km';
    isEstimate = true;
  }

  LiveActivityContent approachContent(
    Station station,
    double? distMeters, {
    required bool kmCaption,
  }) {
    final price = station.priceFor(fuel);
    final String? stationDistanceText = distMeters == null
        ? null
        : kmCaption
            ? (l?.fuelStationRadarDistanceKm(
                    (distMeters / 1000.0).toStringAsFixed(1)) ??
                '${(distMeters / 1000.0).toStringAsFixed(1)} km')
            : (l?.approachStationDistance(distMeters.toStringAsFixed(0)) ??
                '${distMeters.toStringAsFixed(0)} m');
    return LiveActivityContent(
      mode: LiveActivityMode.approach,
      paused: paused,
      startedAtEpochMs: startedAtEpochMs,
      bigFigure: bigFigure,
      bigCaption: bigCaption,
      isEstimate: isEstimate,
      distanceText: distanceText,
      pausedLabel: pausedLabel,
      stationName: station.name.isNotEmpty ? station.name : station.brand,
      priceText: price != null ? PriceFormatter.formatPrice(price) : '--',
      fuelLabel: fuel.displayName,
      stationDistanceText: stationDistanceText,
      progress: (distMeters != null && radiusMeters != null)
          ? RadarCloseness.fillFor(distMeters, radiusMeters)
          : null,
    );
  }

  // 1 — in-radius / leaving wins (locked target, metres caption).
  if (approach is ApproachInRadius) {
    return approachContent(
      approach.station,
      approach.distanceMeters,
      kmCaption: false,
    );
  }
  if (approach is ApproachLeaving) {
    return approachContent(approach.lastStation, null, kmCaption: false);
  }

  // 2 — polling radar hit (km caption — surfaces earlier than the fence).
  if (radarStation != null) {
    return approachContent(
      radarStation,
      radarStation.dist > 0 ? radarStation.dist * 1000.0 : null,
      kmCaption: true,
    );
  }

  // 3 — default consumption hero.
  return LiveActivityContent(
    mode: LiveActivityMode.recording,
    paused: paused,
    startedAtEpochMs: startedAtEpochMs,
    bigFigure: bigFigure,
    bigCaption: bigCaption,
    isEstimate: isEstimate,
    distanceText: distanceText,
    pausedLabel: pausedLabel,
  );
}
