// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'obd2_connection_errors.dart';

/// #2763 — true when [error] is an EXPECTED transient on a best-effort OBD2
/// read (VIN / one-shot PID), the documented #2428/#2379 flaky-comms contract:
///
/// - [TimeoutException] — a slow/flaky ELM327 that didn't answer in time;
/// - [StateError] — the legacy concurrent-`sendCommand` race (#2428);
/// - [Obd2ConnectionError] whose [Obd2ConnectionError.isExpectedUserCondition]
///   is true (device dropped / disconnected mid-read).
///
/// Everything else (parse/IO faults, permission denied) is a genuine fault and
/// returns false so it stays an ERROR trace.
bool isExpectedObd2ReadTransient(Object error) =>
    error is TimeoutException ||
    error is StateError ||
    (error is Obd2ConnectionError && error.isExpectedUserCondition);

/// #2763 — route a best-effort OBD2 *read* failure (VIN, one-shot PID) to the
/// right telemetry level, mirroring `recordObd2ConnectFailure` (#2745).
///
/// `readVin`'s own contract swallows errors and returns null; field error
/// log #15 showed an `[other] TimeoutException "ELM327 did not respond"` ERROR
/// spooled for exactly such an EXPECTED flaky-comms timeout. An expected
/// transient ([isExpectedObd2ReadTransient]) records a diagnostic breadcrumb
/// instead; a GENUINE fault still `errorLogger.log`s at [ErrorLayer.other] so
/// it stays visible. Shared by the data-layer `readVin` and the onboarding
/// connector so the two sites can't drift.
///
/// #2855 — also backs the high-frequency live-poll reads (`readSpeedKmh`,
/// `readRpm`, and every `_readDouble`-based PID: throttle / load / fuel-rate
/// / MAF / MAP / IAT / baro / fuel-trims / …). An engine-off or busy adapter
/// times the speed/RPM PID out every ~2.5 s poll cycle; a real log showed
/// 50× `readSpeed failed` ERROR traces in 2 min. Routing those through here
/// turns each transient into the designed 'no reading this cycle' null +
/// breadcrumb, so the per-poll flood stops while genuine parse/IO faults
/// still surface. Persistent non-response is already covered by the
/// comm-health diagnostics (#2464) + passive-waiting banner (#2767), so no
/// real signal is lost. Same spirit as the #2379 odometer fix.
void recordObd2ReadFailure(
  Object error,
  StackTrace stack, {
  required String where,
}) {
  if (isExpectedObd2ReadTransient(error)) {
    BreadcrumbCollector.add(
      'OBD2 read failed — expected transient',
      detail: '$where: ${error.runtimeType}',
    );
    return;
  }
  unawaited(errorLogger.log(ErrorLayer.other, error, stack,
      context: {'where': where}));
}
