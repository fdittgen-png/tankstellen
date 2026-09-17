// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../domain/vehicle_signal.dart';
import '../protocol/obd2_signal_pids.dart';
import 'obd2_fuel_rate_reader.dart';

/// "Is this signal worth polling on this connection?" asked by NAME
/// (#4159) — the PID and the gate kind come from the adapter's table.
///
/// An extension rather than a method on `Obd2Service`: the service's
/// library is pinned by the #4033 length ratchet, and this needs nothing
/// but the two existing support checks every [Obd2FuelRateReads] has.
extension Obd2SignalSupport on Obd2FuelRateReads {
  /// Strict signals ask [Obd2FuelRateReads.isPidKnownSupported];
  /// everything else asks the optimistic
  /// [Obd2FuelRateReads.isPidSupported]. Exactly one question per call.
  bool supports(VehicleSignal signal) {
    final pid = Obd2SignalPids.pidOf(signal);
    return switch (Obd2SignalPids.gateOf(signal)) {
      SignalGate.strict => isPidKnownSupported(pid),
      SignalGate.optimistic => isPidSupported(pid),
    };
  }
}
