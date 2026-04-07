import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies that main.dart has startup timing instrumentation in place.
/// This test reads the source file to ensure timing markers are not
/// accidentally removed during refactoring.
void main() {
  late String mainSource;

  setUpAll(() {
    final file = File('lib/main.dart');
    expect(file.existsSync(), isTrue, reason: 'lib/main.dart must exist');
    mainSource = file.readAsStringSync();
  });

  group('Startup instrumentation', () {
    test('main.dart imports StartupTimer', () {
      expect(mainSource, contains("import 'core/perf/startup_timer.dart'"));
    });

    test('main.dart starts the timer before initialization', () {
      expect(mainSource, contains('StartupTimer.instance.start()'));
    });

    test('main.dart marks key milestones', () {
      // Verify at least the critical milestones are present
      for (final milestone in [
        'binding',
        'hive_init',
        'storage_ready',
        'services_init',
        'first_frame',
      ]) {
        expect(
          mainSource,
          contains("StartupTimer.instance.mark('$milestone')"),
          reason: 'Missing milestone marker: $milestone',
        );
      }
    });

    test('main.dart calls finish()', () {
      expect(mainSource, contains('StartupTimer.instance.finish()'));
    });

    test('timer start comes before finish in source', () {
      final startIndex = mainSource.indexOf('StartupTimer.instance.start()');
      final finishIndex = mainSource.indexOf('StartupTimer.instance.finish()');
      expect(startIndex, lessThan(finishIndex));
    });
  });
}
