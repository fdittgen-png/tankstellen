// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/elm327_adapter.dart';
import 'package:tankstellen/features/obd2/data/elm327_protocol.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';

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
        '#2906 connect RETRIES a transient channel.open() failure '
        '(GATT-133 / rfcomm-open-fail) with teardown between attempts',
        () async {
      final channel = _ScriptedChannel();
      // First two open() attempts throw a typed recoverable disconnect, the
      // third succeeds — exactly the stale-GATT/rfcomm transient that used to
      // abort the whole connect with no retry.
      channel.scriptOpenFailures(2, const Obd2AdapterUnresponsive());

      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      expect(transport.isConnected, isTrue,
          reason: 'connect must succeed after retrying the transient open');
      expect(channel.openAttempts, 3,
          reason: 'two failures + one success = three open() attempts');
      expect(channel.closeCalls, 2,
          reason: 'a teardown runs between each failed attempt to clear the '
              'half-open GATT/socket');
    });

    test(
        '#2906 connect does NOT retry a genuine (non-transient) open() '
        'failure — it rethrows after one attempt', () async {
      final channel = _ScriptedChannel();
      // A permission denial is a real fault, not a flaky link → no retry.
      channel.scriptOpenFailures(99, const Obd2PermissionDenied());

      final transport = BluetoothObd2Transport(channel);

      await expectLater(transport.connect(), throwsA(isA<Obd2PermissionDenied>()));
      expect(channel.openAttempts, 1, reason: 'genuine fault is not retried');
      expect(transport.isConnected, isFalse);
    });

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

    test(
        '#3639 disconnect() during a STALLED write does not surface an '
        'unhandled Transport-closed error', () async {
      final channel = _ScriptedChannel();
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // The platform write on a dying link never returns — `_sendRaw` is
      // suspended BEFORE the awaiter attaches to the pending completer.
      channel.scriptWriteHang('010D\r');
      unawaited(transport.sendCommand('010D\r').then(
        (_) => fail('a stalled command must not succeed'),
        // The abandoned command's error (if the caller path ever resumes)
        // is expected and handled here.
        onError: (Object _) {},
      ));
      // Let `_sendRaw` reach the stalled write.
      await Future<void>.delayed(Duration.zero);

      // Tearing down mid-write fails the pending completer while its
      // future has no listener yet — this must NOT escape to the zone as
      // an unhandled "Bad state: Transport closed" (the test framework
      // fails the test if it does).
      await transport.disconnect();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(transport.isConnected, isFalse);
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

    test(
        '#2295 — a notify-stream error fails the pending command IMMEDIATELY '
        '(no read-timeout wait)', () async {
      final channel = _ScriptedChannel();
      channel.scriptResponse('ATZ\r', 'ELM327>');
      // Script a reply that NEVER contains the '>' prompt, so the command
      // can only ever complete via the injected error path — never on a
      // happy-path prompt. A bounded read timeout that would dominate if
      // the error were swallowed: the fail-fast path must beat it.
      channel.scriptResponse('010D\r', '41 0D 3C ');
      final transport = BluetoothObd2Transport(
        channel,
        readTimeout: const Duration(seconds: 5),
      );
      await transport.connect();

      final sw = Stopwatch()..start();
      final pending = transport.sendCommand('010D\r');
      // Inject a GATT/ATT-style error on the channel's incoming stream
      // while the command is in flight — exactly what the BLE/Classic
      // channels now forward via `_incoming.addError` (#2295).
      await Future<void>.delayed(const Duration(milliseconds: 10));
      channel.injectError(Exception('simulated GATT error'));

      await expectLater(pending, throwsA(isA<Exception>()));
      sw.stop();
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)),
          reason: 'must fail-fast via the forwarded error, not wait out '
              'the 5 s read timeout');
    });

    test(
        '#2453 — a throwing write surfaces the error to ITS caller AND '
        'leaves the transport recoverable (next command succeeds)', () async {
      final channel = _ScriptedChannel();
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // First command's write rejects mid-session (device-not-connected /
      // GATT-write failure). Before #2453 this left `_pending` set, so the
      // NEXT command tripped the concurrent-sendCommand guard forever.
      final boom = Exception('GATT write failed: device not connected');
      channel.scriptWriteThrows('010C\r', boom);
      // The recovery command writes fine and gets a normal reply.
      channel.scriptResponse('010D\r', '41 0D 3C >');

      // 1) The failing command surfaces the write error to its caller.
      await expectLater(
        transport.sendCommand('010C\r'),
        throwsA(same(boom)),
        reason: 'the write error must reach the command that triggered it',
      );

      // 2) The NEXT command does NOT throw concurrent-sendCommand — the
      //    transport recovered because `_pending` was cleared on the throw.
      final reply = await transport.sendCommand('010D\r');
      expect(reply, contains('41 0D 3C'),
          reason: 'transport must recover: _pending was cleared on the '
              'throwing write, so the next command proceeds normally');
    });

    test(
        '#2453 — a read timeout still throws TimeoutException AND leaves the '
        'transport recoverable for the next command', () async {
      final channel = _ScriptedChannel();
      // First command's reply never carries the '>' prompt, so it can only
      // resolve via the read timeout. Use a short timeout to keep the test
      // fast.
      channel.scriptResponse('010C\r', '41 0C 1A F8 ');
      channel.scriptResponse('010D\r', '41 0D 3C >');
      final transport = BluetoothObd2Transport(
        channel,
        readTimeout: const Duration(milliseconds: 50),
      );
      await transport.connect();

      await expectLater(
        transport.sendCommand('010C\r'),
        throwsA(isA<TimeoutException>()),
      );

      // The timeout cleared `_pending` (via the finally), so the next
      // command is not blocked by the stale in-flight slot.
      final reply = await transport.sendCommand('010D\r');
      expect(reply, contains('41 0D 3C'));
    });

    test(
        '#2524 — a reconnect cycle leaves NO stranded _pending: a command '
        'in flight when the link drops is failed, and the next command on '
        'the reconnected instance succeeds', () async {
      final channel = _ScriptedChannel();
      // A reply that NEVER carries the prompt — the command can only resolve
      // via a forwarded link error, leaving _pending set until then.
      channel.scriptResponse('010C\r', '41 0C 1A F8 ');
      channel.scriptResponse('010D\r', '41 0D 3C >');
      final transport = BluetoothObd2Transport(
        channel,
        readTimeout: const Duration(seconds: 5),
      );
      await transport.connect();

      // Fire a command and, mid-flight, drop the link via a forwarded
      // channel error (the half-dead-reconnect trigger). The pending
      // command must FAIL — never hang — so a caller awaiting it unblocks.
      final pending = transport.sendCommand('010C\r');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      channel.injectError(Exception('GATT link dropped mid-command'));
      await expectLater(pending, throwsA(isA<Exception>()),
          reason: 'a stranded _pending must be failed cleanly on a link '
              'drop, not left to time out / hang (#2524)');

      // Reconnect the SAME instance. connect() resets _pending + _buffer so
      // no stale state survives into the fresh link.
      await transport.disconnect();
      await transport.connect();
      expect(transport.isConnected, isTrue);

      // The next command does NOT trip the concurrent-sendCommand guard
      // (which would now surface as Obd2DisconnectedException) and parses
      // a clean reply — proving _pending was null + _buffer empty on the
      // reconnected link.
      final reply = await transport.sendCommand('010D\r');
      expect(reply.trim(), '41 0D 3C',
          reason: 'the reconnected instance starts with _pending == null + '
              'an empty buffer, so the next command succeeds (#2524)');
    });

    test(
        '#2671 — a drop landing DURING the native write surfaces as the '
        'typed Obd2DisconnectedException and clears _pending (no poisoned '
        'transport)', () async {
      final channel = _ScriptedChannel();
      // The classic channel reclassifies a not-connected platform write
      // throw into a recoverable Obd2DisconnectedException (#2671 fix b).
      // Model that: the channel's write throws the typed disconnect.
      channel.scriptWriteThrows(
        '010C\r',
        const Obd2DisconnectedException(),
      );
      // The recovery command writes fine and gets a normal reply, proving
      // _pending was cleared on the throwing write.
      channel.scriptResponse('010D\r', '41 0D 3C >');
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // 1) The failing command surfaces the typed disconnect to its caller
      //    — the drop detector's `_isTypedDisconnect` routes this through
      //    pause/reconnect instead of logging an ERROR trace.
      await expectLater(
        transport.sendCommand('010C\r'),
        throwsA(isA<Obd2DisconnectedException>()),
      );

      // 2) _pending was cleared on the throw, so the NEXT command does not
      //    trip the concurrent-sendCommand guard (which itself now throws
      //    Obd2DisconnectedException). A clean reply proves the transport
      //    is not poisoned.
      final reply = await transport.sendCommand('010D\r');
      expect(reply.trim(), '41 0D 3C',
          reason: 'transport must recover: _pending cleared on the typed '
              'disconnect write, so the next command proceeds normally');
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

  group('#3731 — transport liveness truth on channel death', () {
    // Field logs 2026-08-16/17: after a classic-socket death the transport
    // kept isConnected=true forever (only deliberate disconnect() cleared
    // it), so the #3569 speed-stream watchdog, the #3725 supervisor-reuse
    // guards and the dead-husk hand-off check were ALL blind — a zombie
    // 1 Hz poller timed out on the corpse while fresh reconnected sessions
    // were discarded, idled, and got killed by the adapter's idle timeout
    // (flap ×3 → #3603 stand-down → whole trips with zero OBD2 data).

    Future<BluetoothObd2Transport> connected(_ScriptedChannel channel) async {
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();
      expect(transport.isConnected, isTrue);
      return transport;
    }

    test('channel DONE edge flips isConnected to false', () async {
      final channel = _ScriptedChannel();
      final transport = await connected(channel);

      await channel.injectDone();
      await pumpEventQueue();

      expect(transport.isConnected, isFalse,
          reason: 'a closed byte channel is a dead transport — every '
              'liveness guard in the stack keys off this flag');
    });

    test('channel ERROR edge flips isConnected to false', () async {
      final channel = _ScriptedChannel();
      final transport = await connected(channel);

      channel.injectError(const Obd2DisconnectedException('socket died'));
      await pumpEventQueue();

      expect(transport.isConnected, isFalse);
    });

    test('an in-flight command fails fast on the done edge instead of '
        'waiting out the read timeout', () async {
      final channel = _ScriptedChannel();
      // Write succeeds but the adapter never replies — the command sits
      // awaiting bytes when the socket dies.
      channel.scriptChunkedResponse('010D\r', const []);
      final transport = await connected(channel);

      final pending = transport.sendCommand('010D\r');
      final result = expectLater(
          pending, throwsA(isA<Obd2DisconnectedException>()));
      await channel.injectDone();
      await result;
      expect(transport.isConnected, isFalse);
    });

    test('sendCommand after the death edge throws the not-connected '
        'StateError (no writes to a corpse)', () async {
      final channel = _ScriptedChannel();
      final transport = await connected(channel);
      await channel.injectDone();
      await pumpEventQueue();

      expect(() => transport.sendCommand('010D\r'),
          throwsA(isA<StateError>()));
    });

    test('a deliberate disconnect() after the death edge stays clean '
        '(idempotent, no throw)', () async {
      final channel = _ScriptedChannel();
      final transport = await connected(channel);
      await channel.injectDone();
      await pumpEventQueue();

      await transport.disconnect();
      expect(transport.isConnected, isFalse);
    });
  });
}

// ---------------------------------------------------------------------------
// Scripted fake channel — one reply per written command.
// ---------------------------------------------------------------------------

class _ScriptedChannel implements ElmByteChannel {
  final Map<String, List<List<int>>> _chunksByCommand = {};
  final Map<String, Object> _writeThrowsByCommand = {};
  final Set<String> _writeHangsByCommand = {};
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();
  final List<List<int>> _writes = [];
  bool _open = false;

  // #2906 — make the first N open() calls throw a transient, then succeed.
  int _openFailuresRemaining = 0;
  Object _openFailure = StateError('open failed');
  int openAttempts = 0;
  int closeCalls = 0;

  void scriptOpenFailures(int count, Object error) {
    _openFailuresRemaining = count;
    _openFailure = error;
  }

  void scriptResponse(String command, String reply) {
    _chunksByCommand[command] = [reply.codeUnits];
  }

  void scriptChunkedResponse(String command, List<String> chunks) {
    _chunksByCommand[command] =
        chunks.map((c) => c.codeUnits).toList();
  }

  /// #2453 — make `write()` THROW for a given command, simulating a
  /// device-not-connected / GATT-write failure mid-session. The write is
  /// still recorded (so order assertions see it) before it throws.
  void scriptWriteThrows(String command, Object error) {
    _writeThrowsByCommand[command] = error;
  }

  /// #3639 — make `write()` STALL forever for a given command, simulating
  /// a dying link whose platform write never returns. The write is still
  /// recorded before stalling.
  void scriptWriteHang(String command) {
    _writeHangsByCommand.add(command);
  }

  /// #2295 — simulate a forwarded notify-stream error (what the real BLE
  /// / Classic channels now push via `_incoming.addError`).
  void injectError(Object error) {
    _controller.addError(error);
  }

  /// #3731 — simulate the byte stream CLOSING (the classic-socket-done
  /// edge: the reader completes instead of erroring).
  Future<void> injectDone() => _controller.close();

  List<String> get writesAsStrings =>
      _writes.map((w) => String.fromCharCodes(w)).toList();

  @override
  Future<void> open() async {
    openAttempts++;
    if (_openFailuresRemaining > 0) {
      _openFailuresRemaining--;
      throw _openFailure; // ignore: only_throw_errors
    }
    _open = true;
  }

  @override
  Future<void> close() async {
    closeCalls++;
    _open = false;
  }

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  Future<void> write(List<int> bytes) async {
    _writes.add(bytes);
    final command = String.fromCharCodes(bytes);
    if (_writeHangsByCommand.contains(command)) {
      // #3639 — stall forever: the platform write on a dying link that
      // never completes.
      return Completer<void>().future;
    }
    final throwFor = _writeThrowsByCommand[command];
    if (throwFor != null) {
      // #2453 — the underlying BLE/GATT write rejected. The transport must
      // surface this to the caller AND clear `_pending` so the next command
      // isn't poisoned.
      throw throwFor; // ignore: only_throw_errors
    }
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
