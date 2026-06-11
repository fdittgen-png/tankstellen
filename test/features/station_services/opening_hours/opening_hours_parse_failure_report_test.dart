// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/core/domain/opening_hours.dart';
import 'package:tankstellen/features/station_services/austria/austria_opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/chile/chile_opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/germany/germany_opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/opening_hours/opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/portugal/portugal_opening_hours_adapter.dart';
import 'package:tankstellen/features/station_services/spain/spain_opening_hours_adapter.dart';

/// #3148 — the five country opening-hours adapters used to swallow parse
/// failures in an assert-wrapped `print`, which is compiled out of release
/// builds: a provider format change degraded every station to "no data"
/// with zero field signal. The catch now emits an `oh-parse-failed`
/// breadcrumb + one errorLogger ERROR, throttled to the first occurrence
/// per adapter per session, while still returning
/// [WeeklyOpeningHours.notAvailable].
class _CapturingRecorder implements TraceRecorder {
  final captured = <ContextualError>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    captured.add(error as ContextualError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Garbage that passes each adapter's `is Map` shape check and then throws
/// on the first key access — a guaranteed in-`try` fault, exactly like a
/// provider payload whose nested shape changed under the adapter.
class _ThrowingMap extends MapBase<dynamic, dynamic> {
  @override
  dynamic operator [](Object? key) =>
      throw StateError('simulated provider-shape fault');

  @override
  void operator []=(dynamic key, dynamic value) {}

  @override
  void clear() {}

  @override
  Iterable<dynamic> get keys =>
      throw StateError('simulated provider-shape fault');

  @override
  dynamic remove(Object? key) => null;
}

void main() {
  late _CapturingRecorder recorder;

  setUp(() {
    recorder = _CapturingRecorder();
    errorLogger.testRecorderOverride = recorder;
    BreadcrumbCollector.clear();
    OpeningHoursAdapter.resetParseFailureReportsForTest();
  });

  tearDown(() {
    errorLogger.resetForTest();
    BreadcrumbCollector.clear();
    OpeningHoursAdapter.resetParseFailureReportsForTest();
  });

  /// Adapters whose parse path reads from a Map payload — feeding the
  /// throwing map drives the real catch block.
  final mapDrivenAdapters = <String, OpeningHoursAdapter>{
    'DE': const GermanyOpeningHoursAdapter(),
    'PT': const PortugalOpeningHoursAdapter(),
    'AT': const AustriaOpeningHoursAdapter(),
    'CL': const ChileOpeningHoursAdapter(),
  };

  for (final entry in mapDrivenAdapters.entries) {
    group('${entry.value.runtimeType} (${entry.key})', () {
      test('garbage input degrades to notAvailable AND fires breadcrumb + '
          'errorLogger once across two calls', () {
        final adapter = entry.value;
        final garbage = _ThrowingMap();

        expect(adapter.parse(garbage), WeeklyOpeningHours.notAvailable);
        expect(adapter.parse(garbage), WeeklyOpeningHours.notAvailable,
            reason: 'second call must also degrade gracefully');

        final crumbs = BreadcrumbCollector.snapshot()
            .where((b) => b.action == 'oh-parse-failed')
            .toList();
        expect(crumbs, hasLength(1),
            reason: 'breadcrumb throttled to first occurrence per session');
        expect(crumbs.single.detail, startsWith(entry.key));
        expect(crumbs.single.detail, contains('StateError'));

        expect(recorder.captured, hasLength(1),
            reason: 'errorLogger throttled to first occurrence per session');
        final logged = recorder.captured.single;
        expect(logged.layer, ErrorLayer.services);
        expect(logged.context?['country'], entry.key);
        expect(logged.inner, isA<StateError>());
      });
    });
  }

  group('SpainOpeningHoursAdapter (ES)', () {
    test('non-string garbage degrades to notAvailable without reporting '
        '(shape-narrowed before the try body can fault)', () {
      const adapter = SpainOpeningHoursAdapter();
      expect(adapter.parse(_ThrowingMap()), WeeklyOpeningHours.notAvailable);
      expect(
          BreadcrumbCollector.snapshot()
              .where((b) => b.action == 'oh-parse-failed'),
          isEmpty);
    });
  });

  group('shared reporter throttle', () {
    test('reports once per country, independent across countries', () {
      const de = GermanyOpeningHoursAdapter();
      const pt = PortugalOpeningHoursAdapter();
      final garbage = _ThrowingMap();

      de.parse(garbage);
      de.parse(garbage);
      pt.parse(garbage);

      final crumbs = BreadcrumbCollector.snapshot()
          .where((b) => b.action == 'oh-parse-failed')
          .map((b) => b.detail)
          .toList();
      expect(crumbs, hasLength(2),
          reason: 'one report per adapter/country, not per call');
      expect(recorder.captured.map((c) => c.context?['country']),
          containsAll(<String>['DE', 'PT']));
    });
  });
}
