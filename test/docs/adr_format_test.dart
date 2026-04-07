import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture Decision Records', () {
    late Directory adrDir;
    late List<File> adrFiles;

    setUpAll(() {
      adrDir = Directory('docs/decisions');
      expect(adrDir.existsSync(), isTrue,
          reason: 'docs/decisions/ directory must exist');

      adrFiles = adrDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md') && !f.path.endsWith('README.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    });

    test('README.md exists with index table', () {
      final readme = File('docs/decisions/README.md');
      expect(readme.existsSync(), isTrue,
          reason: 'README.md must exist in docs/decisions/');

      final content = readme.readAsStringSync();
      expect(content, contains('## Index'),
          reason: 'README must contain an Index section');
      expect(content, contains('| #'),
          reason: 'README must contain an index table');
    });

    test('at least 7 ADR files exist', () {
      expect(adrFiles.length, greaterThanOrEqualTo(7),
          reason: 'Issue #73 requires at least 7 ADRs');
    });

    test('ADR filenames follow 0000-kebab-case.md pattern', () {
      final pattern = RegExp(r'^\d{4}-[a-z0-9]+(-[a-z0-9]+)*\.md$');
      for (final file in adrFiles) {
        final name = file.uri.pathSegments.last;
        expect(pattern.hasMatch(name), isTrue,
            reason: '$name does not match 0000-kebab-case.md pattern');
      }
    });

    test('each ADR has a title as the first heading', () {
      for (final file in adrFiles) {
        final content = file.readAsStringSync();
        final name = file.uri.pathSegments.last;
        expect(content, matches(RegExp(r'^# ADR \d{4}:')),
            reason: '$name must start with "# ADR NNNN: <title>"');
      }
    });

    test('each ADR has a Status field', () {
      for (final file in adrFiles) {
        final content = file.readAsStringSync();
        final name = file.uri.pathSegments.last;
        expect(
          content,
          matches(RegExp(
              r'\*\*Status:\*\*\s+(Proposed|Accepted|Deprecated|Superseded)')),
          reason: '$name must have a valid Status field',
        );
      }
    });

    test('each ADR has a Date field in YYYY-MM-DD format', () {
      final datePattern = RegExp(r'\*\*Date:\*\*\s+\d{4}-\d{2}-\d{2}');
      for (final file in adrFiles) {
        final content = file.readAsStringSync();
        final name = file.uri.pathSegments.last;
        expect(datePattern.hasMatch(content), isTrue,
            reason: '$name must have a Date field in YYYY-MM-DD format');
      }
    });

    test('each ADR has all required sections', () {
      const requiredSections = [
        '## Context',
        '## Decision',
        '## Consequences',
        '## Alternatives Considered',
      ];

      for (final file in adrFiles) {
        final content = file.readAsStringSync();
        final name = file.uri.pathSegments.last;
        for (final section in requiredSections) {
          expect(content, contains(section),
              reason: '$name must contain "$section" section');
        }
      }
    });

    test('README index lists all ADR files', () {
      final readme = File('docs/decisions/README.md').readAsStringSync();
      for (final file in adrFiles) {
        // Extract the 4-digit number from the filename
        final name = file.uri.pathSegments.last;
        final number = name.substring(0, 4);
        expect(readme, contains('| $number'),
            reason: 'README index must list ADR $number');
      }
    });
  });
}
