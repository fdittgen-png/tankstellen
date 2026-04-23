import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural invariants introduced by issue #795 phase 1 — startup
/// parallelization + post-first-frame deferral of non-critical init.
///
/// These are grep-style source-level assertions (like the existing
/// `app_initializer_test.dart`) because `AppInitializer.run` touches
/// platform plugins (Hive, secure storage, Supabase) that flutter_test
/// cannot instantiate without a real device binding.
///
/// The assertions pin three guarantees:
///
///  1. `HiveStorage.loadApiKey()` and `TraceStorage.init()` run in a
///     single `Future.wait` batch in `_initStorage` — not sequentially.
///     Reverting to `await ... await ...` is the exact regression we're
///     defending against.
///  2. `CommunityConfig.load()` and `_maybeInitTankSync(...)` are not
///     `await`ed in `run()` — they run post-first-frame via
///     `SchedulerBinding.addPostFrameCallback`. A future edit that
///     re-adds `await CommunityConfig.load()` to the run body defeats
///     the whole optimization.
///  3. A reusable `_deferPostFirstFrame` helper exists, wraps work in
///     try/catch, and is backed by `SchedulerBinding.instance` — the
///     only API that reliably fires *after* the first paint.
void main() {
  late String initSource;

  setUpAll(() {
    initSource = File('lib/app/app_initializer.dart').readAsStringSync();
  });

  group('#795 phase 1 — parallelized storage init', () {
    test('_initStorage batches loadApiKey + TraceStorage.init via Future.wait',
        () {
      final body = _extractMethodBody(
        initSource,
        'static Future<void> _initStorage',
      );
      expect(body, isNotNull, reason: '_initStorage method must exist');

      // Must contain a Future.wait containing BOTH load calls.
      final futureWaitIdx = body!.indexOf('Future.wait');
      expect(futureWaitIdx, isNonNegative,
          reason: '_initStorage must parallelize with Future.wait — sequential '
              'awaits are the performance regression #795 guards against');

      // Locate the slice from Future.wait to the next ]); which closes the
      // list literal. Both loader calls must live inside that slice.
      final listEnd = body.indexOf(']', futureWaitIdx);
      expect(listEnd, isNonNegative,
          reason: 'Future.wait must be followed by a list literal');
      final batch = body.substring(futureWaitIdx, listEnd);
      expect(batch, contains('HiveStorage.loadApiKey'),
          reason: 'loadApiKey must be inside the parallel batch');
      expect(batch, contains('TraceStorage.init'),
          reason: 'TraceStorage.init must be inside the parallel batch');
    });

    test('_initStorage no longer awaits loadApiKey and TraceStorage.init '
        'sequentially', () {
      // A regression that reverts to `await HiveStorage.loadApiKey(); '
      // await TraceStorage.init();` (or either of them on its own line
      // awaited after the Future.wait) should fail this test.
      final body = _extractMethodBody(
        initSource,
        'static Future<void> _initStorage',
      );
      expect(body, isNotNull);
      expect(body, isNot(contains('await HiveStorage.loadApiKey()')),
          reason: 'loadApiKey must live inside Future.wait, not as a solo '
              'sequential await');
      expect(body, isNot(contains('await TraceStorage.init()')),
          reason: 'TraceStorage.init must live inside Future.wait, not as a '
              'solo sequential await');
    });
  });

  group('#795 phase 1 — post-first-frame deferral', () {
    test('CommunityConfig.load + _maybeInitTankSync live inside a '
        '_deferPostFirstFrame closure (not on the critical path)', () {
      // Prior to #795 phase 1 the run() body `await`ed both calls on
      // the critical path; that cost ~60–200 ms on cold start even
      // when the user had not opted in to TankSync. The work now lives
      // inside a `_deferPostFirstFrame(() async { ... })` closure.
      //
      // Verified structurally: between each `_deferPostFirstFrame(`
      // opener and its matching `});` closer, we expect at least one
      // closure to mention both CommunityConfig.load and
      // _maybeInitTankSync. A regression that re-extracts the awaits
      // out of that closure and back into `run()` directly will fail
      // this test.
      final body = _extractMethodBody(initSource, 'static Future<void> run');
      expect(body, isNotNull);

      final closures = _extractDeferClosures(body!);
      expect(closures, isNotEmpty,
          reason: 'run() must contain at least one _deferPostFirstFrame '
              'closure');

      final merged = closures.join('\n---\n');
      expect(merged, contains('CommunityConfig.load'),
          reason: 'CommunityConfig.load must be invoked from inside a '
              '_deferPostFirstFrame closure, not directly on the critical '
              'path of run()');
      expect(merged, contains('_maybeInitTankSync'),
          reason: '_maybeInitTankSync must be invoked from inside a '
              '_deferPostFirstFrame closure, not directly on the critical '
              'path of run()');
    });

    test('run() schedules deferral before the pre_run_app marker', () {
      // The deferral call must happen on the run body's critical path,
      // not somewhere irrelevant. Order: _deferPostFirstFrame schedules
      // the work → `pre_run_app` marker → `_launch` runs.
      final body = _extractMethodBody(initSource, 'static Future<void> run');
      expect(body, isNotNull);
      final deferIdx = body!.indexOf('_deferPostFirstFrame');
      final preRunAppIdx = body.indexOf("mark('pre_run_app')");
      expect(deferIdx, isNonNegative);
      expect(preRunAppIdx, isNonNegative);
      expect(deferIdx, lessThan(preRunAppIdx),
          reason: 'deferral must be scheduled before the pre_run_app marker '
              'so the post-frame callback is armed before the framework '
              'starts drawing');
    });

    test('run() schedules TankSync + CommunityConfig via _deferPostFirstFrame',
        () {
      final body = _extractMethodBody(initSource, 'static Future<void> run');
      expect(body, isNotNull);
      expect(body, contains('_deferPostFirstFrame'),
          reason: 'run() must schedule the deferred non-critical inits via '
              '_deferPostFirstFrame');

      // The deferral closure must still reference both targets so the
      // post-frame task actually does the work.
      expect(body, contains('CommunityConfig.load'),
          reason: 'CommunityConfig.load must still be invoked — just '
              'deferred, not deleted');
      expect(body, contains('_maybeInitTankSync'),
          reason: '_maybeInitTankSync must still be invoked — just '
              'deferred, not deleted');
    });

    test('_deferPostFirstFrame uses SchedulerBinding.addPostFrameCallback',
        () {
      final body = _extractMethodBody(
        initSource,
        'static void _deferPostFirstFrame',
      );
      expect(body, isNotNull,
          reason: '_deferPostFirstFrame helper must exist');
      expect(body, contains('SchedulerBinding.instance.addPostFrameCallback'),
          reason: 'scheduleMicrotask runs before the first paint — the hook '
              'must be addPostFrameCallback so the deferred I/O actually '
              'lands after the user sees the UI');
    });

    test('_deferPostFirstFrame catches and logs errors', () {
      // Any failure inside a deferred task must NOT bubble up as an
      // uncaught async error while the user is already interacting with
      // the app — log it and move on.
      final body = _extractMethodBody(
        initSource,
        'static void _deferPostFirstFrame',
      );
      expect(body, isNotNull);
      expect(body, contains('try'),
          reason: 'deferred body must be wrapped in try/catch');
      expect(body, contains('debugPrint'),
          reason: 'deferred-task failures must go through debugPrint with '
              'context (no silent swallowing — #566 static scan enforces it)');
    });
  });

  group('#795 phase 1 — StartupTimer instrumentation preserved', () {
    test('storage_ready marker is still fired AFTER the parallelized batch',
        () {
      // The parallelized Future.wait in _initStorage lands between the
      // `hive_init` marker and the end of the method. The run() body
      // marks `storage_ready` once `_initStorage()` returns, so we pin
      // that `storage_ready` is reported from the run body — not from
      // inside _initStorage (which would mean we forgot to move it
      // when refactoring).
      final runBody =
          _extractMethodBody(initSource, 'static Future<void> run');
      expect(runBody, isNotNull);
      expect(runBody, contains("StartupTimer.instance.mark('storage_ready')"),
          reason: 'storage_ready must be marked from run() so it captures '
              'the real end of phase-2 storage init');
    });

    test('hive_init marker is fired INSIDE _initStorage (not run body)', () {
      // `hive_init` fires right after HiveStorage.init() completes, so
      // the parallelized Future.wait slot that follows hive_init is
      // measurable in the StartupTimer summary.
      final initStorageBody =
          _extractMethodBody(initSource, 'static Future<void> _initStorage');
      expect(initStorageBody, isNotNull);
      expect(initStorageBody,
          contains("StartupTimer.instance.mark('hive_init')"),
          reason: 'hive_init must be marked inside _initStorage, right '
              'after Hive.initFlutter + encrypted-box opens complete — '
              'moving it back out of the method loses the timing point.');
    });
  });
}

/// Extracts every `_deferPostFirstFrame(() async { ... });` closure body
/// from [runBody]. Returns the content strictly between the opening
/// `{` and its matching `}` for each closure.
///
/// The extractor walks brace depth so nested blocks (try/catch inside a
/// closure, inner closures) do not confuse the match. A closure is
/// recognised by the literal prefix `_deferPostFirstFrame(() async {`.
List<String> _extractDeferClosures(String runBody) {
  const opener = '_deferPostFirstFrame(() async {';
  final closures = <String>[];
  var searchStart = 0;
  while (true) {
    final open = runBody.indexOf(opener, searchStart);
    if (open < 0) break;
    final bodyStart = open + opener.length;
    var depth = 1;
    var i = bodyStart;
    for (; i < runBody.length; i++) {
      final ch = runBody[i];
      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) break;
      }
    }
    if (i < runBody.length) {
      closures.add(runBody.substring(bodyStart, i));
      searchStart = i + 1;
    } else {
      break;
    }
  }
  return closures;
}

/// Extracts the body of the first method that starts with [signature].
/// Mirrors the helper in `app_initializer_test.dart` so both files stay
/// symmetric.
String? _extractMethodBody(String source, String signature) {
  final start = source.indexOf(signature);
  if (start < 0) return null;

  var i = source.indexOf('(', start);
  if (i < 0) return null;
  var parenDepth = 0;
  for (; i < source.length; i++) {
    final ch = source[i];
    if (ch == '(') parenDepth++;
    if (ch == ')') {
      parenDepth--;
      if (parenDepth == 0) {
        i++;
        break;
      }
    }
  }
  final braceStart = source.indexOf('{', i);
  if (braceStart < 0) return null;
  var depth = 0;
  for (var j = braceStart; j < source.length; j++) {
    final ch = source[j];
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) return source.substring(braceStart + 1, j);
    }
  }
  return null;
}
