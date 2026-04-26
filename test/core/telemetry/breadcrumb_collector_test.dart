import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';

void main() {
  setUp(() => BreadcrumbCollector.clear());

  group('BreadcrumbCollector', () {
    test('adds breadcrumbs', () {
      BreadcrumbCollector.add('tap:search');
      BreadcrumbCollector.add('navigate:/map');
      expect(BreadcrumbCollector.snapshot().length, 2);
    });

    test('preserves order', () {
      BreadcrumbCollector.add('first');
      BreadcrumbCollector.add('second');
      BreadcrumbCollector.add('third');
      final snap = BreadcrumbCollector.snapshot();
      expect(snap[0].action, 'first');
      expect(snap[2].action, 'third');
    });

    test('enforces max size', () {
      for (int i = 0; i < 30; i++) {
        BreadcrumbCollector.add('action_$i');
      }
      expect(
        BreadcrumbCollector.snapshot().length,
        BreadcrumbCollector.maxBreadcrumbs,
      );
      // Oldest should be dropped
      expect(BreadcrumbCollector.snapshot().first.action, 'action_5');
    });

    test('includes detail', () {
      BreadcrumbCollector.add('api:request', detail: 'GET /list.php');
      expect(BreadcrumbCollector.snapshot().first.detail, 'GET /list.php');
    });

    test('clear empties the buffer', () {
      BreadcrumbCollector.add('test');
      BreadcrumbCollector.clear();
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });

    test('snapshot is unmodifiable', () {
      BreadcrumbCollector.add('test');
      final snap = BreadcrumbCollector.snapshot();
      expect(() => snap.add(snap.first), throwsA(anything));
    });
  });
}
