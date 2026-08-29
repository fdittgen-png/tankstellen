// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../domain/vehicle_power_state.dart';
import '../protocol/elm_session.dart';
import '../transport/obd2_link_drop_signal.dart';
import '../transport/obd2_transport.dart';

/// #3528 (Epic #3527) — the [Obd2Service]-side lifecycle of one
/// [ElmSession]: attach after a successful connect, route raw sends
/// through the session's ladder while it is alive, report a session
/// death into the app-wide [Obd2LinkDropSignal] (the same decoupled hop
/// the byte channels use — the one link supervisor recycles the
/// socket), and detach BEFORE a deliberate transport teardown so no
/// keepalive races the closing socket and user intent never reads as a
/// drop (research rule 7).
class Obd2ServiceSession {
  ElmSession? _session;
  StreamSubscription<ElmSessionState>? _statesSub;

  /// Attach a fresh session over [transport] (which the service already
  /// initialized — [ElmSession.adoptReady], no re-init). [linkKind] /
  /// [mac] label the drop event for the supervisor's trace.
  void start(
    Obd2Transport transport, {
    required String? Function() linkKind,
    required String? Function() mac,
  }) {
    stop();
    final session = ElmSession(transport)..adoptReady();
    // #3857 — every ATRV reply (the ~4 s keepalive already pays for it)
    // becomes vehicle power evidence: the one engine signal that needs
    // no bus traffic, so it keeps reporting while the ECU is silent.
    session.onVoltage = Obd2VehiclePower.instance.noteVoltage;
    _session = session;
    _statesSub = session.states.listen((next) {
      if (next != ElmSessionState.dead) return;
      Obd2LinkDropSignal.instance.notifyDrop(
        transportKind: linkKind() ?? 'unknown',
        mac: mac(),
        reason: 'session:${session.deathCause?.name ?? 'unknown'}',
      );
    });
  }

  /// #3756 — completed non-AT commands of the CURRENT session (0 when
  /// none attached). The supervisor reads this at drop time for the
  /// trafficked-ready flap exemption.
  int get successfulObdSends => _session?.successfulObdSends ?? 0;

  /// #3857 — battery voltage from the current session's last `ATRV`
  /// reply; null before the first one or with no session attached.
  double? get lastVoltageV => _session?.lastVoltageV;

  /// #3779 — declare a session-bypassing long read (the protocol-search
  /// `0100`) so the liveness watchdog holds instead of stale-killing the
  /// socket mid-search. No-op when no session is attached.
  void holdLivenessFor(Duration window) => _session?.holdLivenessFor(window);

  /// #3779 — the long read resolved: clear the hold + refresh liveness.
  void noteExternalReply() => _session?.noteExternalReply();

  /// Detach + dispose. Idempotent.
  void stop() {
    unawaited(_statesSub?.cancel());
    _statesSub = null;
    _session?.dispose();
    _session = null;
  }

  /// The ONE raw-send funnel: through the live session's ladder when
  /// attached and alive, straight to [transport] otherwise (the init
  /// burst inside `connect` runs pre-session; a dead session means the
  /// supervisor is already recycling this service).
  Future<String> send(String command, Obd2Transport transport) {
    final session = _session;
    if (session != null &&
        session.state != ElmSessionState.dead &&
        session.state != ElmSessionState.idle) {
      return session.send(command);
    }
    return transport.sendCommand(command);
  }
}
