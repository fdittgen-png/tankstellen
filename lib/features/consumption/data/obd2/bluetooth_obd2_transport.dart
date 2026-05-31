// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'elm_byte_channel.dart';
import 'event_channel_cancel.dart';
import 'obd2_connection_errors.dart';
import 'obd2_read_timeout.dart';
import 'obd2_transport.dart';

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
    await _channel.open();
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
    final cls = classifyReadTimeout(
      command,
      firstCommandOnFreshLink: _firstCommandPending,
    );
    _firstCommandPending = false;
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
