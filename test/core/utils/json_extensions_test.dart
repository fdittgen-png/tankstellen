import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/json_extensions.dart';

void main() {
  group('SafeJsonAccessors', () {
    group('getString', () {
      test('returns string value as-is', () {
        expect({'k': 'hello'}.getString('k'), 'hello');
      });

      test('returns empty string as-is', () {
        expect({'k': ''}.getString('k'), '');
      });

      test('converts int to string', () {
        expect({'k': 42}.getString('k'), '42');
      });

      test('converts double to string', () {
        expect({'k': 3.14}.getString('k'), '3.14');
      });

      test('converts bool to string', () {
        expect({'k': true}.getString('k'), 'true');
        expect({'k': false}.getString('k'), 'false');
      });

      test('returns null for missing key', () {
        expect(<String, dynamic>{}.getString('k'), isNull);
      });

      test('returns null for explicit null value', () {
        expect({'k': null}.getString('k'), isNull);
      });
    });

    group('getDouble', () {
      test('returns double value as-is', () {
        expect({'k': 3.14}.getDouble('k'), 3.14);
      });

      test('converts int to double', () {
        expect({'k': 42}.getDouble('k'), 42.0);
      });

      test('handles negative values', () {
        expect({'k': -1.5}.getDouble('k'), -1.5);
        expect({'k': -7}.getDouble('k'), -7.0);
      });

      test('parses numeric string', () {
        expect({'k': '3.14'}.getDouble('k'), 3.14);
        expect({'k': '42'}.getDouble('k'), 42.0);
        expect({'k': '-2.5'}.getDouble('k'), -2.5);
      });

      test('returns null for non-numeric string', () {
        expect({'k': 'abc'}.getDouble('k'), isNull);
      });

      test('returns null for empty string', () {
        expect({'k': ''}.getDouble('k'), isNull);
      });

      test('returns null for bool value', () {
        expect({'k': true}.getDouble('k'), isNull);
        expect({'k': false}.getDouble('k'), isNull);
      });

      test('returns null for missing key', () {
        expect(<String, dynamic>{}.getDouble('k'), isNull);
      });

      test('returns null for explicit null value', () {
        expect({'k': null}.getDouble('k'), isNull);
      });
    });

    group('getInt', () {
      test('returns int value as-is', () {
        expect({'k': 42}.getInt('k'), 42);
      });

      test('truncates positive double to int', () {
        expect({'k': 3.9}.getInt('k'), 3);
      });

      test('truncates negative double toward zero', () {
        // Dart double.toInt() truncates toward zero, so -3.9 -> -3.
        expect({'k': -3.9}.getInt('k'), -3);
      });

      test('parses numeric string to int', () {
        expect({'k': '42'}.getInt('k'), 42);
        expect({'k': '-7'}.getInt('k'), -7);
      });

      test('returns null for non-numeric string', () {
        expect({'k': 'abc'}.getInt('k'), isNull);
      });

      test('returns null for decimal-formatted string', () {
        // int.tryParse rejects '3.14', unlike double.tryParse.
        expect({'k': '3.14'}.getInt('k'), isNull);
      });

      test('returns null for bool value', () {
        expect({'k': true}.getInt('k'), isNull);
        expect({'k': false}.getInt('k'), isNull);
      });

      test('returns null for missing key', () {
        expect(<String, dynamic>{}.getInt('k'), isNull);
      });

      test('returns null for explicit null value', () {
        expect({'k': null}.getInt('k'), isNull);
      });
    });

    group('getBool', () {
      test('returns true bool as-is', () {
        expect({'k': true}.getBool('k'), isTrue);
      });

      test('returns false bool as-is', () {
        expect({'k': false}.getBool('k'), isFalse);
      });

      test('maps int 1 to true', () {
        expect({'k': 1}.getBool('k'), isTrue);
      });

      test('maps int 0 to false', () {
        expect({'k': 0}.getBool('k'), isFalse);
      });

      test('maps non-zero int to true', () {
        expect({'k': 42}.getBool('k'), isTrue);
        expect({'k': -1}.getBool('k'), isTrue);
      });

      test('parses lowercase string', () {
        expect({'k': 'true'}.getBool('k'), isTrue);
        expect({'k': 'false'}.getBool('k'), isFalse);
      });

      test('parses uppercase string', () {
        expect({'k': 'TRUE'}.getBool('k'), isTrue);
        expect({'k': 'FALSE'}.getBool('k'), isFalse);
      });

      test('parses mixed-case string', () {
        expect({'k': 'True'}.getBool('k'), isTrue);
        expect({'k': 'False'}.getBool('k'), isFalse);
      });

      test('returns null for unrecognised string', () {
        expect({'k': 'yes'}.getBool('k'), isNull);
        expect({'k': 'no'}.getBool('k'), isNull);
        expect({'k': '1'}.getBool('k'), isNull);
        expect({'k': ''}.getBool('k'), isNull);
      });

      test('returns null for double value', () {
        // Only bool/int/String are handled — doubles fall through.
        expect({'k': 1.0}.getBool('k'), isNull);
      });

      test('returns null for missing key', () {
        expect(<String, dynamic>{}.getBool('k'), isNull);
      });

      test('returns null for explicit null value', () {
        expect({'k': null}.getBool('k'), isNull);
      });
    });

    group('getList', () {
      test('returns list of T when all elements match', () {
        expect(<String, dynamic>{
          'k': <dynamic>['a', 'b', 'c'],
        }.getList<String>('k'), ['a', 'b', 'c']);
      });

      test('filters mixed-type list to T only', () {
        expect(<String, dynamic>{
          'k': <dynamic>['a', 1, 'b', null, true, 'c'],
        }.getList<String>('k'), ['a', 'b', 'c']);
      });

      test('returns empty list when no element matches T', () {
        expect(<String, dynamic>{
          'k': <dynamic>[1, 2, 3],
        }.getList<String>('k'), isEmpty);
      });

      test('works for List<int>', () {
        expect(<String, dynamic>{
          'k': <dynamic>[1, 'two', 3, 4.5],
        }.getList<int>('k'), [1, 3]);
      });

      test('returns empty list for missing key', () {
        expect(<String, dynamic>{}.getList<String>('k'), isEmpty);
      });

      test('returns empty list for explicit null value', () {
        expect({'k': null}.getList<String>('k'), isEmpty);
      });

      test('returns empty list for non-list value (string)', () {
        expect({'k': 'not a list'}.getList<String>('k'), isEmpty);
      });

      test('returns empty list for non-list value (map)', () {
        expect({'k': <String, dynamic>{'a': 1}}.getList<String>('k'), isEmpty);
      });

      test('returns empty list for non-list value (int)', () {
        expect({'k': 42}.getList<String>('k'), isEmpty);
      });

      test('preserves original element order', () {
        expect(<String, dynamic>{
          'k': <dynamic>['x', 1, 'a', 2, 'm'],
        }.getList<String>('k'), ['x', 'a', 'm']);
      });
    });

    group('getMap', () {
      test('returns Map<String, dynamic> as-is', () {
        final inner = <String, dynamic>{'nested': 'value', 'count': 3};
        expect({'k': inner}.getMap('k'), inner);
      });

      test('converts Map<dynamic, dynamic> via Map<String, dynamic>.from', () {
        final raw = <dynamic, dynamic>{'nested': 'value', 'count': 3};
        final result = {'k': raw}.getMap('k');
        expect(result, isA<Map<String, dynamic>>());
        expect(result, {'nested': 'value', 'count': 3});
      });

      test('converts Map<String, String> to Map<String, dynamic>', () {
        final raw = <String, String>{'a': 'b'};
        final result = {'k': raw}.getMap('k');
        expect(result, isA<Map<String, dynamic>>());
        expect(result, {'a': 'b'});
      });

      test('returns null for missing key', () {
        expect(<String, dynamic>{}.getMap('k'), isNull);
      });

      test('returns null for explicit null value', () {
        expect({'k': null}.getMap('k'), isNull);
      });

      test('returns null for non-map string value', () {
        expect({'k': 'not a map'}.getMap('k'), isNull);
      });

      test('returns null for list value', () {
        expect({'k': <dynamic>[1, 2, 3]}.getMap('k'), isNull);
      });

      test('returns null for numeric value', () {
        expect({'k': 42}.getMap('k'), isNull);
      });
    });
  });
}
