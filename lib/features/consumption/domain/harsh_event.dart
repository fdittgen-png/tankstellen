/// Classifies a single harsh-driving event captured by
/// [HarshEventDetector] (#2029). Replaces the old integer counters
/// with a typed list so post-trip coaching can say "harsh brake at
/// 14:23, 0.45 g, while doing 80 km/h" instead of bare "12 events".
class HarshEvent {
  /// Wall-clock timestamp the event was detected at — the trailing
  /// sample of the evaluation interval (since the derivative is
  /// computed *from* the previous anchor *to* this point).
  final DateTime timestamp;

  /// Acceleration magnitude in g. Always positive; the sign is encoded
  /// in [type] (a harsh brake is a negative m/s² internally, surfaced
  /// here as the positive magnitude).
  final double magnitudeG;

  /// Speed at the moment of the event in km/h. Surface lets post-trip
  /// review distinguish "harsh brake while doing 90 km/h on the
  /// motorway" from "harsh brake while doing 30 km/h in traffic".
  final double speedKmh;

  /// Whether the event was a brake or an acceleration.
  final HarshEventType type;

  const HarshEvent({
    required this.timestamp,
    required this.magnitudeG,
    required this.speedKmh,
    required this.type,
  });

  /// Compact JSON encoding — short keys (`t`, `m`, `s`, `k`) mirror the
  /// [TripSample] convention so per-trip JSON stays small even when a
  /// long trip carries dozens of events.
  Map<String, dynamic> toJson() => <String, dynamic>{
        't': timestamp.millisecondsSinceEpoch,
        'm': magnitudeG,
        's': speedKmh,
        'k': type.wireName,
      };

  static HarshEvent fromJson(Map<String, dynamic> j) => HarshEvent(
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (j['t'] as num).toInt(),
          isUtc: true,
        ),
        magnitudeG: (j['m'] as num).toDouble(),
        speedKmh: (j['s'] as num).toDouble(),
        type: HarshEventType.fromWireName(j['k'] as String?),
      );
}

enum HarshEventType {
  brake,
  acceleration;

  String get wireName => switch (this) {
        HarshEventType.brake => 'brake',
        HarshEventType.acceleration => 'accel',
      };

  static HarshEventType fromWireName(String? s) => switch (s) {
        'accel' => HarshEventType.acceleration,
        _ => HarshEventType.brake,
      };
}

/// Earth gravity constant used to convert m/s² → g. Single source of
/// truth so [HarshEventDetector] and the future raw-accelerometer
/// pipeline agree on the unit conversion.
const double standardGravityMps2 = 9.80665;

/// Pure function: derives instantaneous acceleration in **g** from two
/// consecutive speed samples (#2022). Returns null when [dtSeconds] is
/// zero or negative (out-of-order timestamps); the caller decides
/// whether to suppress the event entirely.
///
/// Sign convention: positive = acceleration, negative = braking. The
/// caller is responsible for taking the magnitude when feeding into a
/// [HarshEvent], which carries unsigned magnitude + a [HarshEventType].
double? accelGForInterval({
  required double prevSpeedKmh,
  required double currSpeedKmh,
  required double dtSeconds,
}) {
  if (dtSeconds <= 0) return null;
  final dvMps = (currSpeedKmh - prevSpeedKmh) / 3.6;
  return (dvMps / dtSeconds) / standardGravityMps2;
}
