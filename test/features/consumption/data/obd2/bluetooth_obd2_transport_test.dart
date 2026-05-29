// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';

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
    test(
        'connect opens the channel and leaves isConnected=true WITHOUT '
        'sending the ELM init (init is the service\'s job now, #2233)',
        () async {
      final channel = _ScriptedChannel();
      // Scripted per-command responses — present but the transport must
      // no longer fire them on connect(): #2233 moved the init burst to
      // [Obd2Service.connect] so it is sent exactly once, not twice.
      channel.scriptResponse('ATZ\r', 'ELM327 v1.5>');
      channel.scriptResponse('ATE0\r', 'OK>');
      channel.scriptResponse('ATL0\r', 'OK>');
      channel.scriptResponse('ATH0\r', 'OK>');
      channel.scriptResponse('ATSP0\r', 'OK>');

      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      expect(transport.isConnected, isTrue,
          reason: '_connected must flip true so the service-side init '
              'can send — sendCommand throws on !_connected');
      expect(channel.isOpen, isTrue);
      expect(channel.writesAsStrings, isEmpty,
          reason: 'the transport no longer self-inits (#2233)');
    });

    // #2233 — regression guard: the ELM327 init handshake must run EXACTLY
    // ONCE across a full transport.connect() + service-driven init. Before
    // #2233 the transport ran the six AT commands AND Obd2Service.connect
    // re-sent them, so ATZ went out twice — the second reset wiped state
    // and re-paid a 1–2 s clone re-enumeration.
    test('ATZ is sent exactly once across transport + service connect',
        () async {
      final channel = _ScriptedChannel();
      // Script the full init + the firmware probe the service sends after
      // the init burst (#1401), so the service connect completes cleanly.
      channel.scriptResponse('ATZ\r', 'ELM327 v1.5>');
      channel.scriptResponse('ATE0\r', 'OK>');
      channel.scriptResponse('ATL0\r', 'OK>');
      channel.scriptResponse('ATH0\r', 'OK>');
      channel.scriptResponse('ATSP0\r', 'OK>');
      channel.scriptResponse('ATAT1\r', 'OK>');
      channel.scriptResponse('ATI\r', 'ELM327 v1.5>');

      // The transport connect (channel open + subscribe, no init) followed
      // by the single init owner: Obd2Service.connect drives
      // adapter.initSequence over the SAME transport.
      final transport = BluetoothObd2Transport(channel);
      final service = Obd2Service(transport);
      final connected = await service.connect(
        adapter: const GenericElm327Adapter(),
      );

      expect(connected, isTrue);
      final atzCount = channel.writesAsStrings
          .where((w) => w == Elm327Protocol.resetCommand)
          .length;
      expect(atzCount, 1,
          reason: 'the init handshake must run once, not twice (#2233)');
      // The rest of the init burst is likewise sent once, in order.
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

    test(
        'overlapping sendCommand calls serialise instead of colliding (#1972)',
        () async {
      final channel = _ScriptedChannel();
      channel.scriptResponse('ATZ\r', 'ELM327>');
      channel.scriptResponse('ATE0\r', 'OK>');
      channel.scriptResponse('ATL0\r', 'OK>');
      channel.scriptResponse('ATH0\r', 'OK>');
      channel.scriptResponse('ATSP0\r', 'OK>');
      channel.scriptResponse('010C\r', '41 0C 1A F8 >');
      channel.scriptResponse('010D\r', '41 0D 3C >');
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // Fire both WITHOUT awaiting the first — a VIN read racing the
      // auto-record PID poller on the shared transport. Pre-#1972 the
      // second call threw a concurrent-sendCommand StateError.
      final f1 = transport.sendCommand('010C\r');
      final f2 = transport.sendCommand('010D\r');
      final results = await Future.wait([f1, f2]);

      expect(results[0], contains('41 0C 1A F8'));
      expect(results[1], contains('41 0D 3C'));
      // The second command must be written only after the first's
      // round-trip — the queue preserves order on the half-duplex link.
      expect(
        channel.writesAsStrings.sublist(channel.writesAsStrings.length - 2),
        ['010C\r', '010D\r'],
      );
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
