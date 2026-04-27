import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/driving_insight.dart';

DrivingInsight _make({
  String labelKey = 'insightHighRpm',
  double litersWasted = 0.6,
  double percentOfTrip = 12.5,
  Map<String, num>? metadata,
}) =>
    DrivingInsight(
      labelKey: labelKey,
      litersWasted: litersWasted,
      percentOfTrip: percentOfTrip,
      metadata: metadata ?? const {},
    );

void main() {
  group('DrivingInsight construction', () {
    test('const constructor exposes all 3 required fields verbatim', () {
      const insight = DrivingInsight(
        labelKey: 'insightIdling',
        litersWasted: 0.123,
        percentOfTrip: 8.4,
      );

      expect(insight.labelKey, 'insightIdling');
      expect(insight.litersWasted, 0.123);
      expect(insight.percentOfTrip, 8.4);
    });

    test('metadata defaults to empty const map when omitted', () {
      const insight = DrivingInsight(
        labelKey: 'insightHighRpm',
        litersWasted: 0.5,
        percentOfTrip: 10.0,
      );

      expect(insight.metadata, isEmpty);
      expect(insight.metadata, isA<Map<String, num>>());
    });

    test('explicit metadata is exposed verbatim', () {
      const insight = DrivingInsight(
        labelKey: 'insightHighRpm',
        litersWasted: 0.5,
        percentOfTrip: 10.0,
        metadata: {'aboveRpm': 3000, 'eventCount': 4},
      );

      expect(insight.metadata, {'aboveRpm': 3000, 'eventCount': 4});
    });
  });

  group('DrivingInsight equality', () {
    test('is reflexive: a == a', () {
      final a = _make();
      expect(a == a, isTrue);
    });

    test('is symmetric: if a == b then b == a', () {
      final a = _make(metadata: const {'aboveRpm': 3000});
      final b = _make(metadata: const {'aboveRpm': 3000});
      expect(a == b, isTrue);
      expect(b == a, isTrue);
    });

    test('two instances with identical fields and equal metadata are equal',
        () {
      final a = _make(metadata: const {'eventCount': 2});
      final b = _make(metadata: const {'eventCount': 2});
      expect(a, equals(b));
    });

    test('differs when labelKey differs', () {
      final a = _make(labelKey: 'insightHighRpm');
      final b = _make(labelKey: 'insightIdling');
      expect(a == b, isFalse);
    });

    test('differs when litersWasted differs', () {
      final a = _make(litersWasted: 0.6);
      final b = _make(litersWasted: 0.7);
      expect(a == b, isFalse);
    });

    test('differs when percentOfTrip differs', () {
      final a = _make(percentOfTrip: 12.5);
      final b = _make(percentOfTrip: 13.0);
      expect(a == b, isFalse);
    });

    test('short-circuits on identical(a, a)', () {
      final a = _make(metadata: const {'aboveRpm': 3000});
      expect(identical(a, a), isTrue);
      expect(a == a, isTrue);
    });

    test('returns false when compared against a non-DrivingInsight', () {
      final a = _make();
      // ignore: unrelated_type_equality_checks
      expect(a == Object(), isFalse);
    });
  });

  group('DrivingInsight metadata deep-equality', () {
    test('same map literal => equal', () {
      final a = _make(metadata: const {'aboveRpm': 3000, 'eventCount': 4});
      final b = _make(metadata: const {'aboveRpm': 3000, 'eventCount': 4});
      expect(a == b, isTrue);
    });

    test('same keys + values, different insertion order => equal', () {
      // Build two maps with identical entries but opposite insertion order
      // so the compiler can't canonicalise them into the same const.
      final ascending = <String, num>{}
        ..['aboveRpm'] = 3000
        ..['eventCount'] = 4;
      final descending = <String, num>{}
        ..['eventCount'] = 4
        ..['aboveRpm'] = 3000;

      // Sanity-check that the iteration order really differs (LinkedHashMap
      // preserves insertion order in Dart).
      expect(
        ascending.keys.toList(),
        isNot(equals(descending.keys.toList())),
      );

      final a = _make(metadata: ascending);
      final b = _make(metadata: descending);
      expect(a == b, isTrue);
    });

    test('different lengths (one extra key) => not equal', () {
      final a = _make(metadata: const {'aboveRpm': 3000});
      final b = _make(metadata: const {'aboveRpm': 3000, 'eventCount': 4});
      expect(a == b, isFalse);
    });

    test('same length, different keys => not equal', () {
      final a = _make(metadata: const {'aboveRpm': 3000});
      final b = _make(metadata: const {'eventCount': 3000});
      expect(a == b, isFalse);
    });

    test('same keys, different values => not equal', () {
      final a = _make(metadata: const {'aboveRpm': 3000});
      final b = _make(metadata: const {'aboveRpm': 3500});
      expect(a == b, isFalse);
    });

    test('empty map vs non-empty map => not equal', () {
      final a = _make(metadata: const {});
      final b = _make(metadata: const {'aboveRpm': 3000});
      expect(a == b, isFalse);
    });

    test('both empty maps => equal', () {
      final a = _make(metadata: const {});
      final b = _make(metadata: const {});
      expect(a == b, isTrue);
    });

    test('mixed int and double values compare by numeric equality', () {
      // num equality treats 3000 == 3000.0 as true; the deep-equality
      // helper inherits that behaviour.
      final a = _make(metadata: const {'aboveRpm': 3000});
      final b = _make(metadata: const {'aboveRpm': 3000.0});
      expect(a == b, isTrue);
    });
  });

  group('DrivingInsight hashCode', () {
    test('is equal for two equal insights with empty metadata', () {
      final a = _make();
      final b = _make();
      expect(a.hashCode, b.hashCode);
    });

    test('is equal for two equal insights with the same metadata', () {
      final a = _make(metadata: const {'aboveRpm': 3000, 'eventCount': 4});
      final b = _make(metadata: const {'aboveRpm': 3000, 'eventCount': 4});
      expect(a.hashCode, b.hashCode);
    });

    test('is equal when metadata insertion order differs but entries match',
        () {
      final ascending = <String, num>{}
        ..['aboveRpm'] = 3000
        ..['eventCount'] = 4;
      final descending = <String, num>{}
        ..['eventCount'] = 4
        ..['aboveRpm'] = 3000;

      final a = _make(metadata: ascending);
      final b = _make(metadata: descending);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('computes a non-zero value for typical inputs (smoke)', () {
      final a = _make(metadata: const {'aboveRpm': 3000});
      expect(a.hashCode, isNot(0));
    });
  });

  group('DrivingInsight toString', () {
    test('starts with the class name prefix', () {
      final s = _make();
      expect(s.toString(), startsWith('DrivingInsight('));
    });

    test('includes the labelKey', () {
      final s = _make(labelKey: 'insightHardAccel');
      expect(s.toString(), contains('labelKey: insightHardAccel'));
    });

    test('formats litersWasted to 3 decimal places', () {
      final s = _make(litersWasted: 0.6);
      expect(s.toString(), contains('litersWasted: 0.600'));
    });

    test('rounds litersWasted to 3 decimals (banker-style toStringAsFixed)',
        () {
      final s = _make(litersWasted: 0.12345);
      expect(s.toString(), contains('litersWasted: 0.123'));
    });

    test('formats percentOfTrip to 1 decimal place', () {
      final s = _make(percentOfTrip: 12.5);
      expect(s.toString(), contains('percentOfTrip: 12.5'));
    });

    test('rounds percentOfTrip to 1 decimal', () {
      final s = _make(percentOfTrip: 12.46);
      expect(s.toString(), contains('percentOfTrip: 12.5'));
    });

    test('includes the metadata map', () {
      final s = _make(metadata: const {'aboveRpm': 3000, 'eventCount': 4});
      expect(s.toString(), contains('metadata:'));
      expect(s.toString(), contains('aboveRpm'));
      expect(s.toString(), contains('3000'));
      expect(s.toString(), contains('eventCount'));
      expect(s.toString(), contains('4'));
    });

    test('includes an empty metadata map when none was supplied', () {
      final s = _make();
      expect(s.toString(), contains('metadata: {}'));
    });
  });
}
