// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../domain/vehicle_signal.dart';
import '../protocol/obd2_signal_pids.dart';

/// The two support questions a signal gate asks of a connection
/// (implemented by `Obd2Service`). #4315 — narrowed from the deleted pull
/// reader's read port, of which only these two checks had a live caller.
abstract interface class Obd2PidSupport {
  /// "Unknown ⇒ allow" support check (see `SupportedPidsResolver`).
  bool isPidSupported(int pid);

  /// STRICT support check for the #3416 precision PIDs — true only when
  /// the support set is RESOLVED and the bitmap claims [pid] (#3532).
  bool isPidKnownSupported(int pid);
}

/// "Is this signal worth polling on this connection?" asked by NAME
/// (#4159) — the PID and the gate kind come from the adapter's table.
///
/// An extension rather than a method on `Obd2Service`: the service's
/// library is pinned by the #4033 length ratchet, and this needs nothing
/// but the two support checks every [Obd2PidSupport] has.
extension Obd2SignalSupport on Obd2PidSupport {
  /// Strict signals ask [Obd2PidSupport.isPidKnownSupported];
  /// everything else asks the optimistic
  /// [Obd2PidSupport.isPidSupported]. Exactly one question per call.
  bool supports(VehicleSignal signal) {
    final pid = Obd2SignalPids.pidOf(signal);
    return switch (Obd2SignalPids.gateOf(signal)) {
      SignalGate.strict => isPidKnownSupported(pid),
      SignalGate.optimistic => isPidSupported(pid),
    };
  }
}
