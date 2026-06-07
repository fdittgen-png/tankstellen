// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'elm327_protocol.dart';
import 'obd2_response_class.dart';

/// Tri-state outcome of the SAE-J1979 `0100` supported-PIDs probe (#3035).
///
/// The ELM327's AT handshake (`ATZ`→`ATE0`→`ATSP0`→…) is answered by the
/// adapter's own MCU and never touches the car — the ECU is only contacted
/// by the FIRST OBD request, `0100`, which triggers the protocol search.
/// That search can reply `SEARCHING...` and only deliver the real
/// `41 00 <bitmap>` (or `UNABLE TO CONNECT`) several seconds / a later read
/// later. So a single first-shot timeout is NOT proof the engine is off —
/// the probe must distinguish three terminal states:
enum Obd2BusProbeResult {
  /// The probe never ran (resolver primed from cache, or not connected) —
  /// no evidence either way. The cheap cache-hit path leaves this set.
  notProbed,

  /// The ECU answered `0100` with a real `41 00` bitmap → the bus is live
  /// (engine on / ECU awake). At least one supported PID was discovered.
  answered,

  /// The ECU stayed genuinely SILENT through every retry — `UNABLE TO
  /// CONNECT` / `NO DATA` / `BUS INIT: ERROR` after the protocol search
  /// gave up. This is the real engine-off signature.
  probedSilent,

  /// Every retry hit a transport blip (`TimeoutException` / `SEARCHING…`
  /// that never resolved / a thrown send) — an indeterminate state, NOT a
  /// confirmed engine-off. The caller must NOT classify ignition-off on
  /// this; the session stays usable / blind query proceeds.
  transient,
}

/// The discovered first-group bitmap (null when none) plus the tri-state
/// outcome of the resilient first-`0100` probe (#3035).
typedef Obd2FirstProbeOutcome = ({Set<int>? bitmap, Obd2BusProbeResult result});

/// How many times the first `0100` probe is attempted before giving up
/// (#3035). Three attempts span the typical ELM327 protocol-search window:
/// a clone often returns `SEARCHING…` / times out on the first read and only
/// delivers the real `41 00` frame on the second or third.
const int kObd2ProbeAttempts = 3;

/// Per-attempt pre-delay for the first `0100` probe (#3035): 0 / 300 /
/// 600 ms. The first attempt is immediate; subsequent attempts settle so the
/// protocol search has time to complete and the late frame to arrive. Scaled
/// by [obd2ProbeBackoffScale] so unit tests don't wait real time.
const List<Duration> kObd2ProbeBackoffs = [
  Duration.zero,
  Duration(milliseconds: 300),
  Duration(milliseconds: 600),
];

/// Test hook to collapse [kObd2ProbeBackoffs] to ~zero so the retry path runs
/// in microseconds under `fakeAsync`. Production keeps it at `1.0`.
@visibleForTesting
double obd2ProbeBackoffScale = 1.0;

/// Drive the resilient first-`0100` probe (#3035), the root fix for "adapter
/// connects but no live data" (the first `0100` triggers the ELM327 protocol
/// search and its real answer can arrive on a LATER read).
///
/// [send] dispatches the raw command (the host's retry-wrapped `_send`),
/// [isConnected] short-circuits a torn-down link, and [groupBase] is the
/// 32-PID base of `0100` (`0x00`).
///
/// Classification across the retries:
///   - a parseable `41 00` bitmap on ANY attempt → [Obd2BusProbeResult
///     .answered] (terminal, returns immediately);
///   - a definitive ECU-silent reply (`NO DATA` / `UNABLE TO CONNECT` /
///     `CAN ERROR`) is REMEMBERED but the loop keeps trying — a clone can
///     emit one transient NO DATA mid-search before the real frame. Only if
///     every attempt is exhausted with at least one such reply (and no
///     bitmap) does it settle [Obd2BusProbeResult.probedSilent];
///   - a `SEARCHING…` reply / empty frame / [TimeoutException] / thrown send
///     is "search in progress" → re-read. If every attempt is one of these
///     (no bitmap, no definitive-silent), it settles
///     [Obd2BusProbeResult.transient].
Future<Obd2FirstProbeOutcome> probeFirstSupportedPids({
  required Future<String> Function(String command) send,
  required bool Function() isConnected,
  required String command,
  required int groupBase,
}) async {
  var sawDefinitiveSilent = false;
  for (var attempt = 0; attempt < kObd2ProbeAttempts; attempt++) {
    if (!isConnected()) break;
    final settle = kObd2ProbeBackoffs[attempt];
    if (settle > Duration.zero) {
      final scaled = Duration(
        microseconds: (settle.inMicroseconds * obd2ProbeBackoffScale).round(),
      );
      await Future<void>.delayed(scaled);
    }
    try {
      final response = await send(command);
      final bitmap =
          Elm327Protocol.parseSupportedPidsBitmap(response, groupBase);
      if (bitmap != null) {
        return (bitmap: bitmap, result: Obd2BusProbeResult.answered);
      }
      // No bitmap — classify the raw reply to decide retry vs. silent.
      final cls = classifyObd2Response(response);
      if (cls == ResponseClass.noData ||
          cls == ResponseClass.unrecognized ||
          cls == ResponseClass.canError) {
        // A definitive ECU-silent reply. Remember it, but keep retrying: a
        // search can emit one NO DATA before the real frame lands.
        sawDefinitiveSilent = true;
      }
      // Everything else (SEARCHING… → garbage, bufferFull, empty frame) is
      // "search still in progress" → fall through and re-read.
      debugPrint('OBD2 first 0100 probe attempt ${attempt + 1}'
          '/$kObd2ProbeAttempts: no bitmap (${cls.name}) — retrying');
    } on TimeoutException {
      // The protocol search can outlast a single read budget — re-read.
      debugPrint('OBD2 first 0100 probe attempt ${attempt + 1}'
          '/$kObd2ProbeAttempts timed out — retrying');
    } catch (e, st) {
      // A transport blip (concurrent-send guard, device-not-connected). The
      // throw is EXPECTED + recoverable here (we re-read), so the stack is
      // only a debug breadcrumb, not an error trace.
      debugPrint('OBD2 first 0100 probe attempt ${attempt + 1}'
          '/$kObd2ProbeAttempts threw ($e) — retrying\n$st');
    }
  }
  // Exhausted with no bitmap. A definitive-silent reply anywhere ⇒ genuine
  // engine-off; otherwise the link was merely flaky/slow (transient).
  return (
    bitmap: null,
    result: sawDefinitiveSilent
        ? Obd2BusProbeResult.probedSilent
        : Obd2BusProbeResult.transient,
  );
}
