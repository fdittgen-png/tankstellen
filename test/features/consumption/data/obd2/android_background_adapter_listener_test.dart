import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/android_background_adapter_listener.dart';
import 'package:tankstellen/features/consumption/data/obd2/background_adapter_listener.dart';

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
