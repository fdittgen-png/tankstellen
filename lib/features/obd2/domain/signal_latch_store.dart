// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/data_value.dart';
import 'signal_reading.dart';
import 'vehicle_signal.dart';

/// The latest value of each [VehicleSignal] and WHEN it arrived (#4159).
///
/// Scheduler callbacks [write]; consumers read in one of three ways:
///
/// * [latest] — hold-last, forever: exactly what the old per-PID
///   `_latest*` fields did, so the snapshot's getters keep their meaning;
/// * [fresh] — null once the signal's freshness window has passed, for a
///   consumer that must not reuse an old value (speed-density IAT);
/// * [reading] — the value with its provenance and freshness.
///
/// Arrival time is only known here, at the latch — nothing downstream of
/// the snapshot can reconstruct it — so this is where freshness lives.
/// The clock is injected; the store never reads the wall clock itself.
class SignalLatchStore {
  SignalLatchStore({required this._clock});

  final DateTime Function() _clock;
  final Map<VehicleSignal, double> _values = {};
  final Map<VehicleSignal, DateTime> _arrivedAt = {};

  /// How long [signal]'s latest value is current, or null when it never
  /// goes stale (the scheduler's own backoff decides how often it lands).
  ///
  /// * intake-air temperature — 12 s (#2505): the governor reads it on the
  ///   demotable ~0.5 Hz tier, so it is rarely fresh on the tick MAP + RPM
  ///   land; intake air drifts on a minutes scale, and 12 s spans a few
  ///   throttled periods yet rejects a dead link.
  /// * measured wideband φ — 10 s (#3427), as
  ///   `PrecisionPidLatches.measuredPhiStaleness` applies per sensor.
  static Duration? freshnessWindowOf(VehicleSignal signal) =>
      switch (signal) {
        VehicleSignal.intakeAirTemp => const Duration(seconds: 12),
        VehicleSignal.widebandPhi => const Duration(seconds: 10),
        _ => null,
      };

  /// Latch [value] for [signal], stamped with the injected clock.
  void write(VehicleSignal signal, double value) {
    _values[signal] = value;
    _arrivedAt[signal] = _clock();
  }

  /// The last value that landed for [signal], however old; null before
  /// the first.
  double? latest(VehicleSignal signal) => _values[signal];

  /// When [signal]'s latest value landed; null before the first.
  DateTime? arrivedAt(VehicleSignal signal) => _arrivedAt[signal];

  /// The latest value while it is inside [signal]'s freshness window
  /// (inclusive edge), else null. Signals without a window are always
  /// fresh once they landed.
  double? fresh(VehicleSignal signal) =>
      reading(signal).value is Measured<double> ? _values[signal] : null;

  /// [signal]'s latest value with provenance and freshness: `Measured(at)`
  /// inside the window, `Stale(age)` past it, `Unknown(notMeasuredYet)`
  /// before anything landed.
  SignalReading reading(VehicleSignal signal) {
    final value = _values[signal];
    final at = _arrivedAt[signal];
    if (value == null || at == null) {
      return SignalReading(
        signal: signal,
        value: const DataValue<double>.unknown(
          reason: DataUnknownReason.notMeasuredYet,
        ),
      );
    }
    final window = freshnessWindowOf(signal);
    final age = _clock().difference(at);
    return SignalReading(
      signal: signal,
      value: window != null && age > window
          ? DataValue<double>.stale(value, age: age)
          : DataValue<double>.measured(value, at: at),
    );
  }
}
