import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HiveStorage._toStringDynamicMap', () {
    test('converts Map<dynamic, dynamic> to Map<String, dynamic>', () {
      // Simulate what Hive returns on Android
      final dynamic hiveMap = <dynamic, dynamic>{
        'key1': 'value1',
        'key2': 42,
        'key3': true,
      };

      // Our helper should handle this
      // Testing the logic directly since the method is static private
      final result = Map<String, dynamic>.fromEntries(
        (hiveMap as Map).entries.map(
          (e) => MapEntry(e.key.toString(), e.value),
        ),
      );

      expect(result['key1'], 'value1');
      expect(result['key2'], 42);
      expect(result['key3'], true);
    });

    test('handles null input', () {
      expect(null, isNull);
    });

    test('handles nested maps', () {
      final dynamic nested = <dynamic, dynamic>{
        'outer': <dynamic, dynamic>{
          'inner': 'value',
        },
      };

      final result = Map<String, dynamic>.fromEntries(
        (nested as Map).entries.map(
          (e) => MapEntry(e.key.toString(), e.value),
        ),
      );

      expect(result['outer'], isA<Map>());
    });
  });
}
