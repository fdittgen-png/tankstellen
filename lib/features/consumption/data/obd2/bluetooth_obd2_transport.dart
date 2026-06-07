// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import 'ble_disconnect_classifier.dart';
import 'elm_byte_channel.dart';
import 'event_channel_cancel.dart';
import 'obd2_connection_errors.dart';
import 'obd2_read_timeout.dart';
import 'obd2_transport.dart';

/// #2906 — whether a `channel.open()` failure is a transient worth retrying:
/// a slow/flaky adapter ([TimeoutException]), a typed recoverable disconnect
/// (`Obd2AdapterUnresponsive` / `Obd2DisconnectedException` —
/// [Obd2ConnectionError.isExpectedUserCondition]), or a raw BLE GATT-133 /
/// "device not connected" the classic/BLE channels surface
/// ([isBleAdapterDisconnect]). A genuine fault (permission denied, protocol
/// init) is NOT retried — it rethrows so the caller surfaces it.
bool _isRecoverableOpenFailure(Object e) =>
    e is TimeoutException ||
    (e is Obd2ConnectionError && e.isExpectedUserCondition) ||
    isBleAdapterDisconnect(e);

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

/// [Obd2Transport] that moves bytes over a generic [ElmByteChannel]
/// (#716 step 1).
///
/// The channel abstraction keeps this class BLE-free so it can be
/// unit-tested without a real adapter. The concrete Bluetooth
/// implementation — [FlutterBluePlusElmChannel] — adapts
/// flutter_blue_plus to the same interface.
///
/// Protocol detail: every ELM327 response ends with the prompt
/// character `>` (0x3E). BLE notifications commonly arrive as 20-byte
/// chunks, so reads accumulate a buffer until the prompt is seen, then
/// return the accumulated string minus the prompt. A hard timeout
/// guards against a stuck adapter.
class BluetoothObd2Transport
    implements Obd2Transport, Obd2ProtocolSearchTransport {
  final ElmByteChannel _channel;
  final Duration _readTimeout;
  StreamSubscription<List<int>>? _subscription;
  final StringBuffer _buffer = StringBuffer();
  Completer<String>? _pending;
  bool _connected = false;

  /// #2261 concern 5 — true until the FIRST command of a fresh link
  /// completes. The first command faces a waking ECU / a pending
  /// protocol search, so it gets a longer read-timeout class than the
  /// same command would later. Reset on every [connect].
  bool _firstCommandPending = true;

  /// #2889 — count of AT commands sent since the channel opened. Fed to
  /// [classifyReadTimeout] as `atCommandsSinceOpen` so the first
  /// [earlyInitGraceCount] AT echoes (ATE0/ATL0/ATH0 in the standard init)
  /// get the longer `wake` budget — a slow Classic-SPP clone keeps echo on
  /// for the first couple of commands and answers ATE0 in ~2.3 s, which the
  /// old flat 1 s `trivialAt` budget could not absorb. Reset on [connect].
  int _atCommandsSinceOpen = 0;

  /// #2889 — one-shot latch armed when a per-command read times out. The
  /// device's slow original reply can still land AFTER the timeout fired;
  /// without this it would be matched to the NEXT command's `_pending`,
  /// desyncing the whole init burst by one command forever. When set, the
  /// next complete `>`-terminated frame that arrives with NO `_pending`
  /// awaiting it (i.e. the stale late reply) is DROPPED and the latch
  /// cleared, instead of completing any completer. Always cleared again on
  /// the next successfully-matched completion and on [disconnect], so it can
  /// never swallow a legitimate reply.
  bool _swallowNextFrame = false;

  /// Tail of the command queue. Every [sendCommand] chains onto this so
  /// overlapping callers — e.g. the VIN reader racing the auto-record
  /// PID poller, both sharing one transport — serialise instead of
  /// colliding on the half-duplex ELM327 link (#1972). The tail tracks
  /// completion of each command (success *or* error) so one failed
  /// command never stalls the queue behind it.
  Future<void> _queueTail = Future<void>.value();

  BluetoothObd2Transport(
    this._channel, {
    Duration readTimeout = const Duration(seconds: 5),
  }) : _readTimeout = readTimeout;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) return;
    _firstCommandPending = true;
    _atCommandsSinceOpen = 0; // #2889 — fresh early-init grace window.
    _swallowNextFrame = false; // #2889 — never carry a latch across links.
    // #2524 — reset any state a previous link left behind so a reused or
    // half-dead instance can't carry stale pending into the fresh link. A
    // dropped session that never ran `disconnect()` can leave `_pending`
    // pointing at a never-completing completer and `_buffer` holding a
    // partial response; either one would poison the first command on the
    // new channel (the concurrent-sendCommand guard, or a corrupt parse).
    // Fail (not just drop) any stranded pending so a caller awaiting it
    // unblocks instead of hanging forever.
    _failPending(StateError('Transport reconnecting'));
    _buffer.clear();
    // #2906 — the channel open is the #1 fragility point: a transient BLE
    // GATT-133 / Classic rfcomm-open-fail used to abort the whole connect with
    // ZERO retry (the existing _withConnectRetry only wraps the ELM send
    // handshake, AFTER the channel is already open). Bounded retry + backoff,
    // with a best-effort teardown between attempts so a half-open GATT/socket
    // is cleared before the next try (the stale-client → repeat-133 trap).
    const maxOpenAttempts = 3;
    for (var attempt = 1; ; attempt++) {
      try {
        await _channel.open();
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
          await _channel.close();
        } catch (_) {
          // best-effort teardown of a half-open link before retrying
        }
        // #3014 — GATT-133 recovery: on a 133 (cache-poisoned device — a clone
        // whose GATT table mutated, or a stale cache from the aborted attempt),
        // drop the native service cache before the next try so a fresh
        // discovery runs against the real table. Best-effort + Android-only +
        // never throws; a no-op for Classic / non-recoverable channels.
        if (_isGatt133(e)) {
          final ch = _channel;
          if (ch is Obd2GattRecoverable) {
            try {
              await (ch as Obd2GattRecoverable).refreshGattCache();
            } catch (_) {
              // OEM-variable reflection; swallow — the retry proceeds anyway.
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
    _subscription = _channel.incoming.listen(
      _onBytes,
      onError: (e, st) {
        debugPrint('BluetoothObd2Transport: channel error: $e');
        _failPending(e);
      },
    );
    // #2233 — the transport NO LONGER runs the ELM327 init handshake.
    // The init (ATZ/ATE0/ATL0/ATH0/ATSP0/ATAT1) is owned solely by
    // [Obd2Service.connect], which sends `adapter.initSequence`. Running
    // it here too sent the six commands TWICE per connect — the second
    // ATZ wiped the first init's echo/header/protocol state and re-paid
    // a 1–2 s clone re-enumeration. We still flip `_connected=true` here
    // once the channel is open and subscribed, because [sendCommand]
    // throws on `!_connected` and the service-side init must be able to
    // send. Every production caller routes through [Obd2Service.connect]
    // (directly or via [Obd2ConnectionService.connect]/`connectByMac`),
    // so the adapter still receives exactly one init burst.
    _connected = true;
  }

  @override
  Future<String> sendCommand(String command) => _enqueue(command, null);

  /// #3037 — send [command] on the half-duplex queue with a GENEROUS one-shot
  /// read window ([readTimeout]) that OVERRIDES the steady-state read-timeout
  /// ceiling for this single command. The `0100` protocol-search probe uses
  /// this to give the ELM327 auto-search a single long read (~15 s) instead of
  /// re-sending mid-search (which would restart the search). Every other
  /// serialisation guarantee of [sendCommand] still holds — this chains onto
  /// the SAME `_queueTail` so it never collides with an in-flight command.
  @override
  Future<String> sendCommandWithReadTimeout(
          String command, Duration readTimeout) =>
      _enqueue(command, readTimeout);

  /// #1972 — serialise every caller onto a single queue. The ELM327 is
  /// half-duplex; without this a second consumer's command collided with one
  /// already in flight and threw a concurrent-sendCommand StateError. A
  /// non-null [readTimeoutOverride] (#3037) gives this one command the generous
  /// protocol-search window instead of the steady-state class.
  Future<String> _enqueue(String command, Duration? readTimeoutOverride) {
    if (!_connected) {
      throw StateError('BluetoothObd2Transport not connected');
    }
    final completer = Completer<String>();
    _queueTail = _queueTail.then((_) async {
      // The transport may have been torn down while this command waited its
      // turn — fail it cleanly rather than writing to a closed link.
      if (!_connected) {
        completer.completeError(
          StateError('BluetoothObd2Transport not connected'),
        );
        return;
      }
      try {
        completer.complete(
            await _sendRaw(command, readTimeoutOverride: readTimeoutOverride));
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// #2261 concern 4 — forward link-tuning to the underlying channel
  /// when it is a BLE [Obd2LinkTuner]. No-op for channels that don't
  /// expose tuning (Classic SPP, test fakes), so callers can tune
  /// unconditionally. Best-effort: the channel itself swallows platform
  /// rejections.
  Future<void> tuneForRecording() async {
    final ch = _channel;
    if (ch is Obd2LinkTuner) {
      await (ch as Obd2LinkTuner).tuneForRecording();
    }
  }

  /// Drop the link to balanced priority when only the 1 Hz auto-record
  /// stream is live (#2261 concern 4).
  Future<void> tuneForBackground() async {
    final ch = _channel;
    if (ch is Obd2LinkTuner) {
      await (ch as Obd2LinkTuner).tuneForBackground();
    }
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    await _subscription?.safeCancel();
    _subscription = null;
    await _channel.close();
    _failPending(StateError('Transport closed'));
    _buffer.clear();
    _swallowNextFrame = false; // #2889 — never carry a latch across links.
  }

  Future<String> _sendRaw(String command, {Duration? readTimeoutOverride}) async {
    // One in-flight command at a time — the ELM327 is half-duplex.
    // [sendCommand] serialises every caller onto `_queueTail`, so this
    // guard is now a defensive invariant: tripping it means a code path
    // reached `_sendRaw` while another command was unfinished — in
    // practice a stranded `_pending` left behind by a half-dead link.
    // #2524 — fail with a RECOVERABLE [Obd2DisconnectedException] (which
    // the drop detector's `_isTypedDisconnect` already treats as a drop)
    // instead of a raw `StateError`. The raw StateError surfaced as an
    // ERROR trace in the user log; routing it through the drop path means
    // the recording loop recovers (reconnect / pause-with-grace) and no
    // error trace is logged.
    if (_pending != null) {
      throw const Obd2DisconnectedException(
        'BluetoothObd2Transport: concurrent sendCommand — link is recovering',
      );
    }
    // #2261 concern 5 — right-size the read timeout per command class
    // instead of a flat 5 s. Clamped to the configured [_readTimeout] so
    // an explicit override still acts as a hard ceiling.
    // #2889 — pass the AT-command index so the first [earlyInitGraceCount]
    // AT echoes on a fresh link get the longer `wake` budget. The counter
    // is read BEFORE the post-increment below so this command sees its own
    // 0-based position; non-AT (OBD) commands don't advance it.
    final cls = classifyReadTimeout(
      command,
      firstCommandOnFreshLink: _firstCommandPending,
      atCommandsSinceOpen: _atCommandsSinceOpen,
    );
    _firstCommandPending = false;
    if (_isAtCommand(command)) _atCommandsSinceOpen++;
    // #3037 — an explicit [readTimeoutOverride] (the `0100` protocol-search
    // probe's ~15 s generous window) bypasses the steady-state [_readTimeout]
    // ceiling: the auto-search legitimately outlasts the 5 s class on a slow
    // link, and re-sending mid-search would restart it. Without an override
    // the per-class budget is still clamped to [_readTimeout] as before.
    final timeout = readTimeoutOverride ??
        (cls.timeout > _readTimeout ? _readTimeout : cls.timeout);

    _buffer.clear();
    final completer = Completer<String>();
    _pending = completer;
    // Clear `_pending` on EVERY exit — success, timeout *or* a throwing
    // write (#2453). Before, if `_channel.write()` threw (device-not-
    // connected / GATT timeout) with `_pending` still set, every later
    // command tripped the concurrent-sendCommand guard and the transport
    // stayed poisoned. The `identical` guard leaves a normally-completed
    // command alone — `_onBytes` already nulled `_pending`, or a later
    // command reassigned it — so finally only clears the slot it still owns.
    try {
      await _channel.write(command.codeUnits);
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          // #2889 — the reply may STILL land after this fires (the observed
          // 2.3 s ATE0 on a slow clone). Arm the one-shot latch so the late
          // `>`-terminated frame is dropped by [_onBytes] instead of being
          // matched to the NEXT command's completer — that mismatch was the
          // permanent one-command desync (protocol unknown → 0 PIDs).
          _swallowNextFrame = true;
          throw TimeoutException(
            'ELM327 did not respond within $timeout',
            timeout,
          );
        },
      );
    } finally {
      if (identical(_pending, completer)) _pending = null;
    }
  }

  /// #2889 — whether [command] is an AT/ST configuration command (vs an
  /// OBD request). Mirrors the AT detection in [classifyReadTimeout]; only
  /// AT commands advance the early-init grace counter.
  static bool _isAtCommand(String command) {
    final c = command.trim().toUpperCase();
    return c.startsWith('AT') || c.startsWith('ST');
  }

  void _onBytes(List<int> chunk) {
    _buffer.write(String.fromCharCodes(chunk));
    final content = _buffer.toString();
    final promptIdx = content.indexOf('>');
    if (promptIdx < 0) return;
    final body = content.substring(0, promptIdx);
    _buffer.clear();
    // If more chunks arrived past the prompt (rare but legal), keep
    // them for the next read.
    if (promptIdx + 1 < content.length) {
      _buffer.write(content.substring(promptIdx + 1));
    }
    final completer = _pending;
    _pending = null;
    // #2889 — resync after a per-command timeout. When the latch is armed
    // AND no completer is awaiting this frame, it is the stale late reply
    // of the command that just timed out (e.g. a slow clone's 2.3 s ATE0).
    // Drop it and clear the latch so the NEXT command stays aligned with
    // ITS own reply instead of inheriting this one (the desync root cause).
    if (_swallowNextFrame && completer == null) {
      _swallowNextFrame = false;
      return;
    }
    // A legitimate reply matched a waiting command — the link is back in
    // sync, so the latch (if somehow still set) must not survive to swallow
    // a future real reply.
    if (completer != null) _swallowNextFrame = false;
    completer?.complete(body);
  }

  void _failPending(Object error) {
    final completer = _pending;
    _pending = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  }
}
