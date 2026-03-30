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
        );
      }, returnsNormally);
    });
  });
}
