// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/perf/perf_budgets.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_first_frame_boxes.dart';
import 'package:tankstellen/core/storage/hive_open_timing.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4140 — the regression gate on the cold-start path.
///
/// [kColdStartBudget] says a cold start reaches a usable map in 2,500 ms
/// and [kHiveOpenBudget] gives the box opens 400 ms of that. Both numbers
/// were measured against a specific amount of work, and there are exactly
/// two ways to spend the budget without anyone noticing: put another box
/// on the first-frame open batch, or put another `await` in front of
/// `runApp`. This gate makes both of them fail here instead of in a field
/// export three weeks later.
///
/// ## The two halves are not equally strong, and the difference matters
///
/// **The box set is EXECUTED.** `openAll` runs, and the gate compares the
/// boxes it actually opened. #4116 is why: four tests guarded this exact
/// batch by matching its SOURCE TEXT, a bulk rename made the timing
/// helper call itself, and the app failed to start on every cold launch
/// with 16,626 tests green. A gate on this path reads what ran.
///
/// **The pre-first-frame await list is TEXT**, because `AppInitializer.run`
/// ends in `runApp` and touches Hive, secure storage and Supabase — the
/// same reason `app_initializer_phase1_test.dart` gives for its own
/// grep-style assertions. It is therefore a weaker instrument, and it is
/// kept narrow on purpose: it pins the *statements*, not a paraphrase of
/// what they do, so the only way to trip it is to genuinely change the
/// blocking path.
void main() {
  group('the first-frame box set (executed)', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('startup_gate_');
      Hive.init(tmpDir.path);
      HiveOpenTiming.reset();
    });

    tearDown(() async {
      await closeHiveAndDeleteTemp(tmpDir);
    });

    test('is exactly the boxes the budget was measured against',
        () async {
      await HiveFirstFrameBoxes.openAll(null);

      expect(
        HiveOpenTiming.openedBoxes.toSet(),
        _firstFrameBoxBaseline,
        reason: 'The first-frame batch changed.\n\n'
            'Adding a box spends ${kHiveOpenBudget.limit} '
            '${kHiveOpenBudget.unit} that were measured against the '
            'set below, and every millisecond it costs is a millisecond '
            'before the user can read a price '
            '(${kColdStartBudget.limit} ${kColdStartBudget.unit}).\n\n'
            'If the box genuinely gates the first frame: add it here AND '
            're-justify kHiveOpenBudget in lib/core/perf/perf_budgets.dart '
            'with a fresh measurement. If it does not, it belongs in '
            'HiveBoxes.initDeferred — which is where #4110 moved the '
            'national datasets that owned 8,855 ms of an 8,891 ms start.',
      );
    });

    test('every first-frame box is opened exactly once', () async {
      await HiveFirstFrameBoxes.openAll(null);

      final counts = <String, int>{};
      for (final name in HiveOpenTiming.openedBoxes) {
        counts[name] = (counts[name] ?? 0) + 1;
      }
      expect(counts.values, everyElement(1),
          reason: 'a box opened twice in the batch is wasted startup time '
              'that no phase duration would show, because the opens are '
              'parallel and their durations overlap');
    });
  });

  group('the pre-first-frame path (source)', () {
    late List<String> bodyLines;

    setUpAll(() {
      bodyLines = _runBodyLines();
      expect(bodyLines, isNotEmpty,
          reason: 'AppInitializer.run could not be located — this gate '
              'asserts nothing until that is fixed');
    });

    test('blocks on exactly the steps the budget accounts for', () {
      final blocking = [
        for (final line in bodyLines)
          if (_isTopLevelStatement(line) && _mentionsAwait(line)) line.trim(),
      ];

      expect(blocking, _preFirstFrameAwaits,
          reason: 'The set of steps that BLOCK the first frame changed.\n\n'
              'Each one of these is serial time before anything paints, '
              'and ${kColdStartBudget.limit} ${kColdStartBudget.unit} was '
              'measured with these.\n\n'
              'Before adding one, ask what #4110 asked: does the first '
              'frame actually need it, or can it go through '
              '_deferPostFirstFrame? If it must block, update this list '
              'AND re-justify kColdStartBudget with a fresh measurement.');
    });

    test('and does not smuggle one into a nested block', () {
      // The list above only sees statements at the method's own
      // indentation. An `await` inside an `if` body, a loop or a closure
      // would slip past it — so the TOTAL is pinned too. A deferred
      // closure's awaits count here; they are not on the blocking path,
      // but they cannot change without someone looking at this file.
      final total = bodyLines.fold<int>(
          0, (sum, line) => sum + _awaitPattern.allMatches(line).length);

      expect(total, _totalAwaitsInRunBody,
          reason: 'An `await` was added to or removed from '
              'AppInitializer.run somewhere the statement-level list '
              'above cannot see. If it blocks the first frame it belongs '
              'in _preFirstFrameAwaits with a re-justified budget; if it '
              'is inside a _deferPostFirstFrame closure, just update this '
              'count.');
    });
  });
}

/// The boxes `HiveFirstFrameBoxes.openAll` opens, pinned. Exact in both
/// directions: a box leaving the batch is a win, and a win is written
/// down here in the same commit rather than left to be silently re-spent.
final Set<String> _firstFrameBoxBaseline = {
  HiveBoxes.settings,
  HiveBoxes.profiles,
  HiveBoxes.favorites,
  HiveBoxes.cache,
  // #4318 — `priceHistory` left (HiveDeferredUserBoxes) and so did
  // `isolateErrorSpool` (IsolateErrorSpool opens it lazily): a win, locked
  // in. Each remaining box names its route consumer in the contract.
  HiveBoxes.alerts,
  HiveBoxes.featureFlags,
  HiveBoxes.appProfile,
  HiveBoxes.boxSchema,
};

/// The statements in `AppInitializer.run` that the first frame waits for,
/// verbatim and in order.
const List<String> _preFirstFrameAwaits = [
  // #4319 — ONE await: the date formatting, the guarded storage phase and
  // the widget probe used to be three serial awaits; they are now started
  // together and awaited as one dependency graph, whose ordering is
  // EXECUTED by test/app/startup/launch_critical_path_test.dart.
  // #4317 — `await _initServicesInParallel();` left: notifications, the
  // background scheduler and the home-widget answer run post-frame.
  'final container = await LaunchCriticalPath.run(',
];

/// Every `await` in the body, including those inside the post-first-frame
/// closures — the backstop for an await added where [_isTopLevelStatement]
/// cannot see it.
const int _totalAwaitsInRunBody = 8;

final RegExp _awaitPattern = RegExp(r'\bawait\b');

/// A statement at the method body's own indentation (four spaces inside a
/// class member), as opposed to one nested in a block or a closure.
bool _isTopLevelStatement(String line) =>
    line.startsWith('    ') && !line.startsWith('     ');

bool _mentionsAwait(String line) => _awaitPattern.hasMatch(line);

/// `AppInitializer.run`'s body, one line per line, with `//` comments
/// stripped — a comment containing the word `await` is prose, not a step.
List<String> _runBodyLines() {
  final source = File('lib/app/app_initializer.dart').readAsStringSync();
  const signature = 'static Future<void> run({';
  final start = source.indexOf(signature);
  if (start < 0) return const [];

  final braceStart = source.indexOf('{', source.indexOf(')', start));
  if (braceStart < 0) return const [];
  var depth = 0;
  var end = -1;
  for (var i = braceStart; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') {
      depth--;
      if (depth == 0) {
        end = i;
        break;
      }
    }
  }
  if (end < 0) return const [];

  return [
    for (final line in source.substring(braceStart, end).split('\n'))
      line.replaceAll(RegExp(r'//.*$'), '').trimRight(),
  ];
}
