// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// #4347 — the selector's fallbacks must stay safe: a PR is only as tested
// as the tests the selector picks, and the pre-merge coverage policy judges
// exactly those tests' coverage. In process on the real tree (one scan
// shared by every case), never via `dart run` (#4177).

import 'package:flutter_test/flutter_test.dart';

import '../../tool/test_selector.dart';

void main() {
  late DependencyGraph graph;
  setUpAll(() => graph = DependencyGraph.scan());

  Set<String> select(List<String> changed) =>
      selectForChangedPaths(changed, graph: graph).tests;

  test('a changed PART file selects the tests of its library', () {
    // Before #4347 only `import` edges were followed and this selected
    // no test at all: parts are never imported.
    final tests = select(const [
      'lib/features/obd2/data/session/trip_recording_controller_emit.dart',
    ]);
    expect(
        tests,
        contains('test/features/obd2/data/'
            'trip_recording_controller_emit_summary_test.dart'));
  });

  test('parts and every conditional import branch are edges; exports are '
      'deliberately not (measured cost, see the selector header)', () {
    final edges = extractDependencies('lib/features/x/api.dart', """
export 'data/a.dart';
import 'data/b.dart' if (dart.library.io) 'data/b_io.dart';
part 'api_part.dart';
import 'package:tankstellen/core/c.dart';
import 'package:flutter/widgets.dart';
""");
    expect(edges, {
      'lib/features/x/data/b.dart',
      'lib/features/x/data/b_io.dart',
      'lib/features/x/api_part.dart',
      'lib/core/c.dart',
    });
  });

  test('a changed test selects itself, a changed helper its dependents', () {
    const own = 'test/features/obd2/data/'
        'trip_recording_controller_emit_summary_test.dart';
    expect(select(const [own]), contains(own));
    expect(select(const ['test/helpers/silence_error_logger.dart']),
        contains(own));
  });

  test('a changed fixture selects the tests that read it', () {
    expect(
        select(const ['test/fixtures/lu_lustat_diesel_slice.json']),
        contains('test/features/station_services/luxembourg/'
            'lustat_contract_test.dart'));
  });

  test('unreferenced runtime data and shared test infrastructure fall back '
      'to the full suite', () {
    for (final path in const [
      'test/fixtures/nobody_reads_this_${4347}.json',
      'dart_test.yaml',
      'test/flutter_test_config.dart',
      'assets/tanksync_config.json',
    ]) {
      final decision = selectForChangedPaths([path], graph: graph);
      expect(decision.fullSuite, isTrue, reason: path);
      expect(decision.reason, path);
    }
  });

  test('shell tests under test/scripts select no Flutter test', () {
    final decision = selectForChangedPaths(
        const ['test/scripts/check_coverage_test.sh'],
        graph: graph);
    expect(decision.fullSuite, isFalse);
    expect(decision.tests, selectTests(const {}, graph: graph).alwaysRun);
  });

  test('coverage reachability sees files loaded only through parts', () {
    expect(
        graph.libFilesReachedByTests(),
        contains('lib/features/obd2/data/session/'
            'trip_recording_controller_emit.dart'));
  });
}
