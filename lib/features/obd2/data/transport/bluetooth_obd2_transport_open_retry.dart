// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'bluetooth_obd2_transport.dart';

/// Channel-open retry machinery for [BluetoothObd2Transport], extracted
/// from `bluetooth_obd2_transport.dart` as a `part` so the retry loop and
/// its classification helpers keep library-level private access while the
/// transport file stays under the #1680 file-length cap (sanctioned #3760
/// decomposition — move-only, behaviour preserved).

/// #2906 — whether a `channel.open()` failure is a transient worth retrying:
/// a slow/flaky adapter ([TimeoutException]), a typed recoverable disconnect
/// (`Obd2AdapterUnresponsive` / `Obd2DisconnectedException` —
/// [Obd2ConnectionError.isExpectedUserCondition]), or a raw BLE GATT-133 /
/// "device not connected" the classic/BLE channels surface
/// ([isBleAdapterDisconnect]). A genuine fault (permission denied, protocol
/// init) is NOT retried — it rethrows so the caller surfaces it.
///
/// #3181 — [Obd2PairingRequired] is EXPLICITLY excluded even though it is
/// an expected user condition: the failure means the FIRST-connect pairing
/// budget is already exhausted (or the adapter refused the bond), and the
/// inter-attempt `close()` → re-`open()` would dismiss an OS pairing
/// dialog still on screen / burn the adapter's 5-minute bond window on
/// doomed re-dials. It rethrows so the user gets the power-cycle guidance.
bool _isRecoverableOpenFailure(Object e) =>
    e is! Obd2PairingRequired &&
    (e is TimeoutException ||
        (e is Obd2ConnectionError && e.isExpectedUserCondition) ||
        isBleAdapterDisconnect(e));

/// #3014 — true when a channel-open failure carries Android GATT_ERROR 133.
/// Only a 133 warrants the (Android-only, OEM-variable) GATT-cache refresh
/// between retries; a plain timeout / typed disconnect just backs off + retries.
bool _isGatt133(Object e) {
  final msg = e.toString().toUpperCase();
  return msg.contains('133') || msg.contains('GATT_ERROR');
}

/// #3014 — shared RNG for the backoff jitter tail. One static instance so the
/// jitter doesn't reseed per call.
final Random _backoffJitter = Random();

/// #3014 — jittered exponential backoff for the channel-open retry: 250 ms on
/// attempt 1, 500 ms on attempt 2, 1000 ms on attempt 3, …, each plus a 0–125 ms
/// random tail. Capped at 2 s so a high attempt index can't stall the connect.
Duration _backoffForAttempt(int attempt) {
  final base = 250 * (1 << (attempt - 1)); // 250, 500, 1000, 2000, …
  final capped = base > 2000 ? 2000 : base;
  return Duration(milliseconds: capped + _backoffJitter.nextInt(126));
}

/// The bounded channel-open retry loop of [BluetoothObd2Transport.connect]
/// (#2906), extracted verbatim (#3760).
///
/// #2906 — the channel open is the #1 fragility point: a transient BLE
/// GATT-133 / Classic rfcomm-open-fail used to abort the whole connect with
/// ZERO retry (the existing _withConnectRetry only wraps the ELM send
/// handshake, AFTER the channel is already open). Bounded retry + backoff,
/// with a best-effort teardown between attempts so a half-open GATT/socket
/// is cleared before the next try (the stale-client → repeat-133 trap).
Future<void> _openChannelWithRetry(ElmByteChannel channel) async {
  const maxOpenAttempts = 3;
  for (var attempt = 1; ; attempt++) {
    try {
      await channel.open();
      break;
    } catch (e, st) {
      if (attempt >= maxOpenAttempts || !_isRecoverableOpenFailure(e)) {
        rethrow;
      }
      debugPrint('BluetoothObd2Transport: channel.open attempt $attempt/'
          '$maxOpenAttempts failed ($e), tearing down + retrying after '
          'backoff\n$st');
      // #3014 — ensure the half-open client is TRULY closed before retrying.
      // FBP's `disconnect()` inside `close()` may not fully release a
      // half-open GATT client, so a stale client survives into the next
      // connect → repeat-133. close() is best-effort here.
      try {
        await channel.close();
      } catch (_) {
        // Best-effort teardown, swallowed by design — counted (#3610).
        healthCounters.increment('bt.teardown_fail');
        BreadcrumbCollector.add('bt.teardown_fail',
            detail: 'channel.close during open retry');
      }
      // #3014 — GATT-133 recovery: on a 133 (cache-poisoned device — a clone
      // whose GATT table mutated, or a stale cache from the aborted attempt),
      // drop the native service cache before the next try so a fresh
      // discovery runs against the real table. Best-effort + Android-only +
      // never throws; a no-op for Classic / non-recoverable channels.
      if (_isGatt133(e)) {
        final ch = channel;
        if (ch is Obd2GattRecoverable) {
          try {
            await (ch as Obd2GattRecoverable).refreshGattCache();
          } catch (_) {
            // OEM-variable reflection, swallowed — counted (#3610).
            healthCounters.increment('bt.teardown_fail');
            BreadcrumbCollector.add('bt.teardown_fail',
                detail: 'refreshGattCache during open retry');
          }
        }
      }
      // #3014 — jittered exponential backoff (250 → 500 → 1000 ms + a small
      // random tail) instead of the old flat 150·attempt. The exponential
      // step gives a flaky Android BLE stack progressively more room to
      // settle between retries; the jitter de-syncs a repeat-133 retry storm
      // from the device's own advertising cadence (van Welie / Punch Through).
      await Future<void>.delayed(_backoffForAttempt(attempt));
    }
  }
}
