import 'dart:async';

import 'package:flutter/foundation.dart';

import 'elm327_protocol.dart';
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
    for (final command in Elm327Protocol.initCommands) {
      await _sendRaw(command);
    }
    _connected = true;
  }

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) {
      throw StateError('BluetoothObd2Transport not connected');
    }
    return _sendRaw(command);
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
    // Queuing is handled by Future chaining at the service layer;
    // reject overlapping writes here explicitly.
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
