// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../obd2_connect_trace.dart';
import '../obd2_connect_trace_log.dart';
import 'obd2_service.dart';

/// #2969 — open (or join) a connect trace around [body], stamp the
/// terminal outcome, and finalise it into [Obd2ConnectTraceLog].
///
/// The single wrapper every public by-MAC connect entry threads through,
/// so a failure at ANY phase (including the pre-session phases) is
/// captured. Re-entrant safe: a nested connect — a fallback re-entering a
/// public method — joins the same trace.
///
/// The outcome is: success when a service comes back; the inner-stamped
/// outcome, or `scanEmpty` as the default, when null; the classified
/// error on a throw.
///
/// #4035 (epic #4032) — this is a library of its own rather than a `part`
/// of `obd2_connection_service.dart`. It touches no service state: it is
/// pure trace plumbing around a callback, and being a `part` only ever
/// gave it access it did not use.
Future<Obd2Service?> tracedConnect({
  required Obd2ConnectOrigin origin,
  String? mac,
  String? adapterName,
  required Obd2ConnectTransport requestedTransport,
  required Future<Obd2Service?> Function() body,
}) async {
  final trace = Obd2ConnectTraceLog.beginTrace(
    origin: origin,
    mac: mac,
    adapterName: adapterName,
    requestedTransport: requestedTransport,
  );
  try {
    final svc = await body();
    if (svc != null) {
      trace.setOutcome(Obd2ConnectOutcome.success);
    } else if (!trace.hasOutcome) {
      // A clean null with NO inner-stamped outcome means the scan/transport
      // path never matched the adapter — the scan-empty / not-in-range case.
      trace.setOutcome(Obd2ConnectOutcome.scanEmpty);
    }
    return svc;
    // rethrow preserves the stack; the (e) binding only classifies the trace.
    // ignore: catch_no_st
  } catch (e) {
    trace.setOutcomeFromError(e);
    rethrow;
  } finally {
    Obd2ConnectTraceLog.endTrace(trace);
  }
}
