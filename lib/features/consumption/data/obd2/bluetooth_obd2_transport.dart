// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

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
class BluetoothObd2Transport implements Obd2Transport {
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
        try {
          await _channel.close();
        } catch (_) {
          // best-effort teardown of a half-open link before retrying
        }
        await Future<void>.delayed(Duration(milliseconds: 150 * attempt));
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
  Future<String> sendCommand(String command) async {
    if (!_connected) {
      throw StateError('BluetoothObd2Transport not connected');
    }
    // #1972 — serialise every caller onto a single queue. The ELM327 is
    // half-duplex; without this a second consumer's command collided
    // with one already in flight and threw a concurrent-sendCommand
    // StateError.
    final completer = Completer<String>();
    _queueTail = _queueTail.then((_) async {
      // The transport may have been torn down while this command waited
      // its turn — fail it cleanly rather than writing to a closed link.
      if (!_connected) {
        completer.completeError(
          StateError('BluetoothObd2Transport not connected'),
        );
        return;
      }
      try {
        completer.complete(await _sendRaw(command));
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

  Future<String> _sendRaw(String command) async {
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
    final timeout = cls.timeout > _readTimeout ? _readTimeout : cls.timeout;

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
