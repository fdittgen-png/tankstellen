import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/background_adapter_listener.dart';
import 'package:tankstellen/features/consumption/data/obd2/fake_background_adapter_listener.dart';

void main() {
  group('UnimplementedBackgroundAdapterListener (#1004 phase 2a)', () {
    // The production stub must throw on every method so a Riverpod
    // wiring that accidentally points at this class before phase 2b
    // ships fails loudly instead of silently swallowing every BLE
    // event.

    test('events getter throws UnimplementedError', () {
      const listener = UnimplementedBackgroundAdapterListener();
      expect(() => listener.events, throwsUnimplementedError);
    });

    test('start throws UnimplementedError', () async {
      const listener = UnimplementedBackgroundAdapterListener();
      expect(
        () => listener.start(mac: 'AA:BB:CC:DD:EE:FF'),
        throwsUnimplementedError,
      );
    });

    test('stop throws UnimplementedError', () async {
      const listener = UnimplementedBackgroundAdapterListener();
      expect(() => listener.stop(), throwsUnimplementedError);
    });

    test('error message names the issue and the gate', () {
      const listener = UnimplementedBackgroundAdapterListener();
      // The gate hint is the load-bearing part: it tells the next
      // developer where to look (`autoRecord` flag) before they think
      // they need to implement the bridge. Inspect the thrown error
      // via `throwsA(predicate)` rather than a try/catch on the Error
      // subclass (which the analyzer flags as `avoid_catching_errors`).
      expect(
        () => listener.events,
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('#1004 phase 2'),
              contains('autoRecord'),
            ),
          ),
        ),
      );
    });
  });

  group('FakeBackgroundAdapterListener', () {
    late FakeBackgroundAdapterListener fake;

    setUp(() {
      fake = FakeBackgroundAdapterListener();
    });

    tearDown(() async {
      await fake.dispose();
    });

    test('start records every call and the requested MAC', () async {
      await fake.start(mac: 'AA:BB:CC:DD:EE:FF');
      await fake.start(mac: '11:22:33:44:55:66');
      expect(fake.startCalls, 2);
      expect(fake.startedMacs,
          ['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66']);
    });

    test('stop records every call', () async {
      await fake.stop();
      await fake.stop();
      expect(fake.stopCalls, 2);
    });

    test('emitConnected pushes an AdapterConnected event with the MAC',
        () async {
      const mac = 'AA:BB:CC:DD:EE:FF';
      final received = <BackgroundAdapterEvent>[];
      final sub = fake.events.listen(received.add);

      fake.emitConnected(mac);
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      final evt = received.single;
      expect(evt, isA<AdapterConnected>());
      expect(evt.mac, mac);

      await sub.cancel();
    });

    test('emitDisconnected pushes an AdapterDisconnected event', () async {
      const mac = 'AA:BB:CC:DD:EE:FF';
      final received = <BackgroundAdapterEvent>[];
      final sub = fake.events.listen(received.add);

      fake.emitDisconnected(mac);
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single, isA<AdapterDisconnected>());
      expect(received.single.mac, mac);

      await sub.cancel();
    });

    test('events stream is broadcast — multiple listeners both observe',
        () async {
      const mac = 'AA:BB:CC:DD:EE:FF';
      final a = <BackgroundAdapterEvent>[];
      final b = <BackgroundAdapterEvent>[];
      final subA = fake.events.listen(a.add);
      final subB = fake.events.listen(b.add);

      fake.emitConnected(mac);
      await Future<void>.delayed(Duration.zero);

      expect(a, hasLength(1));
      expect(b, hasLength(1));

      await subA.cancel();
      await subB.cancel();
    });

    test('explicit `at` timestamp survives through the event', () async {
      const mac = 'AA:BB:CC:DD:EE:FF';
      final ts = DateTime(2026, 4, 26, 12, 0, 0);
      final received = <BackgroundAdapterEvent>[];
      final sub = fake.events.listen(received.add);

      fake.emitConnected(mac, at: ts);
      await Future<void>.delayed(Duration.zero);

      expect(received.single.at, ts);
      await sub.cancel();
    });
  });
}
