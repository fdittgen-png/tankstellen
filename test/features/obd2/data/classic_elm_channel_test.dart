// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/classic_elm_channel.dart';
import 'package:tankstellen/features/obd2/data/classic_method_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import '../../../helpers/silence_error_logger.dart';

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

  // #2969 — ClassicElmChannel.open now calls connectDetailed; override it so
  // the fake's connectResult still drives the SUT + records the call.
  @override
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
  }) async {
    connectCalls.add(_ConnectCall(address, uuid));
    return (
      ok: connectResult,
      strategy: connectResult ? 'secure' : 'exhausted',
      error: connectResult ? null : 'rfcomm open failed',
    );
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

/// #2953 — a fake whose `incoming` stream hands back a [_LateByteSink] so a
/// test can deliver a native Classic-SPP byte DIRECTLY to the SUT's
/// installed `onData` listener even after `close()` ran — modelling the
/// EventChannel in-flight-byte race where a chunk already queued on the
/// event loop reaches the listener after `_incoming` was closed. A real
/// broadcast `StreamController` would stop delivering once the SUT's
/// subscription is cancelled in `close()`, so it can't reproduce the race.
class _LateByteFakePlugin extends Obd2ClassicMethodChannel {
  _LateByteFakePlugin();

  final sink = _LateByteSink();

  // #2969 — ClassicElmChannel.open now calls connectDetailed.
  @override
  Future<ClassicConnectResult> connectDetailed({
    required String address,
    required String uuid,
  }) async =>
      (ok: true, strategy: 'secure', error: null);

  @override
  Future<void> write(List<int> bytes) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<List<int>> get incoming => sink;
}

/// A minimal [Stream] whose subscription captures the SUT's `onData` and
/// whose `cancel()` is a no-op for delivery — the test fires a late byte
/// through [deliver] regardless of cancellation, reproducing a native
/// in-flight chunk arriving after the channel closed (#2953).
class _LateByteSink extends Stream<List<int>> {
  void Function(List<int>)? _onData;

  void deliver(List<int> bytes) => _onData?.call(bytes);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onData = onData;
    return _NoopSubscription<List<int>>();
  }
}

class _NoopSubscription<T> implements StreamSubscription<T> {
  @override
  Future<void> cancel() async {}
  @override
  void onData(void Function(T)? handleData) {}
  @override
  void onError(Function? handleError) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void pause([Future<void>? resumeSignal]) {}
  @override
  void resume() {}
  @override
  bool get isPaused => false;
  @override
  Future<E> asFuture<E>([E? futureValue]) => Completer<E>().future;
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
        'throws the typed Obd2AdapterUnresponsive when plugin.connect returns '
        'false; isOpen stays false and no subscription is installed (#2745)',
        () async {
      // #2745 — was a raw StateError (field trace #6, ERROR-logged as
      // `[unknown]`). Now a typed, expected, user-surfaced connect condition.
      fake.connectResult = false;
      final channel = ClassicElmChannel(
        address: 'AA:BB:CC:DD:EE:99',
        plugin: fake,
      );

      await expectLater(
        channel.open(),
        throwsA(isA<Obd2AdapterUnresponsive>()),
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

    test(
        '#3183 — a write-time drop ALSO fires the proactive link-drop signal '
        'so the trip-independent reconnect controller is kicked', () async {
      // The lazy write-failure path was the ONLY drop discovery that never
      // called _signalDrop(): a drop noticed on write (no reader error /
      // done edge yet) left the reconnect controller asleep.
      fake.writeError =
          PlatformException(code: 'state', message: 'not connected');
      final channel = ClassicElmChannel(address: 'AA:BB:CC:DD:EE:83',
          plugin: fake);
      await channel.open();

      final drops = <Obd2LinkDropEvent>[];
      final dropSub = Obd2LinkDropSignal.instance.drops.listen(drops.add);
      addTearDown(dropSub.cancel);

      await expectLater(
        channel.write([0x41, 0x54]),
        throwsA(isA<Obd2DisconnectedException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(drops, hasLength(1),
          reason: 'the write-failure drop path must emit the #3019 proactive '
              'signal exactly like the reader onError/onDone paths');
      expect(drops.single.transportKind, 'classic');
      expect(drops.single.mac, 'AA:BB:CC:DD:EE:83');

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

    test(
        '#2953 — a late native byte delivered AFTER close does NOT throw '
        '(the incoming `add` is isClosed-guarded)', () async {
      // Field log #30 spooled `Bad state: Cannot add new events after calling
      // close` 14× during the engine-off connect/disconnect churn: a native
      // Classic-SPP chunk already queued on the event loop reached the
      // listener after `close()` closed `_incoming`. The guard must drop it.
      final latePlugin = _LateByteFakePlugin();
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: latePlugin);
      await channel.open();

      // Sanity: an in-session byte flows through while open.
      final received = <List<int>>[];
      final sub = channel.incoming.listen(received.add);
      latePlugin.sink.deliver([0x41]);
      await Future<void>.delayed(Duration.zero);
      expect(received, [
        [0x41],
      ]);

      await channel.close();

      // The in-flight late byte arrives at the listener AFTER `_incoming`
      // was closed — must be a silent no-op, not a StateError.
      expect(
        () => latePlugin.sink.deliver([0x99]),
        returnsNormally,
        reason: 'a post-close native byte must be dropped silently, not '
            'rethrown as `Cannot add new events after calling close`',
      );

      await sub.cancel();
    });
  });

  group('isBenignClassicLinkDrop (#3379)', () {
    test('the field RFCOMM-drop signature is benign (breadcrumb, not ERROR)',
        () {
      // The exact field-log shape: PlatformException(io, bt socket closed,
      // read return: -1, null, null) — the normal end-of-session drop.
      expect(
        isBenignClassicLinkDrop(
          'PlatformException(io, bt socket closed, read return: -1, null, null)',
        ),
        isTrue,
      );
    });

    test('the older "read ret: -1" + "not connected" shapes are benign', () {
      expect(isBenignClassicLinkDrop('read failed, socket might closed or '
          'timeout, read ret: -1'), isTrue);
      expect(
        isBenignClassicLinkDrop(
            'PlatformException(state, not connected, null, null)'),
        isTrue,
      );
    });

    test('an UNEXPECTED socket error is NOT benign (keeps the ERROR trace)',
        () {
      expect(isBenignClassicLinkDrop('GATT_ERROR 133'), isFalse);
      expect(isBenignClassicLinkDrop('some unrelated failure'), isFalse);
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
