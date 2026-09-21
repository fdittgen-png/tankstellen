// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/transport/android_background_adapter_listener.dart';
import 'package:tankstellen/features/obd2/data/transport/background_adapter_listener.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Per-test channel names so the binary messenger handlers from one
  // test cannot leak into another. Real production code uses the
  // strings hard-coded in [AndroidBackgroundAdapterListener]; the
  // bridge file already pins those, so testing an isolated channel
  // name is fine here.
  const methodChannel =
      MethodChannel('test/tankstellen/auto_record/methods');
  const eventChannel =
      EventChannel('test/tankstellen/auto_record/events');

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late AndroidBackgroundAdapterListener listener;

  setUp(() {
    listener = AndroidBackgroundAdapterListener.withChannels(
      methodChannel: methodChannel,
      eventChannel: eventChannel,
    );
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(methodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, null);
    await listener.dispose();
  });

  group('AndroidBackgroundAdapterListener (#1004 phase 2b-1)', () {
    test('start invokes the platform `start` method with the mac arg',
        () async {
      final List<MethodCall> calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call);
        return true;
      });
      // Empty event stream — start subscribes during invocation, so we
      // need a stream handler installed even if no events flow.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(onListen: (_, _) {}),
      );

      await listener.start(mac: 'AA:BB:CC:DD:EE:01');

      expect(calls, hasLength(1));
      expect(calls.single.method, 'start');
      expect(calls.single.arguments, {'mac': 'AA:BB:CC:DD:EE:01'});
    });

    test(
        '#3246 — a native arm FAILURE (FGS not registered in a shipped build) '
        'degrades silently: start() does NOT throw', () async {
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        // The native side now reports the honest failure instead of a phantom
        // success when the <service> is gated out of the manifest (#3173).
        throw PlatformException(
            code: 'unavailable', message: 'foreground service not registered');
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(onListen: (_, _) {}),
      );

      // Must not crash the auto-record coordinator — recording falls back to
      // the GPS-only / foreground path.
      await expectLater(
          listener.start(mac: 'AA:BB:CC:DD:EE:01'), completes);
    });

    test('events from the EventChannel are translated to typed events',
        () async {
      messenger.setMockMethodCallHandler(
        methodChannel,
        (call) async => true,
      );

      late MockStreamHandlerEventSink sink;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            sink = events;
          },
        ),
      );

      final received = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(received.add);

      await listener.start(mac: 'AA:BB:CC:DD:EE:01');

      // The platform handler captures the EventSink synchronously on
      // first listen. Push two events through it.
      sink.success(<String, Object?>{
        'type': 'connect',
        'mac': 'AA:BB:CC:DD:EE:01',
        'atMillis': 1700000000000,
      });
      sink.success(<String, Object?>{
        'type': 'disconnect',
        'mac': 'AA:BB:CC:DD:EE:01',
        'atMillis': 1700000060000,
      });

      // Pump a microtask so the broadcast stream delivers.
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect(received[0], isA<AdapterConnected>());
      expect(received[0].mac, 'AA:BB:CC:DD:EE:01');
      expect(
        received[0].at.millisecondsSinceEpoch,
        1700000000000,
      );
      expect(received[1], isA<AdapterDisconnected>());
      expect(
        received[1].at.millisecondsSinceEpoch,
        1700000060000,
      );

      await sub.cancel();
    });

    test('#3699 aclConnected events feed the STATIC engine-start hint '
        'stream and never reach the sealed adapter-event stream', () async {
      messenger.setMockMethodCallHandler(
        methodChannel,
        (call) async => true,
      );

      late MockStreamHandlerEventSink sink;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            sink = events;
          },
        ),
      );

      final adapterEvents = <BackgroundAdapterEvent>[];
      final hints = <DateTime>[];
      final sub = listener.events.listen(adapterEvents.add);
      final hintSub =
          AndroidBackgroundAdapterListener.engineStartHints.listen(hints.add);

      await listener.start(mac: 'AA:BB:CC:DD:EE:01');

      sink.success(<String, Object?>{
        'type': 'aclConnected',
        'mac': '11:22:33:44:55:66', // the CAR AUDIO mac, not the adapter
        'atMillis': 1700000000000,
      });
      await Future<void>.delayed(Duration.zero);

      expect(adapterEvents, isEmpty,
          reason: 'a process-wide hint must not impersonate an adapter '
              'transition (the coordinator filters by MAC and would '
              'misread it)');
      expect(hints, hasLength(1));
      expect(hints.single.millisecondsSinceEpoch, 1700000000000);

      await sub.cancel();
      await hintSub.cancel();
    });

    test('malformed events are dropped (no crash, no sealed-event emission)',
        () async {
      messenger.setMockMethodCallHandler(
        methodChannel,
        (call) async => true,
      );

      late MockStreamHandlerEventSink sink;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            sink = events;
          },
        ),
      );

      final received = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(received.add);

      await listener.start(mac: 'AA:BB:CC:DD:EE:01');

      // 1. Non-Map payload.
      sink.success('garbage');
      // 2. Map missing the `mac` field.
      sink.success(<String, Object?>{
        'type': 'connect',
        'atMillis': 1700000000000,
      });
      // 3. Map with an unknown `type`.
      sink.success(<String, Object?>{
        'type': 'unknown',
        'mac': 'AA:BB:CC:DD:EE:01',
        'atMillis': 1700000000000,
      });
      // 4. Map with a non-numeric atMillis.
      sink.success(<String, Object?>{
        'type': 'connect',
        'mac': 'AA:BB:CC:DD:EE:01',
        'atMillis': 'not a number',
      });
      // 5. A valid event AFTER the malformed ones — proves the stream
      //    was not closed by the bad payloads.
      sink.success(<String, Object?>{
        'type': 'connect',
        'mac': 'AA:BB:CC:DD:EE:01',
        'atMillis': 1700000000000,
      });

      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single, isA<AdapterConnected>());

      await sub.cancel();
    });

    test('stop invokes the platform `stop` method', () async {
      final List<MethodCall> calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call);
        return true;
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(onListen: (_, _) {}),
      );

      await listener.start(mac: 'AA:BB:CC:DD:EE:01');
      await listener.stop();

      expect(
        calls.map((c) => c.method),
        containsAllInOrder(<String>['start', 'stop']),
      );
    });

    group('#4355 promotion acknowledgement contract', () {
      // The native `start` reply is parked until the service posts its
      // promotion ack, so a `true` here now MEANS the OS promoted the
      // service. Everything else is a typed degrade — never `promoted`.

      void emptyEventStream() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(onListen: (_, _) {}),
        );
      }

      test('an acknowledged arm reports promoted', () async {
        messenger.setMockMethodCallHandler(methodChannel, (call) async => true);
        emptyEventStream();

        final outcome = await listener.arm(mac: 'AA:BB:CC:DD:EE:01');

        expect(outcome, ForegroundPromotionOutcome.promoted);
        expect(listener.lastPromotion, ForegroundPromotionOutcome.promoted);
      });

      test('a native promotionRefused carries the accurate reason through',
          () async {
        final reasons = <String, ForegroundPromotionOutcome>{
          'notAllowedInBackground':
              ForegroundPromotionOutcome.notAllowedInBackground,
          'permissionDenied': ForegroundPromotionOutcome.permissionDenied,
          'gattUnavailable': ForegroundPromotionOutcome.gattUnavailable,
          'illegalState': ForegroundPromotionOutcome.refused,
        };
        emptyEventStream();
        for (final entry in reasons.entries) {
          messenger.setMockMethodCallHandler(methodChannel, (call) async {
            throw PlatformException(
                code: 'promotionRefused', message: entry.key);
          });
          expect(await listener.arm(mac: 'AA:BB:CC:DD:EE:01'), entry.value,
              reason: entry.key);
        }
      });

      test('a native promotionTimeout is a typed failure, never promoted',
          () async {
        messenger.setMockMethodCallHandler(methodChannel, (call) async {
          throw PlatformException(
              code: 'promotionTimeout',
              message: 'foreground promotion was not acknowledged');
        });
        emptyEventStream();

        expect(await listener.arm(mac: 'AA:BB:CC:DD:EE:01'),
            ForegroundPromotionOutcome.timedOut);
      });

      test('#3246 an unregistered <service> is still reported as unavailable',
          () async {
        messenger.setMockMethodCallHandler(methodChannel, (call) async {
          throw PlatformException(
              code: 'unavailable', message: 'foreground service not registered');
        });
        emptyEventStream();

        expect(await listener.arm(mac: 'AA:BB:CC:DD:EE:01'),
            ForegroundPromotionOutcome.unavailable);
      });

      test('a platform that never answers resolves to timedOut, not promoted',
          () async {
        final bounded = AndroidBackgroundAdapterListener.withChannels(
          methodChannel: methodChannel,
          eventChannel: eventChannel,
          promotionAckTimeout: const Duration(milliseconds: 40),
        );
        addTearDown(bounded.dispose);
        messenger.setMockMethodCallHandler(methodChannel, (call) async {
          // A wedged platform thread: the reply never comes.
          return Completer<bool>().future;
        });
        emptyEventStream();

        expect(await bounded.arm(mac: 'AA:BB:CC:DD:EE:01'),
            ForegroundPromotionOutcome.timedOut);
      });

      test('a non-true reply is never upgraded to promoted', () async {
        messenger.setMockMethodCallHandler(methodChannel, (call) async => null);
        emptyEventStream();

        expect(await listener.arm(mac: 'AA:BB:CC:DD:EE:01'),
            ForegroundPromotionOutcome.refused);
      });

      test('start() never throws on any refusal path', () async {
        messenger.setMockMethodCallHandler(methodChannel, (call) async {
          throw PlatformException(code: 'permission', message: 'denied');
        });
        emptyEventStream();

        await expectLater(listener.start(mac: 'AA:BB:CC:DD:EE:01'), completes);
        expect(
            listener.lastPromotion, ForegroundPromotionOutcome.permissionDenied);
      });

      test(
          'fgsPromoted / fgsStartFailed reach the STATIC promotion stream and '
          'never the sealed adapter-event stream', () async {
        messenger.setMockMethodCallHandler(methodChannel, (call) async => true);
        late MockStreamHandlerEventSink sink;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(onListen: (_, events) => sink = events),
        );

        final adapterEvents = <BackgroundAdapterEvent>[];
        final promotions = <ForegroundPromotionEvent>[];
        final sub = listener.events.listen(adapterEvents.add);
        final promoSub = AndroidBackgroundAdapterListener.promotionEvents
            .listen(promotions.add);

        await listener.arm(mac: 'AA:BB:CC:DD:EE:01');

        // Note: these payloads carry NO mac — a promotion is a process-wide
        // platform fact, so the parser must route them before the mac check.
        sink.success(<String, Object?>{
          'type': 'fgsPromoted',
          'generation': 7,
          'atMillis': 1700000000000,
        });
        sink.success(<String, Object?>{
          'type': 'fgsStartFailed',
          'reason': 'notAllowedInBackground',
          'atMillis': 1700000001000,
        });
        await Future<void>.delayed(Duration.zero);

        expect(adapterEvents, isEmpty);
        expect(promotions, hasLength(2));
        expect(promotions[0].outcome, ForegroundPromotionOutcome.promoted);
        expect(promotions[0].generation, 7);
        expect(promotions[0].at.millisecondsSinceEpoch, 1700000000000);
        expect(promotions[1].outcome,
            ForegroundPromotionOutcome.notAllowedInBackground);
        expect(promotions[1].generation, isNull);

        await sub.cancel();
        await promoSub.cancel();
      });
    });

    test('atMillis can be a num that rounds down to int', () async {
      messenger.setMockMethodCallHandler(
        methodChannel,
        (call) async => true,
      );

      late MockStreamHandlerEventSink sink;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            sink = events;
          },
        ),
      );

      final received = <BackgroundAdapterEvent>[];
      final sub = listener.events.listen(received.add);

      await listener.start(mac: 'AA:BB:CC:DD:EE:01');

      sink.success(<String, Object?>{
        'type': 'disconnect',
        'mac': 'AA:BB:CC:DD:EE:01',
        // Some channels round-trip ints as doubles in JSON.
        'atMillis': 1700000060000.0,
      });

      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single, isA<AdapterDisconnected>());
      expect(
        received.single.at.millisecondsSinceEpoch,
        1700000060000,
      );

      await sub.cancel();
    });
  });
}
