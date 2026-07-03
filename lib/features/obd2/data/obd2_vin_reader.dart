// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'elm327_protocol.dart';
import 'obd2_service.dart';

/// One-shot best-effort VIN (Mode 09 / 0902) read at trip start.
///
/// Extracted verbatim from `TripRecordingController._readVinOnce`
/// (#3431 — keeps that grandfathered god-file net-zero while the
/// instant-consumption EMA wiring lands; decomposition tracked by
/// #3140). The VIN is read exactly once at `start` — it doesn't change
/// mid-trip, and blasting the adapter with a 0902 every 10 s would
/// waste bandwidth the 5 Hz tier needs. Returns null on NO DATA /
/// malformed response.
Future<String?> readTripVinOnce(Obd2Service service) async {
  try {
    final raw = await service.sendCommand(Elm327Protocol.vinCommand);
    return Elm327Protocol.parseVin(raw);
  } catch (_) {
    // #2428 (follow-up to #2379/#2424) — the one-shot VIN (0902) read is
    // best-effort: a flaky/slow ELM327 times it out, the legacy
    // concurrent-sendCommand StateError can fire, or the device drops
    // mid-probe — and old ECUs / clone adapters never answer 0902. All
    // EXPECTED and recoverable: we return null and the trip records fine
    // without a VIN, so a transient here must NOT pollute the user error
    // log (it was mis-tagged `[storage]`). The null return IS the signal.
    debugPrint('OBD2 VIN read failed — recording trip without a VIN');
    return null;
  }
}
