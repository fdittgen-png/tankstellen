// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:hive/hive.dart';

import 'negotiated_protocol_cache.dart';
import 'supported_pids_cache.dart';
import '../../../../core/storage/hive_boxes.dart';

/// Opens the deferred OBD2 caches the live [Obd2ConnectionService] wires
/// into every session. Each returns null when its Hive box isn't open
/// yet (early-boot connect, or a bare test harness that never
/// initialised Hive) so building the connection service can never throw
/// — the session then runs with the pre-cache behaviour (blind PID
/// querying / cold ATSP0 auto-search every connect).

/// #811 supported-PID bitmap cache.
SupportedPidsCache? openSupportedPidsCache() {
  if (!Hive.isBoxOpen(HiveBoxes.obd2SupportedPids)) return null;
  return SupportedPidsCache(Hive.box<String>(HiveBoxes.obd2SupportedPids));
}

/// #2261 negotiated-protocol warm cache.
NegotiatedProtocolCache? openNegotiatedProtocolCache() {
  if (!Hive.isBoxOpen(HiveBoxes.obd2NegotiatedProtocol)) return null;
  return NegotiatedProtocolCache(
    Hive.box<String>(HiveBoxes.obd2NegotiatedProtocol),
  );
}
