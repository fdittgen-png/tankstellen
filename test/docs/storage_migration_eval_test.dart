import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies that the storage backend migration evaluation (issue #23)
/// exists and covers the key concepts required by the issue.
///
/// The document lives as ADR 0008 under `docs/decisions/` so it is
/// tracked by git (unlike `docs/analysis/`, which is gitignored).
void main() {
  group('Storage migration evaluation (ADR 0008)', () {
    late String content;

    setUpAll(() {
      final file = File('docs/decisions/0008-storage-migration-eval.md');
      expect(file.existsSync(), isTrue,
          reason: 'ADR 0008 storage migration evaluation must exist');
      content = file.readAsStringSync();
    });

    test('references issue #23', () {
      expect(content, contains('#23'));
    });

    test('references the current Hive version', () {
      expect(content, contains('2.2.3'));
    });

    test('evaluates all three required options', () {
      expect(content, contains('Isar'));
      expect(content, contains('Drift'));
      expect(content, contains('Stay on Hive'));
    });

    test('discusses pros and cons for each option', () {
      // Each option section must contain Pros and Cons bullets.
      expect(content, contains('**Pros**'));
      expect(content, contains('**Cons**'));
    });

    test('covers encryption and isolate concerns', () {
      expect(content.toLowerCase(), contains('encrypt'));
      expect(content.toLowerCase(), contains('isolate'));
    });

    test('covers web support', () {
      expect(content.toLowerCase(), contains('web'));
    });

    test('includes a migration cost estimate table', () {
      expect(content, contains('Migration cost estimate'));
      expect(content, contains('Files touched'));
    });

    test('records an explicit decision with rationale', () {
      expect(content, contains('## Decision'));
      expect(content.toLowerCase(), contains('rationale'));
    });

    test('includes a migration plan for the escape hatch', () {
      expect(content, contains('Migration plan'));
      expect(content, contains('hive_ce'));
    });

    test('links the R-02 risk from risk analysis', () {
      expect(content, contains('R-02'));
    });

    test('is under 500 lines', () {
      final lines = content.split('\n').length;
      expect(lines, lessThan(500),
          reason: 'ADR 0008 should stay concise (< 500 lines)');
    });
  });
}
