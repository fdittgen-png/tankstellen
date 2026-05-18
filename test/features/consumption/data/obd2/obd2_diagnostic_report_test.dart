import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_diagnostic_report.dart';

/// Coverage for [formatObd2DiagnosticReport] — the pure plain-text
/// formatter behind the exportable OBD2 diagnostic log (#1920).
///
/// Asserts the report shape (header + one line per event), the
/// per-event timestamp format, MAC redaction (PII), and the empty
/// list case.
void main() {
  final DateTime generatedAt = DateTime.utc(2024, 1, 15, 9, 30, 0);

  test('empty event list produces a clear "no events" line', () {
    final String report = formatObd2DiagnosticReport(
      const <AutoRecordEvent>[],
      generatedAt: generatedAt,
    );
    expect(report, contains('2024-01-15 09:30:00'));
    expect(report.toLowerCase(), contains('no events'));
  });

  test('header carries the generated-at timestamp', () {
    final String report = formatObd2DiagnosticReport(
      <AutoRecordEvent>[
        AutoRecordEvent(
          timestamp: DateTime.utc(2024, 1, 15, 9, 30, 1, 123),
          kind: AutoRecordEventKind.connectStarted,
        ),
      ],
      generatedAt: generatedAt,
    );
    final List<String> lines = report.trimRight().split('\n');
    expect(lines.first, contains('2024-01-15 09:30:00'));
  });

  test('one line per event in the kind/mac/detail shape', () {
    final String report = formatObd2DiagnosticReport(
      <AutoRecordEvent>[
        AutoRecordEvent(
          timestamp: DateTime.utc(2024, 1, 15, 9, 30, 1, 123),
          kind: AutoRecordEventKind.connectStarted,
          mac: 'AA:BB:CC:DD:EE:FF',
        ),
        AutoRecordEvent(
          timestamp: DateTime.utc(2024, 1, 15, 9, 30, 3, 456),
          kind: AutoRecordEventKind.connectSucceeded,
          mac: 'AA:BB:CC:DD:EE:FF',
          detail: 'ELM327 v1.5',
        ),
      ],
      generatedAt: generatedAt,
    );
    final List<String> lines = report.trimRight().split('\n');
    // header + 2 event lines.
    expect(lines, hasLength(3));
    expect(lines[1], startsWith('[09:30:01.123]'));
    expect(lines[1], contains('connectStarted'));
    expect(lines[2], startsWith('[09:30:03.456]'));
    expect(lines[2], contains('connectSucceeded'));
    expect(lines[2], contains('ELM327 v1.5'),
        reason: 'the firmware detail must survive into the report');
  });

  test('MAC is redacted to its last four characters', () {
    final String report = formatObd2DiagnosticReport(
      <AutoRecordEvent>[
        AutoRecordEvent(
          timestamp: DateTime.utc(2024, 1, 15, 9, 30, 1),
          kind: AutoRecordEventKind.connectStarted,
          mac: 'AA:BB:CC:DD:EE:FF',
        ),
      ],
      generatedAt: generatedAt,
    );
    // The full MAC is PII and must never appear verbatim.
    expect(report, isNot(contains('AA:BB:CC:DD:EE:FF')));
    // Only the trailing four characters survive, the rest masked.
    expect(report, contains('E:FF'));
    expect(report, isNot(contains('AA:BB')));
    expect(report, contains('·'),
        reason: 'redacted characters are shown as the middle dot');
  });

  test('events without mac or detail render the bare kind', () {
    final String report = formatObd2DiagnosticReport(
      <AutoRecordEvent>[
        AutoRecordEvent(
          timestamp: DateTime.utc(2024, 1, 15, 9, 30, 5),
          kind: AutoRecordEventKind.dropEscalatedToVisible,
        ),
      ],
      generatedAt: generatedAt,
    );
    final List<String> lines = report.trimRight().split('\n');
    expect(lines[1], '[09:30:05.000]  dropEscalatedToVisible');
  });
}
