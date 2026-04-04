import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/car/car_data_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CarDataBridge', () {
    test('isCarMode returns false when no native implementation', () async {
      // Without a native MethodChannel handler, this should return false
      final result = await CarDataBridge.isCarMode();
      expect(result, isFalse);
    });

    test('registerHandlers completes without error', () {
      // Should not throw even when no native handler exists
      expect(() {
        CarDataBridge.registerHandlers(
          onSearchNearby: (lat, lng, radius) async => [],
          onGetFavorites: () async => [],
          onGetStationDetail: (id) async => null,
          appVersion: '4.3.0+4002',
        );
      }, returnsNormally);
    });

    test('getAppVersion returns the provided version string', () async {
      CarDataBridge.registerHandlers(
        onSearchNearby: (lat, lng, radius) async => [],
        onGetFavorites: () async => [],
        onGetStationDetail: (id) async => null,
        appVersion: '4.3.0+4002',
      );

      // Simulate native→Dart call via the binary messenger
      const channel = MethodChannel('com.tankstellen/car');
      final codec = const StandardMethodCodec();
      final message = codec.encodeMethodCall(const MethodCall('getAppVersion'));
      final responseBytes = await TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .handlePlatformMessage('com.tankstellen/car', message, (_) {});
      final result = codec.decodeEnvelope(responseBytes!);
      expect(result, '4.3.0+4002');
    });

    test('getAppVersion does not return hardcoded 4.1.0', () async {
      CarDataBridge.registerHandlers(
        onSearchNearby: (lat, lng, radius) async => [],
        onGetFavorites: () async => [],
        onGetStationDetail: (id) async => null,
        appVersion: '5.0.0+100',
      );

      const channel = MethodChannel('com.tankstellen/car');
      final codec = const StandardMethodCodec();
      final message = codec.encodeMethodCall(const MethodCall('getAppVersion'));
      final responseBytes = await TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .handlePlatformMessage('com.tankstellen/car', message, (_) {});
      final result = codec.decodeEnvelope(responseBytes!);
      expect(result, isNot('4.1.0'));
      expect(result, '5.0.0+100');
    });
  });
}
