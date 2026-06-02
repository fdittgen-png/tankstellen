// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_elm_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_method_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Captured call to [_FakeObd2ClassicMethodChannel.connect].
class _ConnectCall {
  final String address;
  final String uuid;
  const _ConnectCall(this.address, this.uuid);
}

/// In-memory double for [Obd2ClassicMethodChannel]. Records calls and lets
/// each test override return values / inject errors per-method.
class _FakeObd2ClassicMethodChannel extends Obd2ClassicMethodChannel {
  _FakeObd2ClassicMethodChannel();

  // --- connect -----------------------------------------------------------
  bool connectResult = true;
  final List<_ConnectCall> connectCalls = [];

  @override
  Future<bool> connect({required String address, required String uuid}) async {
    connectCalls.add(_ConnectCall(address, uuid));
    return connectResult;
  }

  // --- write -------------------------------------------------------------
  final List<List<int>> writeCalls = [];
  Object? writeError;

  @override
  Future<void> write(List<int> bytes) async {
    writeCalls.add(List<int>.from(bytes));
    if (writeError != null) {
      throw writeError!;
    }
  }

  // --- disconnect --------------------------------------------------------
  int disconnectCallCount = 0;
  Object? disconnectError;

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
    if (disconnectError != null) {
      throw disconnectError!;
    }
  }

  // --- incoming ----------------------------------------------------------
  final StreamController<List<int>> incomingController =
      StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> get incoming => incomingController.stream;

  Future<void> dispose() async {
    if (!incomingController.isClosed) {
      await incomingController.close();
    }
  }
}

void main() {
  silenceErrorLoggerSpool();
  late _FakeObd2ClassicMethodChannel fake;

  setUp(() {
    fake = _FakeObd2ClassicMethodChannel();
  });

  tearDown(() async {
    await fake.dispose();
  });

  group('ClassicElmChannel.open', () {
    test('forwards address + sppUuid to plugin.connect and flips isOpen',
        () async {
      final channel = ClassicElmChannel(
        address: 'AA:BB:CC:DD:EE:01',
        plugin: fake,
      );

      expect(channel.isOpen, isFalse);
      await channel.open();

      expect(channel.isOpen, isTrue);
      expect(fake.connectCalls, hasLength(1));
      expect(fake.connectCalls.single.address, 'AA:BB:CC:DD:EE:01');
      expect(fake.connectCalls.single.uuid, sppServiceUuid);

      await channel.close();
    });

    test('honours a custom sppUuid', () async {
      const customUuid = '00001101-0000-1000-8000-deadbeef0001';
      final channel = ClassicElmChannel(
        address: 'AA:BB',
        plugin: fake,
        sppUuid: customUuid,
      );

      await channel.open();
      expect(fake.connectCalls.single.uuid, customUuid);

      await channel.close();
    });

    test('is idempotent — second call is a no-op (no second connect)',
        () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);

      await channel.open();
      await channel.open();

      expect(fake.connectCalls, hasLength(1));
      expect(channel.isOpen, isTrue);

      await channel.close();
    });

    test(
        'throws StateError when plugin.connect returns false; isOpen stays '
        'false and no subscription is installed', () async {
      fake.connectResult = false;
      final channel = ClassicElmChannel(
        address: 'AA:BB:CC:DD:EE:99',
        plugin: fake,
      );

      await expectLater(
        channel.open(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('failed to open'),
              contains('AA:BB:CC:DD:EE:99'),
            ),
          ),
        ),
      );
      expect(channel.isOpen, isFalse);

      // No subscription was installed: bytes pushed by the plugin must
      // NOT reach the channel's incoming stream.
      final received = <List<int>>[];
      final sub = channel.incoming.listen(received.add);
      fake.incomingController.add([0x42]);
      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);

      await sub.cancel();
      await channel.close();
    });

    test('forwards bytes from plugin.incoming to channel.incoming once open',
        () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      final received = <List<int>>[];
      final sub = channel.incoming.listen(received.add);

      fake.incomingController.add([0x41, 0x54, 0x5A]);
      fake.incomingController.add([0x0D]);
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        [0x41, 0x54, 0x5A],
        [0x0D],
      ]);

      await sub.cancel();
      await channel.close();
    });

    test(
        '#2295 — forwards plugin.incoming errors onto channel.incoming so the '
        'transport fails the pending command immediately, and stays functional',
        () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      final received = <List<int>>[];
      final errors = <Object>[];
      final sub = channel.incoming.listen(
        received.add,
        onError: errors.add,
      );

      final boom = Exception('simulated incoming error');
      fake.incomingController.addError(boom);
      await Future<void>.delayed(Duration.zero);

      // #2295 — the error is forwarded, not swallowed: a downstream
      // consumer (the transport) sees it and can fail-fast instead of
      // waiting out the 5 s read timeout.
      expect(errors, hasLength(1));
      expect(errors.single, same(boom));

      // #2671 — a reader-stream error now also clears `_open` (a classic-SPP
      // drop raises an ERROR, not stream `done`), so the next write
      // short-circuits instead of dispatching into a dead socket.
      expect(channel.isOpen, isFalse);
      // The broadcast controller is NOT closed by a forwarded error, so any
      // late good bytes the native side already queued still flow through.
      fake.incomingController.add([0x99]);
      await Future<void>.delayed(Duration.zero);
      expect(received, [
        [0x99],
      ]);

      await sub.cancel();
      await channel.close();
    });
  });

  group('ClassicElmChannel.write', () {
    test(
        'throws the recoverable Obd2DisconnectedException when not open; '
        'no plugin.write call (#2671)', () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);

      await expectLater(
        channel.write([0x01, 0x02]),
        throwsA(isA<Obd2DisconnectedException>()),
      );
      expect(fake.writeCalls, isEmpty);
    });

    test('forwards bytes to plugin.write when open', () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      await channel.write([0x41, 0x54, 0x5A, 0x0D]);

      expect(fake.writeCalls, hasLength(1));
      expect(fake.writeCalls.single, [0x41, 0x54, 0x5A, 0x0D]);

      await channel.close();
    });
  });

  // #2671 — a Classic-SPP drop raises a socket ERROR on the reader stream
  // (not stream done). The `onError` handler must clear `_open` so the next
  // write short-circuits, and a `plugin.write` that throws the raw
  // `PlatformException(state, not connected)` must surface as the
  // recoverable `Obd2DisconnectedException` the drop detector routes through
  // pause/reconnect — never the raw platform error logged as an ERROR trace.
  group('ClassicElmChannel — disconnect on reader-stream error (#2671)', () {
    test(
        'a reader-stream error flips isOpen=false so the next write '
        'short-circuits as Obd2DisconnectedException (no plugin.write call)',
        () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();
      expect(channel.isOpen, isTrue);

      // Swallow the forwarded error on the incoming stream so it doesn't
      // surface as an unhandled zone error during the test.
      final sub = channel.incoming.listen((_) {}, onError: (_) {});

      // The native classic-SPP socket drop raises an ERROR on the reader
      // stream, not stream `done`.
      fake.incomingController.addError(
        PlatformException(code: 'state', message: 'not connected'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(channel.isOpen, isFalse,
          reason: 'onError must clear _open just like onDone does');

      // The next write must short-circuit on the guard as a recoverable
      // typed disconnect — NOT a raw StateError, and NOT reaching the plugin.
      await expectLater(
        channel.write([0x01, 0x02]),
        throwsA(isA<Obd2DisconnectedException>()),
      );
      expect(fake.writeCalls, isEmpty,
          reason: 'a closed channel must not reach plugin.write');

      await sub.cancel();
      await channel.close();
    });

    test(
        'a plugin.write that throws PlatformException(not connected) is '
        'rethrown as the recoverable Obd2DisconnectedException', () async {
      // Models the in-flight-write race: the drop lands DURING the native
      // write, so the guard passed but the plugin write throws raw.
      fake.writeError =
          PlatformException(code: 'state', message: 'not connected');
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      await expectLater(
        channel.write([0x41, 0x54, 0x5A, 0x0D]),
        throwsA(isA<Obd2DisconnectedException>()),
        reason: 'the raw PlatformException must be reclassified as a '
            'recoverable typed disconnect (matching the #2524 precedent)',
      );

      await channel.close();
    });
  });

  group('ClassicElmChannel.close', () {
    test(
        'flips isOpen, calls plugin.disconnect once and closes the incoming '
        'stream', () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      var doneFired = false;
      final sub = channel.incoming.listen(
        (_) {},
        onDone: () => doneFired = true,
      );

      await channel.close();

      expect(channel.isOpen, isFalse);
      expect(fake.disconnectCallCount, 1);

      // Give the broadcast controller a tick to deliver onDone.
      await Future<void>.delayed(Duration.zero);
      expect(doneFired, isTrue);

      await sub.cancel();
    });

    test('swallows errors thrown by plugin.disconnect', () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();
      fake.disconnectError = Exception('boom on disconnect');

      final originalDebugPrint = debugPrintOverride();
      try {
        await expectLater(channel.close(), completes);
      } finally {
        restoreDebugPrint(originalDebugPrint);
      }

      expect(channel.isOpen, isFalse);
      expect(fake.disconnectCallCount, 1);
    });

    test('is idempotent — second close is a no-op and does not throw',
        () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      await channel.close();
      await expectLater(channel.close(), completes);

      // disconnect on the plugin is invoked unconditionally inside the
      // try-block, so a second close calls it again — but the SUT must
      // not throw, which is the behaviour under test here. The call
      // count assertion is a documentation of current behaviour.
      expect(fake.disconnectCallCount, greaterThanOrEqualTo(1));
      expect(channel.isOpen, isFalse);
    });

    test('close before open does not throw', () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);

      await expectLater(channel.close(), completes);
      expect(channel.isOpen, isFalse);
    });
  });
}

// --- debugPrint override helpers ---------------------------------------
//
// `debugPrint` writes to stdout by default; tests that intentionally
// trigger error paths swap it out for a no-op so the test log stays
// readable. We keep this tiny shim local to this file rather than
// reaching for a fixture.

DebugPrintCallback debugPrintOverride() {
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {};
  return original;
}

void restoreDebugPrint(DebugPrintCallback original) {
  debugPrint = original;
}
