import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/classic_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('tankstellen.obd2/classic');
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
  });

  group('Obd2ClassicMethodChannel (#763)', () {
    test('bondedDevices parses the native list into typed DTOs',
        () async {
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        expect(call.method, 'bondedDevices');
        return [
          {'address': 'AA:BB:CC:DD:EE:01', 'name': 'vLinker FS 14884'},
          {'address': 'AA:BB:CC:DD:EE:02', 'name': 'Bose Mini SoundLink'},
        ];
      });

      const plugin = Obd2ClassicMethodChannel();
      final bonded = await plugin.bondedDevices();

      expect(bonded, hasLength(2));
      expect(bonded.first.address, 'AA:BB:CC:DD:EE:01');
      expect(bonded.first.name, 'vLinker FS 14884');
    });

    test('bondedDevices returns empty when native pushes back null',
        () async {
      messenger.setMockMethodCallHandler(methodChannel, (_) async => null);
      const plugin = Obd2ClassicMethodChannel();
      expect(await plugin.bondedDevices(), isEmpty);
    });

    test('bondedDevices drops entries with an empty address', () async {
      messenger.setMockMethodCallHandler(methodChannel, (_) async => [
            {'address': '', 'name': 'garbage entry'},
            {'address': 'AA:BB', 'name': 'ok'},
          ]);
      const plugin = Obd2ClassicMethodChannel();
      final bonded = await plugin.bondedDevices();
      expect(bonded, hasLength(1));
      expect(bonded.single.address, 'AA:BB');
    });

    test('connect forwards address + uuid + returns native bool',
        () async {
      MethodCall? captured;
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        captured = call;
        return true;
      });

      const plugin = Obd2ClassicMethodChannel();
      final ok = await plugin.connect(
        address: 'AA:BB',
        uuid: '00001101-0000-1000-8000-00805f9b34fb',
      );

      expect(ok, isTrue);
      expect(captured!.method, 'connect');
      expect(captured!.arguments, {
        'address': 'AA:BB',
        'uuid': '00001101-0000-1000-8000-00805f9b34fb',
      });
    });

    test('connect defaults to false when native returns null', () async {
      messenger.setMockMethodCallHandler(methodChannel, (_) async => null);
      const plugin = Obd2ClassicMethodChannel();
      expect(
        await plugin.connect(address: 'AA', uuid: 'UUID'),
        isFalse,
      );
    });

    test('write forwards bytes as a Uint8List', () async {
      Object? capturedBytes;
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        expect(call.method, 'write');
        capturedBytes = (call.arguments as Map)['bytes'];
        return null;
      });

      const plugin = Obd2ClassicMethodChannel();
      await plugin.write([0x41, 0x54, 0x5A, 0x0D]); // "ATZ\r"

      expect(capturedBytes, [0x41, 0x54, 0x5A, 0x0D]);
    });

    test('disconnect invokes the native disconnect method', () async {
      var called = false;
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        if (call.method == 'disconnect') called = true;
        return null;
      });

      const plugin = Obd2ClassicMethodChannel();
      await plugin.disconnect();

      expect(called, isTrue);
    });
  });
}
