// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3857 (Epic #3855) — the ~10 s `ATRV` voltage watch of
/// [TripRecordingController], as a collaborator that owns its two fields
/// (#4034, epic #4032).
///
/// One AT reply per 10 s is invisible next to the ~4 Hz PID cadence, and
/// it is the ONLY way the engine state stays measurable once the bus goes
/// quiet. The reply feeds the vehicle power model through the session
/// hook; the value is also held here for exactly ONE slow-cadence `bv`
/// stamp on the next sample, so a voltage never lands on two samples and
/// no sample carries a stale one.
class TripVoltageWatch {
  TripVoltageWatch({this.interval = const Duration(seconds: 10)});

  /// Cadence of the voltage watch.
  final Duration interval;

  DateTime? _lastReadAt;
  double? _pendingStamp;

  /// True when [interval] has elapsed since the last read (or none has
  /// happened yet). The caller still owns the link-state preconditions.
  bool isDue(DateTime now) {
    final last = _lastReadAt;
    return last == null || now.difference(last) >= interval;
  }

  /// Mark a read as started at [now], so the next tick does not re-issue
  /// it while this one is still in flight.
  void markRead(DateTime now) => _lastReadAt = now;

  /// Hold [volts] for the next sample.
  void stamp(double volts) => _pendingStamp = volts;

  /// Hand the pending stamp to exactly one sample: the value is cleared
  /// as it is read, so the sample after it carries null again.
  double? take() {
    final v = _pendingStamp;
    _pendingStamp = null;
    return v;
  }
}
