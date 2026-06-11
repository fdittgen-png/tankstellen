// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/obd2/data/connection_drop_debouncer.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';

import 'dart:async';

/// #2261 concern 1 — connectionState-driven drop detection + debounce.
void main() {
  group('ConnectionDropDebouncer (#2261 concern 1)', () {
    test('a disconnect held for the full debounce confirms the drop', () {
      fakeAsync((async) {
        var confirmed = 0;
        final d = ConnectionDropDebouncer(
          onConfirmed: () => confirmed++,
          debounce: const Duration(milliseconds: 1500),
        );

        d.noteConnectionState(disconnected: true);
        expect(d.isPending, isTrue);
        expect(confirmed, 0, reason: 'not confirmed until the debounce elapses');

        async.elapse(const Duration(milliseconds: 1499));
        expect(confirmed, 0);

        async.elapse(const Duration(milliseconds: 2));
        expect(confirmed, 1, reason: 'confirmed once the debounce elapses');
        expect(d.isConfirmed, isTrue);
      });
    });

    test('a self-healing blip (reconnect before debounce) does NOT confirm',
        () {
      fakeAsync((async) {
        var confirmed = 0;
        final d = ConnectionDropDebouncer(
          onConfirmed: () => confirmed++,
          debounce: const Duration(milliseconds: 1500),
        );

        d.noteConnectionState(disconnected: true);
        async.elapse(const Duration(milliseconds: 800));
        // The link healed itself before the debounce elapsed.
        d.noteConnectionState(disconnected: false);
        async.elapse(const Duration(seconds: 5));

        expect(confirmed, 0,
            reason: 'a recoverable blip must never tear the session down');
        expect(d.isPending, isFalse);
        expect(d.isConfirmed, isFalse);
      });
    });

    test('a command failure during the pending window confirms immediately',
        () {
      fakeAsync((async) {
        var confirmed = 0;
        final d = ConnectionDropDebouncer(
          onConfirmed: () => confirmed++,
          debounce: const Duration(seconds: 30),
        );

        d.noteConnectionState(disconnected: true);
        async.elapse(const Duration(milliseconds: 100));
        // Next command also failed — the link is demonstrably unusable.
        d.noteCommandFailure();

        expect(confirmed, 1,
            reason: 'a failed command short-circuits the rest of the debounce');
        expect(d.isConfirmed, isTrue);
      });
    });

    test('a lone command failure with no pending disconnect is a no-op', () {
      fakeAsync((async) {
        var confirmed = 0;
        final d = ConnectionDropDebouncer(onConfirmed: () => confirmed++);

        d.noteCommandFailure();
        async.elapse(const Duration(seconds: 5));

        expect(confirmed, 0,
            reason: 'a lone timeout on a connected link is the read-timeout\'s '
                'concern, not a drop');
      });
    });

    test('confirms only once even if the debounce + failure both fire', () {
      fakeAsync((async) {
        var confirmed = 0;
        final d = ConnectionDropDebouncer(
          onConfirmed: () => confirmed++,
          debounce: const Duration(milliseconds: 500),
        );

        d.noteConnectionState(disconnected: true);
        async.elapse(const Duration(seconds: 1)); // confirm via debounce
        d.noteCommandFailure(); // already confirmed — no double fire
        expect(confirmed, 1);
      });
    });

    test('reset clears state so the debouncer can be reused', () {
      fakeAsync((async) {
        var confirmed = 0;
        final d = ConnectionDropDebouncer(
          onConfirmed: () => confirmed++,
          debounce: const Duration(milliseconds: 500),
        );

        d.noteConnectionState(disconnected: true);
        async.elapse(const Duration(seconds: 1));
        expect(confirmed, 1);

        d.reset();
        expect(d.isConfirmed, isFalse);
        expect(d.isPending, isFalse);

        d.noteConnectionState(disconnected: true);
        async.elapse(const Duration(seconds: 1));
        expect(confirmed, 2, reason: 'a fresh drop fires again after reset');
      });
    });
  });

  group('transport surfaces a confirmed drop as Obd2DisconnectedException', () {
    test(
        'an Obd2DisconnectedException on the byte stream fails the in-flight '
        'sendCommand with the typed error', () async {
      final channel = _DropEmittingChannel();
      final transport = BluetoothObd2Transport(channel);
      await transport.connect();

      // Fire a command, then push the typed drop (as the channel does on
      // a confirmed connectionState disconnect) before any reply arrives.
      final pending = transport.sendCommand('010C\r');
      channel.emitDrop();

      await expectLater(pending, throwsA(isA<Obd2DisconnectedException>()),
          reason: 'a confirmed BLE drop surfaces to the poller as a typed '
              'disconnect, which TripDropDetector classifies in ~1–2 s');
    });
  });
}

/// Fake channel that, like [FlutterBluePlusElmChannel] on a confirmed
/// connectionState disconnect, can push an [Obd2DisconnectedException]
/// onto its byte stream instead of a reply.
class _DropEmittingChannel implements ElmByteChannel {
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  void emitDrop() => _controller.addError(const Obd2DisconnectedException());

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
    // No reply — the drop arrives via [emitDrop] instead.
  }
}
