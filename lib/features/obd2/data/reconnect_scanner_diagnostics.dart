// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'obd2_comm_diagnostics.dart';
import 'obd2_session_diagnostic.dart';

/// Gated comm-health recorders for the [AdapterReconnectScanner] (#2466 +
/// #2905), pulled into a free helper so the scanner stays under the
/// 400-line cap. Both are no-ops unless `Feature.debugMode` armed the
/// collector (the scanner only allocates its Stopwatch then), so production
/// pays nothing.

/// Record a SUCCESSFUL reconnect: the #2466 silent-vs-visible tally + the
/// time-to-reconnect sample, PLUS the #2905 `reconnected` transition
/// marker. The per-attempt `succeeded:true` timeline row is recorded by the
/// [ReconnectConnector] — the single owner of per-attempt path/reason/rssi
/// detail — so it is NOT duplicated here.
///
/// [silent] is true when the link healed before the backoff ever escalated
/// (the fast first probe / first attempt landed inside the grace window).
/// [elapsedMs] is the episode duration.
void recordReconnectSuccess({required bool silent, required int? elapsedMs}) {
  final diag = Obd2CommDiagnostics.instance;
  if (!diag.enabled) return;
  diag.noteConnectionEvent(
    silentReconnect: silent,
    visibleReconnect: !silent,
    timeToReconnectMs: elapsedMs,
  );
  diag.noteSessionTransition(Obd2SessionState.reconnected);
}

/// Record the scanner entering the active reconnecting state at the start
/// of a drop episode (#2905) — the `reconnecting` transition marker.
void recordReconnectingStarted() {
  final diag = Obd2CommDiagnostics.instance;
  if (!diag.enabled) return;
  diag.noteSessionTransition(Obd2SessionState.reconnecting);
}
