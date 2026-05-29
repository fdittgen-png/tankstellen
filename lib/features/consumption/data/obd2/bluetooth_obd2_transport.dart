// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'elm_byte_channel.dart';
import 'event_channel_cancel.dart';
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
    // reached `_sendRaw` while another command was unfinished.
    if (_pending != null) {
      throw StateError(
        'BluetoothObd2Transport: concurrent sendCommand is not allowed',
      );
    }
    _buffer.clear();
    final completer = Completer<String>();
    _pending = completer;
    await _channel.write(command.codeUnits);
    return completer.future.timeout(
      _readTimeout,
      onTimeout: () {
        _pending = null;
        throw TimeoutException(
          'ELM327 did not respond within $_readTimeout',
          _readTimeout,
        );
      },
    );
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
