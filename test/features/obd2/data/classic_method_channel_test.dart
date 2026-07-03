// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/classic_method_channel.dart';
import 'package:tankstellen/features/obd2/data/obd2_platform_budgets.dart';

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
        // #3421 — the whole-ladder budget rides along by default.
        'budgetMs': Obd2PlatformBudgets.classicConnectLadderBudgetMs,
      });
    });

    // #3421 — the whole-ladder budget must reach the native side as
    // `budgetMs` so the Kotlin ladder can skip remaining rungs when spent.
    test('#3421 — connectDetailed forwards an explicit budgetMs', () async {
      MethodCall? captured;
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        captured = call;
        return {'ok': true, 'strategy': 'secure', 'error': null};
      });

      const plugin = Obd2ClassicMethodChannel();
      final r = await plugin.connectDetailed(
        address: 'AA:BB',
        uuid: 'UUID',
        budgetMs: 12345,
      );

      expect(r.ok, isTrue);
      expect((captured!.arguments as Map)['budgetMs'], 12345);
    });

    test(
        '#3421 — connectDetailed defaults budgetMs to the audited '
        'whole-ladder constant', () async {
      MethodCall? captured;
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        captured = call;
        return true;
      });

      const plugin = Obd2ClassicMethodChannel();
      await plugin.connectDetailed(address: 'AA:BB', uuid: 'UUID');

      expect(
        (captured!.arguments as Map)['budgetMs'],
        Obd2PlatformBudgets.classicConnectLadderBudgetMs,
      );
    });

    test('connect defaults to false when native returns null', () async {
      messenger.setMockMethodCallHandler(methodChannel, (_) async => null);
      const plugin = Obd2ClassicMethodChannel();
      expect(
        await plugin.connect(address: 'AA', uuid: 'UUID'),
        isFalse,
      );
    });

    // #2969 — bidirectional back-compat: the binding accepts BOTH the new Map
    // return shape {ok, strategy, error} AND the legacy bare bool.
    test('connectDetailed parses the new Map shape {ok, strategy, error}',
        () async {
      messenger.setMockMethodCallHandler(methodChannel, (_) async => {
            'ok': false,
            'strategy': 'exhausted',
            'error': 'read failed, socket might closed',
          });
      const plugin = Obd2ClassicMethodChannel();
      final r = await plugin.connectDetailed(address: 'AA', uuid: 'UUID');
      expect(r.ok, isFalse);
      expect(r.strategy, 'exhausted');
      expect(r.error, contains('socket'));
      // connect() still returns the bool from the same Map.
    });

    test('connectDetailed accepts the legacy bare bool (back-compat)',
        () async {
      messenger.setMockMethodCallHandler(methodChannel, (_) async => true);
      const plugin = Obd2ClassicMethodChannel();
      final r = await plugin.connectDetailed(address: 'AA', uuid: 'UUID');
      expect(r.ok, isTrue);
      expect(r.strategy, isNull);
      expect(r.error, isNull);
    });

    test('parseClassicConnectResult handles both shapes + null', () {
      expect(parseClassicConnectResult(true).ok, isTrue);
      expect(parseClassicConnectResult(false).ok, isFalse);
      final m = parseClassicConnectResult(
          {'ok': true, 'strategy': 'insecure', 'error': null});
      expect(m.ok, isTrue);
      expect(m.strategy, 'insecure');
      // A loosely-typed Map<dynamic,dynamic> (the codec shape) parses too.
      final loose = parseClassicConnectResult(
          <dynamic, dynamic>{'ok': false, 'strategy': 'bad-address'});
      expect(loose.ok, isFalse);
      expect(loose.strategy, 'bad-address');
      // null / unexpected → clean failure.
      expect(parseClassicConnectResult(null).ok, isFalse);
      expect(parseClassicConnectResult(42).ok, isFalse);
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

    test('#3183 — sdkInt returns the native Build.VERSION.SDK_INT', () async {
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        expect(call.method, 'sdkInt');
        return 30;
      });

      const plugin = Obd2ClassicMethodChannel();
      expect(await plugin.sdkInt(), 30);
    });

    test('#3183 — sdkInt throws on a null native reply (caller falls back)',
        () async {
      messenger.setMockMethodCallHandler(methodChannel, (_) async => null);
      const plugin = Obd2ClassicMethodChannel();
      await expectLater(plugin.sdkInt(), throwsStateError);
    });

    test(
        '#3183 — sdkInt throws when the native side predates the method '
        '(MissingPluginException — the permission flow falls back to 33)',
        () async {
      messenger.setMockMethodCallHandler(methodChannel, null);
      const plugin = Obd2ClassicMethodChannel();
      await expectLater(
        plugin.sdkInt(),
        throwsA(isA<MissingPluginException>()),
      );
    });
  });
}
