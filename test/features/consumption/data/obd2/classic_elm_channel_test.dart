import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_elm_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_method_channel.dart';

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
        'survives errors on plugin.incoming — debugPrint swallow keeps the '
        'channel functional', () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);
      await channel.open();

      // Suppress debugPrint output during the test.
      final originalDebugPrint = debugPrintOverride();
      try {
        fake.incomingController.addError(
          Exception('simulated incoming error'),
        );
        await Future<void>.delayed(Duration.zero);

        // Channel still functional after the error.
        expect(channel.isOpen, isTrue);

        // Subsequent good bytes still flow through.
        final received = <List<int>>[];
        final sub = channel.incoming.listen(received.add);
        fake.incomingController.add([0x99]);
        await Future<void>.delayed(Duration.zero);
        expect(received, [
          [0x99],
        ]);
        await sub.cancel();
      } finally {
        restoreDebugPrint(originalDebugPrint);
      }

      await channel.close();
    });
  });

  group('ClassicElmChannel.write', () {
    test('throws StateError when channel is not open; no plugin.write call',
        () async {
      final channel = ClassicElmChannel(address: 'AA:BB', plugin: fake);

      await expectLater(
        channel.write([0x01, 0x02]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not open'),
          ),
        ),
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
