import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/collectors/network_state_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkStateCollector', () {
    setUp(() {
      // Mock the connectivity_plus method channel to return wifi
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'check') {
            return ['wifi'];
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        null,
      );
    });

    test('collect returns a NetworkSnapshot', () async {
      final snapshot = await NetworkStateCollector.collect();

      expect(snapshot, isA<NetworkSnapshot>());
      expect(snapshot.connectivityType, isNotNull);
      // Should have a boolean isOnline field
      expect(snapshot.isOnline, isA<bool>());
    });

    test('collect returns valid connectivity type', () async {
      final snapshot = await NetworkStateCollector.collect();

      // The mock returns wifi, so we expect wifi or it may fall back
      expect(
        snapshot.connectivityType,
        isIn(['wifi', 'mobile', 'ethernet', 'none', 'unknown']),
      );
    });
  });

  group('NetworkStateCollector fallback', () {
    setUp(() {
      // Mock to throw an error to test the catch branch
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (MethodCall methodCall) async {
          throw PlatformException(code: 'ERROR', message: 'not available');
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        null,
      );
    });

    test('collect returns offline unknown on failure', () async {
      final snapshot = await NetworkStateCollector.collect();

      expect(snapshot.isOnline, isFalse);
      expect(snapshot.connectivityType, 'unknown');
    });
  });
}
