/// Provenance tags persisted on [TripSummary.distanceSource] (#800).
///
/// Extracted from `trip_recording_controller.dart` as part of the
/// #563 controller-split refactor. Exposed publicly so callers that
/// inspect a finalised [TripSummary] (eco-analytics, fill-up flow) can
/// compare against a named constant instead of a magic string.
library;

/// Final trip distance came from the car's odometer delta
/// (`odometerLatest - odometerStart`). Ground truth: km quantised to
/// the adapter's PID precision (usually 0.1 km) but otherwise exact.
const String kDistanceSourceReal = 'real';

/// Final trip distance came from [VirtualOdometer] integration of the
/// buffered 5 Hz speed samples. Estimate: accurate to a few percent
/// on a steady trip, biases low on stop-and-go because the cap drops
/// the oldest samples first.
const String kDistanceSourceVirtual = 'virtual';

/// Final trip distance came from haversine-summing the trip's recorded
/// GPS track (#1979). More accurate than [kDistanceSourceVirtual] — the
/// OBD speed sensor reads the speedometer, which over-reads true road
/// distance by a few percent — but ranked below [kDistanceSourceReal]:
/// the car's own odometer stays the ground truth when it is readable.
const String kDistanceSourceGps = 'gps';

/// Minimum number of buffered GPS fixes before the track is trusted as
/// a distance source (#1979). A handful of fixes cannot describe a
/// route; below this the recorder falls back to the virtual odometer.
const int kMinGpsFixesForDistanceSource = 10;

/// Upper bound on the speed-sample buffer used by the virtual
/// odometer (#800). At 5 Hz a 10-hour trip produces ~180 k samples —
/// the typical driving session is well under 2 hours, so 60 k (~3.3
/// hours at 5 Hz) is a generous cap that still prevents a forgotten
/// recording from eating unbounded memory. When the cap is hit we
/// drop the oldest sample; the virtual-odometer error from losing
/// the early stretch is bounded by the lost km.
const int kVirtualOdometerSampleCap = 60000;
