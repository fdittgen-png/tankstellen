// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connection_service.dart';

/// #3244 — close-by-identity teardown for [Obd2ConnectionService],
/// extracted as a `part` (the `obd2_connect_by_mac.dart` precedent) so the
/// helper keeps private access to `_lastDirectChannel` while the service
/// file stays at its #1680 snapshot.
///
/// The BLE-audit HIGH finding this fixes: a teardown that closed
/// *whatever `_lastDirectChannel` pointed at* could run AFTER
/// `_lastDirectChannel` was re-assigned to a rival attempt's channel —
/// closing the rival's live connect mid-handshake.

/// Close [channel] — the calling attempt's OWN channel — and clear
/// [Obd2ConnectionService._lastDirectChannel] ONLY when it still points at
/// that same instance (#3244 close-by-identity). A failure path that runs
/// AFTER a rival attempt re-assigned the pointer therefore tears down only
/// its own dead channel, never the rival's live one.
Future<void> _teardownDirectChannel(
  Obd2ConnectionService svc,
  ElmByteChannel channel,
) async {
  if (identical(svc._lastDirectChannel, channel)) {
    svc._lastDirectChannel = null;
  }
  try {
    await channel.close();
  } catch (e, st) {
    // #2379 — OBD2/BLE, not local storage.
    unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
      'where': 'Obd2ConnectionService: own-direct-channel teardown',
    }));
  }
}
