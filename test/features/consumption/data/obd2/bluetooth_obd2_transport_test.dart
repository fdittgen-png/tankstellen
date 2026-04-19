import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';

/// TDD tests for the Bluetooth OBD2 transport (#716).
///
/// The transport itself is BLE-agnostic — it talks to any
/// [ElmByteChannel]. The real Bluetooth implementation is the
/// flutter_blue_plus wrapper, which needs a physical device to test;
/// these tests exercise the protocol logic (init sequence, command
/// round-trip, prompt accumulation, disconnect) against a scripted
/// fake channel.
void main() {
  group('BluetoothObd2Transport (#716)', () {
    test('connect runs the ELM init sequence and leaves isConnected=true',
        () async {
      final channel = _ScriptedChannel();
      // Scripted per-command responses — the channel streams each one
      // when the transport writes the matching command.
      channel.scriptResponse('ATZ\r', 'ELM327 v1.5>');
      channel.scriptResponse('ATE0\r', 'OK>');
      channel.scriptResponse('ATL0\r', 'OK>');
      channel.scriptResponse('ATH0\r', 'OK>');
      channel.scriptResponse('ATSP0\r', 'OK>');

      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      expect(transport.isConnected, isTrue);
      expect(channel.writesAsStrings, containsAllInOrder([
        Elm327Protocol.resetCommand,
        Elm327Protocol.echoOffCommand,
        Elm327Protocol.lineFeedsOffCommand,
        Elm327Protocol.headersOffCommand,
        Elm327Protocol.autoProtocolCommand,
      ]));
    });

    test('sendCommand writes the command, accumulates bytes until "> "', () async {
      final channel = _ScriptedChannel();
      channel.scriptResponse('ATZ\r', 'ELM327>');
      channel.scriptResponse('ATE0\r', 'OK>');
      channel.scriptResponse('ATL0\r', 'OK>');
      channel.scriptResponse('ATH0\r', 'OK>');
      channel.scriptResponse('ATSP0\r', 'OK>');
      channel.scriptResponse(
        '010D\r',
        '41 0D 3C >',
      );
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      final reply = await transport.sendCommand(Elm327Protocol.vehicleSpeedCommand);

      expect(reply, contains('41 0D 3C'));
      expect(reply, isNot(contains('>')),
          reason: 'the trailing prompt is consumed, not returned');
    });

    test('sendCommand throws StateError when called before connect', () async {
      final channel = _ScriptedChannel();
      final transport = BluetoothObd2Transport(channel);
      expect(() => transport.sendCommand('010D\r'), throwsStateError);
    });

    test('sendCommand handles chunked notifications', () async {
      // BLE notifications often arrive in 20-byte chunks. The transport
      // must accumulate across chunks until the "> " prompt.
      final channel = _ScriptedChannel();
      channel.scriptResponse('ATZ\r', 'ELM327>');
      channel.scriptResponse('ATE0\r', 'OK>');
      channel.scriptResponse('ATL0\r', 'OK>');
      channel.scriptResponse('ATH0\r', 'OK>');
      channel.scriptResponse('ATSP0\r', 'OK>');
      channel.scriptChunkedResponse('010D\r', ['41 ', '0D ', '3C', '>']);
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();
      final reply = await transport.sendCommand(Elm327Protocol.vehicleSpeedCommand);
      expect(reply.trim(), '41 0D 3C');
    });

    test('disconnect closes the channel and flips isConnected to false',
        () async {
      final channel = _ScriptedChannel();
      channel.scriptResponse('ATZ\r', 'ELM327>');
      channel.scriptResponse('ATE0\r', 'OK>');
      channel.scriptResponse('ATL0\r', 'OK>');
      channel.scriptResponse('ATH0\r', 'OK>');
      channel.scriptResponse('ATSP0\r', 'OK>');
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      await transport.disconnect();
      expect(transport.isConnected, isFalse);
      expect(channel.isOpen, isFalse);
    });
  });
}

// ---------------------------------------------------------------------------
// Scripted fake channel — one reply per written command.
// ---------------------------------------------------------------------------

class _ScriptedChannel implements ElmByteChannel {
  final Map<String, List<List<int>>> _chunksByCommand = {};
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();
  final List<List<int>> _writes = [];
  bool _open = false;

  void scriptResponse(String command, String reply) {
    _chunksByCommand[command] = [reply.codeUnits];
  }

  void scriptChunkedResponse(String command, List<String> chunks) {
    _chunksByCommand[command] =
        chunks.map((c) => c.codeUnits).toList();
  }

  List<String> get writesAsStrings =>
      _writes.map((w) => String.fromCharCodes(w)).toList();

  @override
  Future<void> open() async => _open = true;

  @override
  Future<void> close() async => _open = false;

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  Future<void> write(List<int> bytes) async {
    _writes.add(bytes);
    final command = String.fromCharCodes(bytes);
    final chunks = _chunksByCommand[command];
    if (chunks == null) {
      // Unknown command — send NO DATA> so the transport doesn't hang.
      _controller.add('NO DATA>'.codeUnits);
      return;
    }
    for (final chunk in chunks) {
      // Spread across microtasks to simulate BLE notifications.
      await Future<void>.delayed(Duration.zero);
      _controller.add(chunk);
    }
  }
}
