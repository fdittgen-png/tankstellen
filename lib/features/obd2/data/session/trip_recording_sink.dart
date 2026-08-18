// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/driving_coaching_hint.dart';
import '../../domain/trip_live_reading.dart';

/// #3743 (epic item 2) — obd2-side seam for [TripRecordingController]'s
/// consumption-feature touchpoints, so the controller depends on
/// interfaces it OWNS instead of reaching into `features/consumption`.
///
/// The #2506 GPS-physics estimate + coaching overlay is the first
/// inverted touchpoint: the controller only ever calls [overlay] per
/// emit tick and reads the two final-estimate getters at trip stop, so
/// this interface is that exact surface — expressed purely in obd2
/// ([TripLiveReading]) and kernel ([DrivingCoachingHint]) types.
/// Consumption's `GpsLiveEstimateFolder` implements it and is injected
/// at the existing wiring point (`Obd2RecordingPipeline`), keeping the
/// anti-divergence guarantee (one folding implementation shared with the
/// GPS-only pipeline) with the dependency arrow inverted.
abstract interface class TripGpsEstimateOverlay {
  /// Overlay the GPS-physics live estimate + coaching onto [base] for a
  /// tick where no fuel-rate PID was measurable. Returns the reading
  /// with the `gpsEstimated*` fields filled plus the computed coaching
  /// hint for the caller to publish.
  ({TripLiveReading reading, DrivingCoachingHint? coachingHint}) overlay({
    required TripLiveReading base,
    required DateTime now,
    required double effectiveSpeedKmh,
    required double? rpm,
    required double? altitudeM,
  });

  /// Final trip-average estimate (L/100 km) accumulated by the folder,
  /// stamped onto the summary when NO measured fuel exists (#3576).
  double? get finalAvgLPer100Km;

  /// Final estimated litres burned, same stamping rule as
  /// [finalAvgLPer100Km].
  double? get finalFuelLiters;
}
