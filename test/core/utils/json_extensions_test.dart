import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/json_extensions.dart';

void main() {
  group('SafeJsonAccessors', () {
    group('getString', () {
      test('returns string value', () {
        expect({'k': 'hello'}.getString('k'), 'hello');
      });

      test('converts num to string', () {
        expect({'k': 42}.getString('k'), '42');
        expect({'k': 3.14}.getString('k'), '3.14');
      });

      test('returns null for missing key', () {
        expect(<String, dynamic>{}.getString('k'), isNull);
      });

      test('returns null for null value', () {
        expect({'k': null}.getString('k'), isNull);
      });
    });

    group('getDouble', () {
      test('returns double value', () {
        expect({'k': 3.14}.getDouble('k'), 3.14);
      });

      test('converts int to double', () {
        expect({'k': 42}.getDouble('k'), 42.0);
      });

      test('parses string to double', () {
        expect({'k': '3.14'}.getDouble('k'), 3.14);
      });

      test('returns null for non-numeric string', () {
        expect({'k': 'abc'}.getDouble('k'), isNull);
      });

      test('returns null for missing key', () {
        expect(<String, dynamic>{}.getDouble('k'), isNull);
      });
    });

    group('getInt', () {
      test('returns int value', () {
        expect({'k': 42}.getInt('k'), 42);
      });

      test('truncates double to int', () {
        expect({'k': 3.9}.getInt('k'), 3);
      });

      test('parses string to int', () {
        expect({'k': '42'}.getInt('k'), 42);
      });

      test('returns null for non-numeric', () {
        expect({'k': 'abc'}.getInt('k'), isNull);
      });
    });

    group('getBool', () {
      test('returns bool value', () {
        expect({'k': true}.getBool('k'), isTrue);
        expect({'k': false}.getBool('k'), isFalse);
      });

      test('converts int to bool', () {
        expect({'k': 1}.getBool('k'), isTrue);
        expect({'k': 0}.getBool('k'), isFalse);
      });

      test('parses string to bool', () {
        expect({'k': 'true'}.getBool('k'), isTrue);
        expect({'k': 'false'}.getBool('k'), isFalse);
        expect({'k': 'TRUE'}.getBool('k'), isTrue);
      });

      test('returns null for non-bool string', () {
        expect({'k': 'yes'}.getBool('k'), isNull);
      });
    });

    group('getList', () {
      test('returns typed list', () {
        expect({'k': ['a', 'b']}.getList<String>('k'), ['a', 'b']);
      });

      test('filters mismatched types', () {
        expect({'k': ['a', 1, 'b']}.getList<String>('k'), ['a', 'b']);
      });

      test('returns empty list for missing key', () {
        expect(<String, dynamic>{}.getList<String>('k'), isEmpty);
      });

      test('returns empty list for non-list value', () {
        expect({'k': 'not a list'}.getList<String>('k'), isEmpty);
      });
    });

    group('getMap', () {
      test('returns map value', () {
        final inner = {'nested': 'value'};
        expect({'k': inner}.getMap('k'), inner);
      });

      test('converts raw Map to typed Map', () {
        final raw = <dynamic, dynamic>{'nested': 'value'};
        expect({'k': raw}.getMap('k'), {'nested': 'value'});
      });

      test('returns null for missing key', () {
        expect(<String, dynamic>{}.getMap('k'), isNull);
      });

      test('returns null for non-map value', () {
        expect({'k': 'string'}.getMap('k'), isNull);
      });
    });
  });
}
