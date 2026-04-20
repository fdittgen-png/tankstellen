import 'dart:math' as math;

/// One OBD2 sample tick — captured by the polling loop and fed into
/// [TripRecorder] for metric accumulation.
class TripSample {
  final DateTime timestamp;
  final double speedKmh;
  final double rpm;
  final double? fuelRateLPerHour;

  const TripSample({
    required this.timestamp,
    required this.speedKmh,
    required this.rpm,
    this.fuelRateLPerHour,
  });
}

/// Aggregated metrics for a single driving trip (#718).
class TripSummary {
  final double distanceKm;
  final double maxRpm;
  final double highRpmSeconds;
  final double idleSeconds;
  final int harshBrakes;
  final int harshAccelerations;
  /// Average fuel consumption in L/100 km. Null when the trip carried
  /// no fuel-rate samples (cars without PID 5E / MAF).
  final double? avgLPer100Km;
  /// Estimated fuel burned during the trip, in litres. Null when the
  /// trip carried no fuel-rate samples. This is what the "save as
  /// fill-up" flow pre-fills into the liters field (#726).
  final double? fuelLitersConsumed;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const TripSummary({
    required this.distanceKm,
    required this.maxRpm,
    required this.highRpmSeconds,
    required this.idleSeconds,
    required this.harshBrakes,
    required this.harshAccelerations,
    this.avgLPer100Km,
    this.fuelLitersConsumed,
    this.startedAt,
    this.endedAt,
  });
}

/// Pure-logic accumulator that turns a stream of OBD2 [TripSample]s
/// into a [TripSummary]. The Bluetooth polling loop feeds samples in
/// via [onSample] at whatever cadence it can sustain (~1-2 Hz); the
/// recorder is cadence-agnostic — every metric is integrated over
/// Δt between consecutive samples, not over sample count.
///
/// Thresholds are configurable at construction; defaults match common
/// telematics cutoffs so the derived "aggressive driving" signal maps
/// to something a typical user would recognise.
class TripRecorder {
  /// RPM value above which the recorder clocks "high-RPM" time.
  final double highRpmThreshold;

  /// Negative acceleration (m/s²) that triggers a harsh-brake count.
  /// Stored as a positive number; comparison uses absolute value.
  final double harshBrakeThresholdMps2;

  /// Positive acceleration (m/s²) that triggers a harsh-accel count.
  final double harshAccelThresholdMps2;

  TripSample? _previous;
  double _distanceKm = 0;
  double _maxRpm = 0;
  double _highRpmSeconds = 0;
  double _idleSeconds = 0;
  int _harshBrakes = 0;
  int _harshAccels = 0;
  double _fuelLiters = 0;
  bool _hadFuelRate = false;
  DateTime? _startedAt;
  DateTime? _endedAt;

  TripRecorder({
    this.highRpmThreshold = 3500,
    this.harshBrakeThresholdMps2 = 3.5,
    this.harshAccelThresholdMps2 = 3.0,
  });

  /// Feed one sample. Safe to call with arbitrary cadence; the
  /// recorder derives Δt internally.
  void onSample(TripSample sample) {
    _startedAt ??= sample.timestamp;
    _endedAt = sample.timestamp;
    _maxRpm = math.max(_maxRpm, sample.rpm);

    final previous = _previous;
    if (previous == null) {
      _previous = sample;
      return;
    }
    final dt = sample.timestamp.difference(previous.timestamp).inMicroseconds
        / Duration.microsecondsPerSecond;
    if (dt <= 0) {
      // Out-of-order or duplicate timestamp — skip.
      _previous = sample;
      return;
    }

    // Distance: integrate average speed across the interval.
    final avgSpeedKmh = (previous.speedKmh + sample.speedKmh) / 2.0;
    _distanceKm += avgSpeedKmh * dt / 3600.0;

    // High-RPM time: count the whole interval when the START sample is
    // above threshold (the polling cadence is short relative to typical
    // gear shifts, so this is a reasonable approximation and keeps the
    // metric monotone).
    if (previous.rpm >= highRpmThreshold) {
      _highRpmSeconds += dt;
    }

    // Idle time: engine on, car stationary for the whole interval.
    if (previous.speedKmh <= 0.5 && previous.rpm > 0) {
      _idleSeconds += dt;
    }

    // Harsh brake / accel: derivative of speed across the interval.
    // Convert km/h → m/s by / 3.6.
    final dvMps = (sample.speedKmh - previous.speedKmh) / 3.6;
    final accelMps2 = dvMps / dt;
    if (accelMps2 <= -harshBrakeThresholdMps2) {
      _harshBrakes++;
    } else if (accelMps2 >= harshAccelThresholdMps2) {
      _harshAccels++;
    }

    // Fuel: integrate fuel rate across the interval. Only counts when
    // BOTH endpoints carry a fuel-rate reading (average the two).
    if (previous.fuelRateLPerHour != null && sample.fuelRateLPerHour != null) {
      final avgRate =
          (previous.fuelRateLPerHour! + sample.fuelRateLPerHour!) / 2.0;
      _fuelLiters += avgRate * dt / 3600.0;
      _hadFuelRate = true;
    }

    _previous = sample;
  }

  /// Build a [TripSummary] snapshot from the samples fed so far. Safe
  /// to call at any time — the recorder keeps accumulating.
  TripSummary buildSummary() {
    double? avgLPer100Km;
    if (_hadFuelRate && _distanceKm > 0.001) {
      avgLPer100Km = _fuelLiters / _distanceKm * 100.0;
    }
    return TripSummary(
      distanceKm: _distanceKm,
      maxRpm: _maxRpm,
      highRpmSeconds: _highRpmSeconds,
      idleSeconds: _idleSeconds,
      harshBrakes: _harshBrakes,
      harshAccelerations: _harshAccels,
      avgLPer100Km: avgLPer100Km,
      fuelLitersConsumed: _hadFuelRate ? _fuelLiters : null,
      startedAt: _startedAt,
      endedAt: _endedAt,
    );
  }

  /// Reset the accumulator. Useful before starting a fresh trip
  /// without destroying the recorder instance.
  void reset() {
    _previous = null;
    _distanceKm = 0;
    _maxRpm = 0;
    _highRpmSeconds = 0;
    _idleSeconds = 0;
    _harshBrakes = 0;
    _harshAccels = 0;
    _fuelLiters = 0;
    _hadFuelRate = false;
    _startedAt = null;
    _endedAt = null;
  }
}
