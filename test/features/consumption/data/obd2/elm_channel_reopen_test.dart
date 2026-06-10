// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'classic_elm_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'classic_method_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'flutter_blue_plus_elm_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_connection_errors.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'obd2_link_drop_signal.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #3179 — the zombie retry channel.
///
/// [BluetoothObd2Transport.connect] retries a recoverable `open()` failure by
/// `close()` + `open()` on the SAME channel instance. But both production
/// channels ([FlutterBluePlusElmChannel], [ClassicElmChannel]) used a `final`
/// broadcast `_incoming` controller that `close()` closes and `open()` never
/// recreated, and a `_closing` latch that was never reset — so the "recovered"
/// link was a zombie: every later notify byte was silently dropped (the
/// `isClosed` guard), every reply timed out, and drop detection / drop-error
/// delivery were permanently dead.
///
/// These tests drive the REAL channels through close() → open() and assert
/// bytes + drop signals flow on the reopened link. RED on master.
class _ReopenFakePlugin extends Obd2ClassicMethodChannel {
  _ReopenFakePlugin({this.failuresBeforeSuccess = 0});

  /// How many connectDetailed calls fail (rfcomm-open false) before success.
  final int failuresBeforeSuccess;
  int connectCalls = 0;
  final writes = <List<int>>[];
  Object? writeError;

  /// Re-openable native side: each EventChannel listen gets the live stream.
  StreamController<List<int>> incomingController =
      StreamController<List<int>>.broadcast();

  @override
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
  }) async {
    connectCalls++;
    if (connectCalls <= failuresBeforeSuccess) {
      return (ok: false, strategy: 'exhausted', error: 'rfcomm open failed');
    }
    return (ok: true, strategy: 'secure', error: null);
  }

  @override
  Future<void> write(List<int> bytes) async {
    writes.add(List<int>.from(bytes));
    final e = writeError;
    if (e != null) throw e;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  Future<void> dispose() async {
    if (!incomingController.isClosed) await incomingController.close();
  }
}

/// FBP channel with the unfakeable seams stubbed so open()/close()/open() runs
/// without a BLE stack (the #3014 _TestChannel precedent).
class _ReopenableFbpChannel extends FlutterBluePlusElmChannel {
  _ReopenableFbpChannel(super.device, {super.dropDebounce});

  @override
  Future<void> connectDevice() async {}

  @override
  Future<void> discoverAndBind() async {}

  @override
  void bindConnectionState() {}

  @override
  Future<void> tuneForRecording() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  silenceErrorLoggerSpool();

  group('#3179 — transport open-retry must yield a LIVE channel', () {
    test(
        'a recoverable first open() failure + a successful retry → bytes flow '
        'end-to-end (write a command, deliver notify bytes, reply completes)',
        () async {
      final plugin = _ReopenFakePlugin(failuresBeforeSuccess: 1);
      addTearDown(plugin.dispose);
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: plugin);
      final transport = BluetoothObd2Transport(
        channel,
        readTimeout: const Duration(milliseconds: 400),
      );
      addTearDown(transport.disconnect);

      // Attempt 1 fails recoverably (Obd2AdapterUnresponsive), the transport
      // close()s + retries, attempt 2 succeeds.
      await transport.connect();
      expect(transport.isConnected, isTrue);
      expect(plugin.connectCalls, 2);

      // The recovered link must MOVE BYTES — the documented false-green was
      // asserting only attempt counts while the reopened channel's incoming
      // controller stayed closed and every reply timed out.
      final reply = transport.sendCommand('010D');
      // Let the queued write land before the adapter "answers".
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(plugin.writes, isNotEmpty,
          reason: 'the command must reach the (re)opened link');
      plugin.incomingController.add('41 0D 00\r>'.codeUnits);

      await expectLater(reply, completion(contains('41 0D 00')),
          reason: 'notify bytes on the reopened channel must complete the '
              'pending reply — a zombie channel drops them silently');
    });
  });

  group('#3179 — ClassicElmChannel is safely re-openable', () {
    test('close() → open() → incoming bytes flow again', () async {
      final plugin = _ReopenFakePlugin();
      addTearDown(plugin.dispose);
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: plugin);

      await channel.open();
      await channel.close();
      await channel.open();
      expect(channel.isOpen, isTrue);

      final received = <List<int>>[];
      final sub = channel.incoming.listen(received.add);
      addTearDown(sub.cancel);
      plugin.incomingController.add([0x41, 0x54]);
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        [0x41, 0x54],
      ]);
      await channel.close();
    });

    test(
        'drop detection still works after a reopen — a reader-stream error '
        'fires the proactive link-drop signal AND surfaces on incoming',
        () async {
      final plugin = _ReopenFakePlugin();
      addTearDown(plugin.dispose);
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: plugin);

      await channel.open();
      await channel.close(); // deliberate close latches `_closing` on master
      await channel.open();

      final drops = <Obd2LinkDropEvent>[];
      final dropSub = Obd2LinkDropSignal.instance.drops.listen(drops.add);
      addTearDown(dropSub.cancel);
      final errors = <Object>[];
      final sub = channel.incoming.listen((_) {}, onError: errors.add);
      addTearDown(sub.cancel);

      plugin.incomingController.addError(
        PlatformException(code: 'state', message: 'not connected'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(channel.isOpen, isFalse);
      expect(errors, isNotEmpty,
          reason: 'the socket error must be forwarded on the reopened '
              'incoming stream so a pending command fails fast');
      expect(drops, hasLength(1),
          reason: 'an unexpected drop AFTER a reopen must still fire the '
              'proactive link-drop signal (the `_closing`/`_dropSignalled` '
              'latches must reset on open)');
      await channel.close();
    });
  });

  group('#3179 — FlutterBluePlusElmChannel is safely re-openable', () {
    test('close() → open() → the incoming stream is live (not done)',
        () async {
      final channel = _ReopenableFbpChannel(
        BluetoothDevice.fromId('AA:BB:CC:DD:EE:79'),
      );

      await channel.open();
      await channel.close();
      await channel.open();
      expect(channel.isOpen, isTrue);

      var doneFired = false;
      final sub = channel.incoming.listen((_) {}, onDone: () {
        doneFired = true;
      });
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);

      expect(doneFired, isFalse,
          reason: 'after a reopen the incoming stream must be a LIVE '
              'controller, not the closed one the previous close() left');
      await channel.close();
    });

    test('close() → open() → notify bytes flow on the reopened stream',
        () async {
      final channel = _ReopenableFbpChannel(
        BluetoothDevice.fromId('AA:BB:CC:DD:EE:80'),
      );

      await channel.open();
      await channel.close();
      await channel.open();

      final received = <List<int>>[];
      final sub = channel.incoming.listen(received.add);
      addTearDown(sub.cancel);
      // The exact production notify-stream data path (#3179 seam).
      channel.handleNotifyBytes([0x41, 0x0D]);
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        [0x41, 0x0D],
      ]);
      await channel.close();
    });

    test(
        'drop detection still works after a reopen — a debounce-confirmed '
        'disconnect edge delivers the typed drop error AND fires the '
        'proactive link-drop signal', () async {
      final channel = _ReopenableFbpChannel(
        BluetoothDevice.fromId('AA:BB:CC:DD:EE:81'),
        dropDebounce: const Duration(milliseconds: 30),
      );

      await channel.open();
      await channel.close(); // disposes the debouncer + latches `_closing`
      await channel.open();

      final drops = <Obd2LinkDropEvent>[];
      final dropSub = Obd2LinkDropSignal.instance.drops.listen(drops.add);
      addTearDown(dropSub.cancel);
      final errors = <Object>[];
      final sub = channel.incoming.listen((_) {}, onError: errors.add);
      addTearDown(sub.cancel);

      channel.debugNoteConnectionState(disconnected: true);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(errors, hasLength(1),
          reason: 'the confirmed drop must push the typed disconnect onto '
              'the reopened byte stream');
      expect(errors.single, isA<Obd2DisconnectedException>());
      expect(drops, hasLength(1),
          reason: 'the proactive drop signal must fire after a reopen — the '
              '`_closing`/`_dropSignalled` latches reset on open()');
      await channel.close();
    });
  });
}
