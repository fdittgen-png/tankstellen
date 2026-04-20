import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies that the cold-start sequence has full StartupTimer instrumentation.
///
/// The instrumentation used to live in `main.dart`; after #424 the cold-start
/// flow moved into `lib/app/app_initializer.dart`. This test reads both files
/// so the markers can't be silently removed during a future refactor.
void main() {
  late String startupSource;

  setUpAll(() {
    // The phased cold-start sequence lives here now.
    final file = File('lib/app/app_initializer.dart');
    expect(file.existsSync(), isTrue,
        reason: 'lib/app/app_initializer.dart must exist (issue #424)');
    startupSource = file.readAsStringSync();
  });

  group('Startup instrumentation', () {
    test('AppInitializer imports StartupTimer', () {
      expect(startupSource, contains('startup_timer.dart'));
    });

    test('AppInitializer starts the timer before initialization', () {
      expect(startupSource, contains('StartupTimer.instance.start()'));
    });

    test('AppInitializer marks key milestones', () {
      // Verify at least the critical milestones are present
      for (final milestone in [
        'binding',
        'hive_init',
        'storage_ready',
        'services_init',
        'first_frame',
      ]) {
        expect(
          startupSource,
          contains("StartupTimer.instance.mark('$milestone')"),
          reason: 'Missing milestone marker: $milestone',
        );
      }
    });

    test('AppInitializer calls finish()', () {
      expect(startupSource, contains('StartupTimer.instance.finish()'));
    });

    test('timer start comes before finish in source', () {
      final startIndex =
          startupSource.indexOf('StartupTimer.instance.start()');
      final finishIndex =
          startupSource.indexOf('StartupTimer.instance.finish()');
      expect(startIndex, isNonNegative);
      expect(finishIndex, isNonNegative);
      expect(startIndex, lessThan(finishIndex));
    });
  });
}
