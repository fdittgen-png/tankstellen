import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/baseline_sync.dart';

Map<String, dynamic> _payload(Map<String, Map<String, num>> situations) {
  return {
    'version': 1,
    'perSituation': {
      for (final e in situations.entries)
        e.key: {
          'n': e.value['n'] ?? 0,
          'mean': e.value['mean'] ?? 0.0,
          'm2': e.value['m2'] ?? 0.0,
        },
    },
  };
}

void main() {
  group('mergeBaselinePayloads (#780)', () {
    test('both null → empty perSituation, version preserved', () {
      final merged = mergeBaselinePayloads(null, null);
      expect(merged['version'], 1);
      expect(merged['perSituation'], isEmpty);
    });

    test('local only → passthrough of every situation', () {
      final local = _payload({
        'highwayCruise': {'n': 10, 'mean': 6.5, 'm2': 1.0},
      });
      final merged = mergeBaselinePayloads(local, null);
      final sit = merged['perSituation'] as Map<String, dynamic>;
      expect(sit['highwayCruise']['n'], 10);
      expect(sit['highwayCruise']['mean'], 6.5);
    });

    test('server only → passthrough of every situation', () {
      final server = _payload({
        'urbanCruise': {'n': 7, 'mean': 8.1, 'm2': 2.0},
      });
      final merged = mergeBaselinePayloads(null, server);
      final sit = merged['perSituation'] as Map<String, dynamic>;
      expect(sit['urbanCruise']['n'], 7);
    });

    test('both present, disjoint situations → union', () {
      final local = _payload({
        'highwayCruise': {'n': 10},
      });
      final server = _payload({
        'urbanCruise': {'n': 20},
      });
      final merged = mergeBaselinePayloads(local, server);
      final sit = merged['perSituation'] as Map<String, dynamic>;
      expect(sit.keys.toSet(), {'highwayCruise', 'urbanCruise'});
      expect(sit['highwayCruise']['n'], 10);
      expect(sit['urbanCruise']['n'], 20);
    });

    test('overlapping situations → higher-n wins regardless of which '
        'side it came from', () {
      final local = _payload({
        'highwayCruise': {'n': 5, 'mean': 7.0},
        'urbanCruise': {'n': 100, 'mean': 8.0},
      });
      final server = _payload({
        'highwayCruise': {'n': 50, 'mean': 6.0},
        'urbanCruise': {'n': 10, 'mean': 9.0},
      });
      final merged = mergeBaselinePayloads(local, server);
      final sit = merged['perSituation'] as Map<String, dynamic>;
      // Server had more highway → server mean wins
      expect(sit['highwayCruise']['n'], 50);
      expect(sit['highwayCruise']['mean'], 6.0);
      // Local had more urban → local mean wins
      expect(sit['urbanCruise']['n'], 100);
      expect(sit['urbanCruise']['mean'], 8.0);
    });

    test('tied n → local wins — a device should not be silently '
        'overwritten by an equally-aged server copy', () {
      final local = _payload({
        'highwayCruise': {'n': 20, 'mean': 7.0},
      });
      final server = _payload({
        'highwayCruise': {'n': 20, 'mean': 6.0},
      });
      final merged = mergeBaselinePayloads(local, server);
      final sit = merged['perSituation'] as Map<String, dynamic>;
      expect(sit['highwayCruise']['mean'], 7.0);
    });
  });

  group('totalSampleCount (#780)', () {
    test('sums n across every situation', () {
      final payload = _payload({
        'highwayCruise': {'n': 30},
        'urbanCruise': {'n': 15},
        'idle': {'n': 5},
      });
      expect(totalSampleCount(payload), 50);
    });

    test('empty payload → 0', () {
      expect(totalSampleCount({'version': 1, 'perSituation': {}}), 0);
    });
  });

  group('mergeBaselineJson (#780)', () {
    test('both null/empty → null', () {
      expect(mergeBaselineJson(null, null), isNull);
      expect(mergeBaselineJson('', ''), isNull);
    });

    test('valid local + null server round-trips through JSON', () {
      final local = jsonEncode(_payload({
        'highwayCruise': {'n': 10, 'mean': 6.5, 'm2': 1.0},
      }));
      final merged = mergeBaselineJson(local, null);
      expect(merged, isNotNull);
      final decoded = jsonDecode(merged!) as Map;
      expect((decoded['perSituation'] as Map)['highwayCruise']['n'], 10);
    });

    test('corrupt JSON on either side → treated as empty, no throw',
        () {
      final local = jsonEncode(_payload({
        'highwayCruise': {'n': 10},
      }));
      final merged = mergeBaselineJson(local, '{not json');
      expect(merged, isNotNull);
      final decoded = jsonDecode(merged!) as Map;
      expect((decoded['perSituation'] as Map)['highwayCruise']['n'], 10);
    });
  });
}
