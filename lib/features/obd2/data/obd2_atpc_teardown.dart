// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'elm327_commands.dart';
import 'obd2_transport.dart';

/// #3422 — upper bound on the best-effort `ATPC` send: a teardown must stay
/// snappy even against an already-half-dead adapter that never answers.
const kAtpcTeardownTimeout = Duration(seconds: 2);

/// #3422 (epic #3415) — wedge PREVENTION: send `ATPC` (Protocol Close)
/// best-effort before a DELIBERATE teardown, so the adapter parks its
/// protocol state machine cleanly and releases its single SPP channel in a
/// re-openable state (see [Elm327Commands.protocolCloseCommand]).
///
/// Contract:
///  * DELIBERATE teardowns only — a drop-triggered teardown reaches this
///    with `transport.isConnected == false` (the channels clear their open
///    flag on the drop edge, #2671) and is skipped: writing into a dead
///    socket would only add latency and error noise.
///  * Never interrupts a command mid-response: the send rides the
///    transport's ordinary serialized [Obd2Transport.sendCommand] path, so
///    it queues BEHIND any in-flight command (#1965 serialization).
///  * Best-effort and NEVER throws — bounded by [kAtpcTeardownTimeout]; a
///    miss/throw is breadcrumbed (release-visible via the error-trace ring)
///    and the disconnect proceeds exactly as before #3422.
Future<void> sendProtocolCloseBeforeTeardown(Obd2Transport transport) async {
  if (!transport.isConnected) return;
  try {
    await transport
        .sendCommand(Elm327Commands.protocolCloseCommand)
        .timeout(kAtpcTeardownTimeout);
  } catch (e, st) {
    // Expected on a dying link — the teardown is already happening, so the
    // breadcrumb (not an ERROR trace) is the right visibility level (#3379
    // precedent for benign teardown-path noise).
    BreadcrumbCollector.add(
      'obd2: ATPC before deliberate disconnect failed (ignored)',
      detail: '$e\n$st',
    );
  }
}
