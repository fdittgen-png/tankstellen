import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Tests that verify the prefer_const_constructors lint rule is enforced
/// at error level in analysis_options.yaml, ensuring no regressions.
void main() {
  late YamlMap analysisOptions;

  setUpAll(() {
    final file = File('analysis_options.yaml');
    expect(file.existsSync(), isTrue,
        reason: 'analysis_options.yaml must exist at project root');
    analysisOptions = loadYaml(file.readAsStringSync()) as YamlMap;
  });

  group('prefer_const_constructors lint enforcement', () {
    test('is configured at error severity in analyzer errors', () {
      final analyzer = analysisOptions['analyzer'] as YamlMap;
      final errors = analyzer['errors'] as YamlMap;
      expect(errors['prefer_const_constructors'], equals('error'),
          reason:
              'prefer_const_constructors must be enforced at error level');
    });

    test('is listed in linter rules', () {
      final linter = analysisOptions['linter'] as YamlMap;
      final rules = linter['rules'] as YamlList;
      expect(rules, contains('prefer_const_constructors'),
          reason:
              'prefer_const_constructors must be in the linter rules list');
    });

    test('companion const rules are also configured', () {
      final analyzer = analysisOptions['analyzer'] as YamlMap;
      final errors = analyzer['errors'] as YamlMap;
      // These companion rules should exist (at any severity)
      expect(errors.containsKey('prefer_const_declarations'), isTrue,
          reason: 'prefer_const_declarations should be configured');
      expect(
          errors.containsKey('prefer_const_literals_to_create_immutables'),
          isTrue,
          reason:
              'prefer_const_literals_to_create_immutables should be configured');
    });
  });

  group('const constructor usage in codebase', () {
    test('lib/ files use const constructors (spot check)', () {
      // Spot-check that key files use const where expected
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      // Count const keyword usage in lib/ — should be well above 1000
      var constCount = 0;
      for (final file in libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.endsWith('.freezed.dart'))) {
        final content = file.readAsStringSync();
        constCount +=
            RegExp(r'\bconst\b').allMatches(content).length;
      }

      // The codebase should maintain a high const usage count
      expect(constCount, greaterThan(1000),
          reason:
              'Codebase should have >1000 const usages in lib/ (found $constCount)');
    });

    test('test fixtures use const constructors', () {
      final fixturesDir = Directory('test/fixtures');
      expect(fixturesDir.existsSync(), isTrue);

      for (final file in fixturesDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final content = file.readAsStringSync();
        final constCount =
            RegExp(r'\bconst\b').allMatches(content).length;
        // Fixture files with Station/LatLng objects should use const
        expect(constCount, greaterThan(0),
            reason:
                '${file.path} should use const constructors in fixtures');
      }
    });
  });
}
