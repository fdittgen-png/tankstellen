import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';

/// Coverage for [AutoRecordTraceLog] — the in-memory ring of
/// auto-record state transitions added in #1004 phase 2a-trace.
///
/// Asserts the four invariants the coordinator depends on: append +
/// snapshot order, ring capacity, clear, and the breadcrumb mirror.
void main() {
  setUp(() {
    AutoRecordTraceLog.clear();
    BreadcrumbCollector.clear();
  });

  test('add() appends to ring; snapshot() returns events in order', () {
    AutoRecordTraceLog.add(
      AutoRecordEventKind.coordinatorStarted,
      mac: 'AA:BB:CC:DD:EE:FF',
      detail: 'thresholdKmh=5.0',
    );
    AutoRecordTraceLog.add(
      AutoRecordEventKind.adapterConnected,
      mac: 'AA:BB:CC:DD:EE:FF',
    );
    AutoRecordTraceLog.add(
      AutoRecordEventKind.speedSampleSupraThreshold,
      mac: 'AA:BB:CC:DD:EE:FF',
      detail: 'speed=12.3 kmh, count=1/3',
    );

    final List<AutoRecordEvent> snapshot = AutoRecordTraceLog.snapshot();
    expect(snapshot, hasLength(3));
    expect(snapshot[0].kind, AutoRecordEventKind.coordinatorStarted);
    expect(snapshot[0].mac, 'AA:BB:CC:DD:EE:FF');
    expect(snapshot[0].detail, 'thresholdKmh=5.0');
    expect(snapshot[1].kind, AutoRecordEventKind.adapterConnected);
    expect(snapshot[1].mac, 'AA:BB:CC:DD:EE:FF');
    expect(snapshot[1].detail, isNull);
    expect(snapshot[2].kind, AutoRecordEventKind.speedSampleSupraThreshold);
    expect(snapshot[2].detail, 'speed=12.3 kmh, count=1/3');
  });

  test('snapshot() returns an unmodifiable list', () {
    AutoRecordTraceLog.add(AutoRecordEventKind.coordinatorStarted);
    final List<AutoRecordEvent> snapshot = AutoRecordTraceLog.snapshot();
    expect(
      () => snapshot.add(AutoRecordEvent(
        timestamp: DateTime.now(),
        kind: AutoRecordEventKind.error,
      )),
      throwsUnsupportedError,
      reason: 'snapshot must protect the ring from outside mutation',
    );
  });

  test('ring capacity: 101 adds keep the latest 100', () {
    // Push 101 events with a distinguishable detail so we can check
    // the oldest fell off and the newest stuck.
    for (int i = 0; i < 101; i++) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.speedSampleSupraThreshold,
        detail: 'i=$i',
      );
    }
    final List<AutoRecordEvent> snapshot = AutoRecordTraceLog.snapshot();
    expect(snapshot, hasLength(AutoRecordTraceLog.maxEvents));
    expect(snapshot.first.detail, 'i=1',
        reason: 'i=0 must have been dropped to make room for i=100');
    expect(snapshot.last.detail, 'i=100',
        reason: 'the newest event must remain at the tail');
  });

  test('clear() empties the ring', () {
    AutoRecordTraceLog.add(AutoRecordEventKind.coordinatorStarted);
    AutoRecordTraceLog.add(AutoRecordEventKind.adapterConnected);
    expect(AutoRecordTraceLog.snapshot(), hasLength(2));

    AutoRecordTraceLog.clear();
    expect(AutoRecordTraceLog.snapshot(), isEmpty);
  });

  test('custom clock is honoured exactly, not DateTime.now()', () {
    final DateTime fixed = DateTime.utc(2024, 1, 15, 9, 30, 0);
    AutoRecordTraceLog.add(
      AutoRecordEventKind.tripStarted,
      clock: () => fixed,
    );
    final AutoRecordEvent event = AutoRecordTraceLog.snapshot().single;
    expect(event.timestamp, fixed,
        reason: 'a test seam clock must not be ignored');
  });

  test('mirrors entry to BreadcrumbCollector with the auto_record: prefix',
      () {
    AutoRecordTraceLog.add(
      AutoRecordEventKind.adapterConnected,
      mac: 'AA:BB:CC:DD:EE:FF',
    );
    final Breadcrumb crumb = BreadcrumbCollector.snapshot().last;
    expect(crumb.action, 'auto_record:adapterConnected');
    expect(crumb.detail, isNotNull);
    expect(crumb.detail, contains('mac=AA:BB:CC:DD:EE:FF'));
  });

  test('mirror collapses null mac and null detail to a null breadcrumb detail',
      () {
    // The coordinator emits some kinds (e.g. coordinatorStopped) with
    // mac alone and no detail. The mirror should not crash on null
    // inputs and the breadcrumb should not contain literal "null".
    AutoRecordTraceLog.add(AutoRecordEventKind.coordinatorStopped);
    final Breadcrumb crumb = BreadcrumbCollector.snapshot().last;
    expect(crumb.action, 'auto_record:coordinatorStopped');
    expect(crumb.detail, isNull,
        reason: 'breadcrumbs must collapse to null when neither mac nor '
            'detail is provided');
  });

  test('mirror joins mac and detail in the breadcrumb', () {
    AutoRecordTraceLog.add(
      AutoRecordEventKind.speedSampleSupraThreshold,
      mac: 'AA:BB:CC:DD:EE:FF',
      detail: 'speed=12.3 kmh, count=2/3',
    );
    final Breadcrumb crumb = BreadcrumbCollector.snapshot().last;
    expect(crumb.action, 'auto_record:speedSampleSupraThreshold');
    expect(crumb.detail, contains('mac=AA:BB:CC:DD:EE:FF'));
    expect(crumb.detail, contains('speed=12.3 kmh'));
  });
}
