// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan ratchet (#2349): every `lib/` boundary that *documents*
/// a "never throws" contract must be backed by a `*_test.dart` that
/// actually injects a fault and asserts the call returns normally.
///
/// ## Why this exists
/// `IsolateErrorSpool.enqueue` documented "never throws" but
/// `TraceUploader.getConfig()` was read OUTSIDE the try, leaking a
/// TypeError on schema drift (#2311); the orphaned-completer leak in
/// the spool (#2321) was caught by instrumentation, not a test. A
/// docstring promise is worthless without a fault-path test — this lint
/// makes the promise testable and prevents a *new* documented
/// never-throws boundary from shipping with no fault-injection test.
///
/// ## What counts as a never-throws docstring
/// Any `///` doc line in `lib/` matching `never throws`, `never thrown`,
/// `never re-throws`, `can never throw`, or `never throw` (case- and
/// hyphen-insensitive). Generated files (`.g.dart`, `.freezed.dart`)
/// are skipped.
///
/// ## What counts as a fault-injection test
/// A sibling test file named `<stem>_test.dart` (same basename as the
/// lib file) that contains at least one fault-injection idiom:
/// `returnsNormally`, `, completes)` / `completes,`, `throwsA`,
/// `thenThrow`, `Future.error` / `Future<…>.error`, `completeError`,
/// a `boxFactory` swap, a `setMockMethodCallHandler` mock, an `onError`
/// stream-error injection, or a `cancelError`.
///
/// ## Ratchet-down only
/// [_grandfathered] lists the documented boundaries that lack such a
/// test *today*. The set may only ever **shrink**: removing a path from
/// it (by writing its fault-path test) is the goal; adding one is
/// forbidden — a brand-new "never throws" boundary must arrive with its
/// fault-path test. The test fails if:
///   - a non-grandfathered boundary has no fault-path test (regression /
///     new boundary without a test), OR
///   - a grandfathered entry is stale (it now HAS a fault-path test, so
///     it must be removed from the allow-set — keeps the ratchet honest).
void main() {
  // Boundaries that document "never throws" but have no fault-injection
  // test yet. RELATIVE, forward-slash paths from the repo root.
  //
  // ⚠️ This set may only SHRINK. Do not add entries. To remove an entry,
  // write a fault-path test in the matching `<stem>_test.dart`.
  const grandfathered = <String>{
    'lib/core/services/radar/corridor_location_cache.dart',
    'lib/core/sync/trip_shares_sync.dart',
    'lib/features/obd2/data/adapter_capability.dart',
    'lib/features/obd2/data/auto_trip_coordinator.dart',
    'lib/features/obd2/data/broken_map_detector.dart',
    'lib/features/obd2/data/obd2_cache_openers.dart',
    'lib/features/obd2/data/obd2_service.dart',
    'lib/features/consumption/data/ocr/ocr_image_preprocessor.dart',
    'lib/features/consumption/data/ocr/seven_segment_recognizer.dart',
    'lib/features/consumption/providers/consumption_providers.dart',
    'lib/features/vehicle/data/obd2_vin_reader.dart',
    'lib/features/vehicle/data/vin_adapter_pair_auto_populator.dart',
    // #3234 — the never-throws adapter-persist / auto-population boundaries
    // moved verbatim from edit_vehicle_screen.dart into its `_VehicleEditActions`
    // part mixin; the grandfather entry follows the code (a file move, not a new
    // untested boundary — net count unchanged).
    'lib/features/vehicle/presentation/screens/edit_vehicle_screen_actions.dart',
  };

  // Matches a `///` doc comment line that documents a never-throws
  // contract. Case-insensitive; tolerates `never throws` / `never-throws`
  // / `never thrown` / `never re-throws` / `never throw`.
  final neverThrowsDoc = RegExp(
    r'///.*never[\s-]?(re-?)?throws?n?',
    caseSensitive: false,
  );

  // Fault-injection idioms a fault-path test should contain.
  final faultIdiom = RegExp(
    r'returnsNormally'
    r'|completes,'
    r'|,\s*completes\)'
    r'|throwsA'
    r'|thenThrow'
    r'|Future(<[^>]*>)?\.error'
    r'|completeError'
    r'|boxFactory'
    r'|setMockMethodCallHandler'
    r'|onError'
    r'|cancelError',
  );

  String norm(String p) => p.replaceAll('\\', '/');

  /// Every lib/ file that documents a never-throws contract.
  Set<String> documentedBoundaries() {
    final out = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final p = norm(entity.path);
      if (p.endsWith('.g.dart') || p.endsWith('.freezed.dart')) continue;
      final src = entity.readAsStringSync();
      // Only look at lines that are doc comments — avoids matching a
      // never-throws phrase inside a normal `//` comment or a string.
      final hasDoc =
          src.split('\n').any((line) => neverThrowsDoc.hasMatch(line));
      if (hasDoc) out.add(p);
    }
    return out;
  }

  /// True when a sibling `<stem>_test.dart` exists with a fault idiom.
  bool hasFaultPathTest(String libPath) {
    final stem = libPath.split('/').last.replaceAll('.dart', '');
    final wanted = '${stem}_test.dart';
    for (final entity in Directory('test').listSync(recursive: true)) {
      if (entity is! File || !norm(entity.path).endsWith(wanted)) continue;
      if (faultIdiom.hasMatch(entity.readAsStringSync())) return true;
    }
    return false;
  }

  test('the never-throws docstring scanner finds the known boundaries', () {
    // Sanity guard: if this drops to zero the scanner regex or the cwd
    // is wrong and every other assertion below would vacuously pass.
    final boundaries = documentedBoundaries();
    expect(
      boundaries,
      contains('lib/core/telemetry/storage/isolate_error_spool.dart'),
      reason: 'the spool is the canonical documented never-throws boundary; '
          'if the scanner misses it, the regex or cwd is wrong.',
    );
    expect(
      boundaries,
      contains('lib/core/telemetry/upload/trace_uploader.dart'),
    );
    expect(boundaries.length, greaterThanOrEqualTo(10),
        reason: 'expected the full documented set, got ${boundaries.length}');
  });

  test(
      'every documented never-throws boundary has a fault-injection test '
      '(or is grandfathered) — ratchet-down only (#2349)', () {
    final missing = <String>[];
    for (final boundary in documentedBoundaries()) {
      if (hasFaultPathTest(boundary)) continue;
      if (grandfathered.contains(boundary)) continue;
      missing.add(boundary);
    }

    expect(
      missing,
      isEmpty,
      reason: 'These lib/ files DOCUMENT a "never throws" contract but have '
          'no `<stem>_test.dart` that injects a fault and asserts the call '
          'returns normally (e.g. `expectLater(call(), completes)` or '
          '`expect(() => call(), returnsNormally)` after wiring a throwing '
          'dependency). Add the fault-path test, or — only if you cannot — '
          'document why. Do NOT widen the grandfathered allow-set.\n'
          'Uncovered boundaries:\n${missing.join("\n")}',
    );
  });

  test(
      'grandfathered allow-set has no stale entries — write the test, then '
      'remove it from the set (ratchet-down only)', () {
    final stale = <String>[];
    for (final entry in grandfathered) {
      final file = File(entry);
      if (!file.existsSync()) {
        stale.add('$entry  (file no longer exists / moved)');
        continue;
      }
      if (hasFaultPathTest(entry)) {
        stale.add('$entry  (now HAS a fault-path test)');
      }
    }

    expect(
      stale,
      isEmpty,
      reason: 'The never-throws grandfathered allow-set may only shrink. '
          'These entries are stale — a fault-path test now exists (or the '
          'file moved), so the entry must be removed from `grandfathered` '
          'in this test to keep the ratchet honest:\n${stale.join("\n")}',
    );
  });
}
