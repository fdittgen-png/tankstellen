import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/data/map_breadcrumb_collector.dart';

void main() {
  group('MapBreadcrumbCollector (#1316 phase 2)', () {
    test('record appends an entry with the right tag and message', () {
      final c = MapBreadcrumbCollector();
      c.record('map-cold-start', 'firing one-shot bump');

      expect(c.entries, hasLength(1));
      expect(c.entries.first.tag, equals('map-cold-start'));
      expect(c.entries.first.message, equals('firing one-shot bump'));
      // Recording must stamp `at` to a non-null DateTime — used by the
      // overlay to render the breadcrumb timestamp if we ever surface it.
      expect(c.entries.first.at, isNotNull);
    });

    test('preserves insertion order across multiple records', () {
      final c = MapBreadcrumbCollector();
      c.record('a', 'first');
      c.record('b', 'second');
      c.record('c', 'third');

      expect(
        c.entries.map((e) => e.message).toList(),
        equals(['first', 'second', 'third']),
      );
    });

    test('ring buffer caps at maxEntries — entry 101 evicts entry 0', () {
      final c = MapBreadcrumbCollector();
      for (var i = 0; i < MapBreadcrumbCollector.maxEntries; i++) {
        c.record('t', 'm$i');
      }
      expect(c.entries, hasLength(MapBreadcrumbCollector.maxEntries));
      expect(c.entries.first.message, equals('m0'));

      // One more — oldest must drop, newest must land at the end.
      c.record('t', 'overflow');
      expect(c.entries, hasLength(MapBreadcrumbCollector.maxEntries));
      expect(c.entries.first.message, equals('m1'),
          reason: 'oldest entry must be evicted on overflow');
      expect(c.entries.last.message, equals('overflow'));
    });

    test('clear empties the buffer', () {
      final c = MapBreadcrumbCollector();
      c.record('a', '1');
      c.record('b', '2');
      expect(c.entries, isNotEmpty);

      c.clear();
      expect(c.entries, isEmpty);
    });

    test('entries returns an unmodifiable view', () {
      final c = MapBreadcrumbCollector();
      c.record('a', '1');
      expect(
        () => c.entries.add(MapBreadcrumb(
          at: DateTime.now(),
          tag: 't',
          message: 'm',
        )),
        throwsUnsupportedError,
      );
    });
  });
}
