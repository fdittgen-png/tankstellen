// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_recovery_natives.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const classicChannel = MethodChannel('tankstellen.obd2/classic');
  const recoveryChannel = MethodChannel('tankstellen.obd2/recovery');

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(classicChannel, null);
    messenger.setMockMethodCallHandler(recoveryChannel, null);
  });

  group('ChannelObd2WedgeRecoveryNatives (#3422)', () {
    test('routes the device hooks over the classic channel with the mac',
        () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(classicChannel, (call) async {
        calls.add(call);
        return true;
      });
      const natives = ChannelObd2WedgeRecoveryNatives();

      expect(await natives.fetchUuidsWithSdp('AA:BB'), isTrue);
      expect(await natives.removeBond('AA:BB'), isTrue);
      expect(await natives.createBond('AA:BB'), isTrue);
      expect(await natives.adapterEnabled(), isTrue);

      expect(calls.map((c) => c.method), [
        'fetchUuidsWithSdp',
        'removeBond',
        'createBond',
        'adapterEnabled',
      ]);
      expect(
        calls
            .take(3)
            .map((c) => (c.arguments as Map)['address'])
            .toSet(),
        {'AA:BB'},
      );
    });

    test('routes the intent hooks over the activity recovery channel with '
        'the action', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(recoveryChannel, (call) async {
        calls.add(call);
        return true;
      });
      const natives = ChannelObd2WedgeRecoveryNatives();

      expect(await natives.resolveBtIntent(kBtActionRequestDisable), isTrue);
      expect(await natives.fireBtIntent(kBtActionRequestEnable), isTrue);
      expect(await natives.openBluetoothSettings(), isTrue);

      expect(calls.map((c) => c.method), [
        'resolveBtIntent',
        'fireBtIntent',
        'openBluetoothSettings',
      ]);
      expect((calls[0].arguments as Map)['action'], kBtActionRequestDisable);
      expect((calls[1].arguments as Map)['action'], kBtActionRequestEnable);
    });

    test('never throws — a PlatformException / missing native side degrades '
        'every hook to false (fault injection)', () async {
      // Classic channel throws; recovery channel has NO handler at all
      // (models an old native side → MissingPluginException).
      messenger.setMockMethodCallHandler(classicChannel, (call) async {
        throw PlatformException(code: 'platform', message: 'native blew up');
      });
      const natives = ChannelObd2WedgeRecoveryNatives();

      expect(await natives.fetchUuidsWithSdp('AA:BB'), isFalse);
      expect(await natives.removeBond('AA:BB'), isFalse);
      expect(await natives.createBond('AA:BB'), isFalse);
      expect(await natives.adapterEnabled(), isFalse);
      expect(await natives.resolveBtIntent(kBtActionRequestDisable), isFalse);
      expect(await natives.fireBtIntent(kBtActionRequestEnable), isFalse);
      expect(await natives.openBluetoothSettings(), isFalse);
    });

    test('a null native reply degrades to false', () async {
      messenger.setMockMethodCallHandler(classicChannel, (call) async => null);
      messenger.setMockMethodCallHandler(recoveryChannel, (call) async => null);
      const natives = ChannelObd2WedgeRecoveryNatives();
      expect(await natives.fetchUuidsWithSdp('AA:BB'), isFalse);
      expect(await natives.openBluetoothSettings(), isFalse);
    });
  });
}
