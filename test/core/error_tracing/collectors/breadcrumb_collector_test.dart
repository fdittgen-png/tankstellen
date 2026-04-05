import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error_tracing/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/error_tracing/models/error_trace.dart';

void main() {
  setUp(() {
    BreadcrumbCollector.clear();
  });

  group('BreadcrumbCollector', () {
    test('starts empty', () {
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });

    test('add creates a breadcrumb', () {
      BreadcrumbCollector.add('navigate', detail: '/search');

      final crumbs = BreadcrumbCollector.snapshot();
      expect(crumbs, hasLength(1));
      expect(crumbs.first.action, 'navigate');
      expect(crumbs.first.detail, '/search');
      expect(crumbs.first.timestamp, isA<DateTime>());
    });

    test('add without detail sets detail to null', () {
      BreadcrumbCollector.add('tap_button');

      final crumbs = BreadcrumbCollector.snapshot();
      expect(crumbs.first.detail, isNull);
    });

    test('multiple adds preserve order', () {
      BreadcrumbCollector.add('first');
      BreadcrumbCollector.add('second');
      BreadcrumbCollector.add('third');

      final crumbs = BreadcrumbCollector.snapshot();
      expect(crumbs, hasLength(3));
      expect(crumbs[0].action, 'first');
      expect(crumbs[1].action, 'second');
      expect(crumbs[2].action, 'third');
    });

    test('max capacity evicts oldest entries', () {
      // Fill beyond maxBreadcrumbs (25)
      for (var i = 0; i < 30; i++) {
        BreadcrumbCollector.add('action-$i');
      }

      final crumbs = BreadcrumbCollector.snapshot();
      expect(crumbs, hasLength(BreadcrumbCollector.maxBreadcrumbs));

      // The first 5 (action-0 through action-4) should have been evicted
      expect(crumbs.first.action, 'action-5');
      expect(crumbs.last.action, 'action-29');
    });

    test('exactly at max capacity keeps all', () {
      for (var i = 0; i < BreadcrumbCollector.maxBreadcrumbs; i++) {
        BreadcrumbCollector.add('action-$i');
      }

      final crumbs = BreadcrumbCollector.snapshot();
      expect(crumbs, hasLength(BreadcrumbCollector.maxBreadcrumbs));
      expect(crumbs.first.action, 'action-0');
      expect(crumbs.last.action, 'action-24');
    });

    test('clear removes all breadcrumbs', () {
      BreadcrumbCollector.add('a');
      BreadcrumbCollector.add('b');
      expect(BreadcrumbCollector.snapshot(), hasLength(2));

      BreadcrumbCollector.clear();
      expect(BreadcrumbCollector.snapshot(), isEmpty);
    });

    test('snapshot returns unmodifiable list', () {
      BreadcrumbCollector.add('test');

      final crumbs = BreadcrumbCollector.snapshot();
      expect(
        () => crumbs.add(
          Breadcrumb(timestamp: DateTime.now(), action: 'hack'),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('adding after clear starts fresh', () {
      BreadcrumbCollector.add('before');
      BreadcrumbCollector.clear();
      BreadcrumbCollector.add('after');

      final crumbs = BreadcrumbCollector.snapshot();
      expect(crumbs, hasLength(1));
      expect(crumbs.first.action, 'after');
    });
  });
}
