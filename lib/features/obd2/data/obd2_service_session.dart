// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'elm_session.dart';
import 'obd2_link_drop_signal.dart';
import 'obd2_transport.dart';

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
