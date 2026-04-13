import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// Pins the severity of the safety lints elevated in issue #422.
///
/// If anyone downgrades these back to `info` (or removes them) the test
/// fails before the change can land. This is the "wall of info messages"
/// guard called for in the audit.
void main() {
  late YamlMap analysisOptions;

  setUpAll(() {
    final file = File('analysis_options.yaml');
    expect(file.existsSync(), isTrue,
        reason: 'analysis_options.yaml must exist at project root');
    analysisOptions = loadYaml(file.readAsStringSync()) as YamlMap;
  });

  group('safety lints are enforced at error severity', () {
    /// Lints that must be `error` so the analyzer hard-fails on them.
    const requiredErrorSeverity = {
      'use_build_context_synchronously',
      'unawaited_futures',
      'cancel_subscriptions',
      'close_sinks',
      'prefer_const_constructors',
    };

    for (final lint in requiredErrorSeverity) {
      test('$lint is set to error', () {
        final analyzer = analysisOptions['analyzer'] as YamlMap;
        final errors = analyzer['errors'] as YamlMap;
        expect(
          errors[lint],
          equals('error'),
          reason:
              '$lint must stay at error severity (issue #422). Downgrading '
              'this lint reintroduces an entire class of bugs the audit '
              'flagged: data races, unmount crashes, leaked subscriptions.',
        );
      });
    }

    test('linter section still lists every safety lint', () {
      final linter = analysisOptions['linter'] as YamlMap;
      final rules = linter['rules'] as YamlList;
      const expected = {
        'use_build_context_synchronously',
        'unawaited_futures',
        'cancel_subscriptions',
        'close_sinks',
      };
      for (final lint in expected) {
        expect(
          rules,
          contains(lint),
          reason: '$lint must be enabled in the linter rules list',
        );
      }
    });
  });
}
