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

  /// The ECU stayed genuinely SILENT through the probe window — `UNABLE TO
  /// CONNECT` / `NO DATA` / `BUS INIT: ERROR` after the protocol search
  /// gave up. This is the real engine-off signature.
  probedSilent,

  /// The probe ran out its generous window with no terminal answer — a read
  /// [TimeoutException] / a `SEARCHING…` that never resolved / a thrown send —
  /// an indeterminate state, NOT a confirmed engine-off. The caller must NOT
  /// classify ignition-off on this; the session stays usable / blind query
  /// proceeds.
  transient,
}

/// The discovered first-group bitmap (null when none) plus the tri-state
/// outcome of the resilient first-`0100` probe (#3035).
typedef Obd2FirstProbeOutcome = ({Set<int>? bitmap, Obd2BusProbeResult result});

/// #3037 — the GENEROUS single-shot read window for the first `0100` probe.
///
/// The first `0100` triggers the ELM327's `ATSP0` protocol auto-search, which
/// walks every OBD protocol in turn. On a slow Classic-SPP clone (the user's
/// handshake took ~13 s in one trace) that search legitimately outlasts the
/// transport's 5 s steady-state read ceiling. Re-SENDING `0100` mid-search
/// RESTARTS the search, so the late `41 00` frame is never caught — the
/// #3035/#3037 false engine-off. The fix is a SINGLE long read that lets the
/// search resolve to `41 00` (or a definitive silent reply) within ONE
/// window. 15 s safely covers the worst-case search: even an engine-off bus
/// returns `UNABLE TO CONNECT` inside ~10 s, so this won't hang. Steady-state
/// PID reads keep their ~5 s class.
const Duration kObd2ProtocolSearchTimeout = Duration(seconds: 15);

/// #3037 — at most ONE extra `0100` send, and ONLY on a genuine TRANSPORT
/// THROW (a failed write — concurrent-send guard / device-not-connected),
/// where the command never reached the ELM327 so re-sending is the first real
/// delivery, NOT a search restart. A plain read [TimeoutException] is NEVER
/// re-sent: a timeout means the search MAY still be in progress, and the
/// invariant is "do not re-send `0100` while a search may still be running".
const int kObd2ProbeMaxTransportRetries = 1;

/// Per-retry settle before the single permitted transport-throw re-send
/// (#3037). Scaled by [obd2ProbeBackoffScale] so unit tests don't wait real
/// time. Only paid on a genuine transport throw, never on a timeout.
const Duration kObd2ProbeTransportRetryBackoff = Duration(milliseconds: 300);

/// Test hook to collapse [kObd2ProbeTransportRetryBackoff] to ~zero so the
/// (transport-throw-only) retry path runs in microseconds under tests.
/// Production keeps it at `1.0`.
@visibleForTesting
double obd2ProbeBackoffScale = 1.0;

/// Drive the resilient first-`0100` probe (#3035, generous-window rework
/// #3037), the root fix for "adapter connects but no live data" (the first
/// `0100` triggers the ELM327 protocol search and its real answer can arrive
/// several seconds into the search).
///
/// [searchSend] dispatches `0100` with the GENEROUS protocol-search read
/// window ([kObd2ProtocolSearchTimeout]) — a SINGLE long read that lets
/// `SEARCHING…` resolve to `41 00` without re-sending mid-search. When the
/// host transport can give a per-command timeout override (it implements
/// [Obd2ProtocolSearchTransport]) the resolver wires this to it; otherwise it
/// falls back to the plain `send`, which still applies its own first-command
/// search class. [isConnected] short-circuits a torn-down link, and
/// [groupBase] is the 32-PID base of `0100` (`0x00`). [recordTrace], when
/// supplied, is fed the raw response (or `TIMEOUT` / the thrown error) of each
/// probe read for connect-trace observability (#3037 root cause 3).
///
/// Classification:
///   - a parseable `41 00` bitmap → [Obd2BusProbeResult.answered] (terminal);
///   - a definitive ECU-silent reply (`NO DATA` / `UNABLE TO CONNECT` /
///     `CAN ERROR`) → [Obd2BusProbeResult.probedSilent] (the real engine-off
///     signature, still detected — within the window, never hanging);
///   - a read [TimeoutException] / a `SEARCHING…` that never resolved within
///     the generous window / an empty frame → [Obd2BusProbeResult.transient]
///     (indeterminate, NEVER a confirmed engine-off);
///   - a genuine TRANSPORT THROW (the write itself failed — the command never
///     reached the adapter) is re-sent at most [kObd2ProbeMaxTransportRetries]
///     times; if it keeps throwing it settles [Obd2BusProbeResult.transient].
///
/// INVARIANT (#3037): `0100` is sent ONCE per successful (timed-out or
/// answered) read — it is NEVER re-sent while a protocol search may still be
/// in progress. The only re-send is on a transport throw, where the search
/// never started.
Future<Obd2FirstProbeOutcome> probeFirstSupportedPids({
  required Future<String> Function(String command) searchSend,
  required bool Function() isConnected,
  required String command,
  required int groupBase,
  void Function(String rawResponseOrError, bool timedOut)? recordTrace,
}) async {
  // At most (1 + kObd2ProbeMaxTransportRetries) physical sends, and a re-send
  // happens ONLY on a transport throw (the command never reached the adapter).
  for (var transportThrows = 0;; transportThrows++) {
    if (!isConnected()) {
      return (bitmap: null, result: Obd2BusProbeResult.transient);
    }
    if (transportThrows > 0) {
      final scaled = Duration(
        microseconds:
            (kObd2ProbeTransportRetryBackoff.inMicroseconds * obd2ProbeBackoffScale)
                .round(),
      );
      if (scaled > Duration.zero) await Future<void>.delayed(scaled);
    }
    try {
      // SINGLE generous-window read: let SEARCHING… resolve to 41 00 (or a
      // definitive silent reply) WITHIN this window — no re-send mid-search.
      final response = await searchSend(command);
      recordTrace?.call(response, false);
      final bitmap =
          Elm327Protocol.parseSupportedPidsBitmap(response, groupBase);
      if (bitmap != null) {
        return (bitmap: bitmap, result: Obd2BusProbeResult.answered);
      }
      final cls = classifyObd2Response(response);
      if (cls == ResponseClass.noData ||
          cls == ResponseClass.unrecognized ||
          cls == ResponseClass.canError) {
        // The ECU was contacted and is genuinely SILENT — real engine-off,
        // detected within the window (never hanging).
        return (bitmap: null, result: Obd2BusProbeResult.probedSilent);
      }
      // A SEARCHING… / empty / partial frame that filled the generous window
      // without ever resolving. Indeterminate — NOT a confirmed engine-off,
      // and we do NOT re-send (the search may still have been in progress).
      debugPrint('OBD2 first 0100 probe: no bitmap (${cls.name}) within the '
          'generous search window — transient (not engine-off)');
      return (bitmap: null, result: Obd2BusProbeResult.transient);
    } on TimeoutException {
      // The generous window elapsed mid-search. RE-READING/draining the
      // in-progress search is exactly what a longer single window already
      // did; re-SENDING here would restart it. So a timeout is terminal-
      // transient — never a confirmed engine-off (#3036/#3037 invariant).
      recordTrace?.call('TIMEOUT', true);
      debugPrint('OBD2 first 0100 probe timed out within the generous '
          '${kObd2ProtocolSearchTimeout.inSeconds}s window — transient '
          '(NOT re-sent; a re-send would restart the protocol search)');
      return (bitmap: null, result: Obd2BusProbeResult.transient);
    } catch (e, st) {
      // A genuine TRANSPORT THROW: the write itself failed (concurrent-send
      // guard / device-not-connected), so the command never reached the
      // adapter and the protocol search never started. Re-sending is the
      // FIRST real delivery, not a search restart — so it is the ONLY case
      // that re-sends, bounded by [kObd2ProbeMaxTransportRetries].
      recordTrace?.call(e.toString(), false);
      if (transportThrows >= kObd2ProbeMaxTransportRetries) {
        debugPrint('OBD2 first 0100 probe: transport threw ($e) and retries '
            'are exhausted — transient\n$st');
        return (bitmap: null, result: Obd2BusProbeResult.transient);
      }
      debugPrint('OBD2 first 0100 probe: transport threw ($e) before the '
          'command reached the adapter — re-sending once (search not '
          'started)\n$st');
      // loop → one bounded re-send
    }
  }
}
