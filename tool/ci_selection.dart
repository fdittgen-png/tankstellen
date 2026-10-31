// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// SDK-only adapter: one dependency scan for both selection and coverage.
import 'dart:convert';
import 'dart:io';

import 'coverage_policy.dart'
    show coverageTests, isMaintainedSource, parseChangedLines;
import 'test_selector.dart';

void main(List<String> args) {
  final changed = (jsonDecode(File(args[0]).readAsStringSync()) as List)
      .cast<String>();
  final graph = DependencyGraph.scan(followExports: true);
  final decision = selectForChangedPaths(changed, graph: graph);
  final diff = File(args[1]).readAsStringSync();
  final lines = parseChangedLines(diff)
    ..removeWhere((path, _) => !isMaintainedSource(path));
  stdout.writeln(
    jsonEncode({
      'tests': (decision.fullSuite ? graph.tests : decision.tests.toList())
        ..sort(),
      'coverage_tests': coverageTests(lines.keys, graph),
      'applicable': lines.isNotEmpty,
      'reason': decision.fullSuite
          ? 'full: ${decision.reason}'
          : 'affected + always-run',
    }),
  );
}
