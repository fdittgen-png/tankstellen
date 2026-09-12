// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

    test('#4110 — storage marks its SUB-phases, from inside HiveBoxes', () {
      // The single `hive_init` mark this file used to require was the
      // problem: it owned 8,855 ms of an 8,891 ms cold start in the
      // 2026-09-12 field export and could say nothing about which of the
      // four kinds of work inside it was responsible. The marks moved to
      // where the work is.
      expect(startupSource, isNot(contains("mark('hive_init')")),
          reason: 'one label over four kinds of work is what #4110 is '
              'about; re-adding it would hide the sub-phases behind it');
      final hiveSource =
          File('lib/core/storage/hive_boxes.dart').readAsStringSync();
      for (final phase in [
        'hive_dir',
        'hive_cipher',
        'hive_migrate',
        'hive_open',
        'hive_schema',
      ]) {
        expect(hiveSource, contains("StartupTimer.instance.mark('$phase')"),
            reason: 'Missing storage sub-phase marker: $phase');
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
