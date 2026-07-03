// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_connection_service.dart';

/// #3244 — passive-preemption teardown + close-by-identity for
/// [Obd2ConnectionService], extracted as a `part` (the
/// `obd2_connect_by_mac.dart` precedent) so both helpers keep private
/// access to `_lastDirectChannel` while the service file stays at its
/// #1680 snapshot.
///
/// The BLE-audit HIGH finding this fixes: the supervisor's preempt
/// teardown closed *whatever `_lastDirectChannel` pointed at*, and the
/// zombie's own failure path did the same LATER — after the slot had been
/// force-released and `_lastDirectChannel` re-assigned to the ACTIVE
/// requester's channel. The zombie then closed the active connect
/// mid-handshake (the exact race #3185 exists to prevent).

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

/// #3244 — the supervisor's preempt teardown for the PASSIVE holder
/// ([Obd2ConnectionService.connectByMacPassive]'s `onPreempt`). Three jobs,
/// in order:
///
///  1. **Poison the channel** ([Obd2ChannelAbandonLatch.abandon]) BEFORE
///     closing it, so the transport's open-retry loop sees the terminal
///     [Obd2ChannelAbandoned] instead of a recoverable disconnect — the
///     passive path unwinds without re-dialling an UNBOUNDED autoConnect
///     GATT request against the just-granted active requester.
///  2. **Mark the passive attempt's live trace superseded** so the active
///     requester's `beginTrace` finalises it and opens its OWN root — the
///     active trace must land as a persisted root, not vanish as a child
///     of the zombie's (`Obd2ConnectTraceLog._active` is one static slot).
///  3. **Close the channel** (the ordinary teardown), unwinding the
///     in-flight autoConnect wait.
Future<void> _preemptPassiveHolder(Obd2ConnectionService svc) async {
  // Declared Object? so the `is`-check PROMOTES: the latch mixin is not a
  // subtype of ElmByteChannel, and Dart only promotes to subtypes.
  final Object? ch = svc._lastDirectChannel;
  if (ch is Obd2ChannelAbandonLatch) ch.abandon();
  Obd2ConnectTraceLog.active?.markSuperseded(
      'passive holder preempted by an active requester (#3244)');
  await svc._teardownLastDirectChannel();
}
