import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#1104): no raw `debugPrint(<exception>)`
/// calls in `lib/`. Errors must go through `errorLogger.log(layer, e, st)`
/// from `lib/core/logging/error_logger.dart` so we have a single PII
/// scrub point, a single sample-rate control, and one place to swap
/// Sentry → Glitchtip.
///
/// What is forbidden:
///   debugPrint(e)
///   debugPrint(error)
///   debugPrint(err)
///   debugPrint(exception)
///   debugPrint(ex)
///
/// What is allowed:
///   - String-interpolated forms like `debugPrint('context: $e')` —
///     these already include surrounding context. They were migrated
///     in #1137 and may be tightened up in a follow-up PR.
///   - `lib/core/logging/` (this is the logger itself).
///   - `tool/` (build scripts; lints don't apply to dev tooling).
///   - Generated files (`.g.dart`, `.freezed.dart`).
///   - A `// ignore: log_raw_debugprint: <reason>` opt-out on the same
///     line or the line directly above the call.
///
/// Failure mode: list every `path:line  matched-text` and tell the
/// caller to migrate to `errorLogger.log(layer, e, st)`.
void main() {
  test(
      'no raw `debugPrint(<exception>)` calls outside lib/core/logging/ (#1104)',
      () {
    final offenders = <String>[];

    // Match `debugPrint(<bare-name>)` where the bare name is one of
    // the conventional exception variables. The trailing character
    // must be `)` or `,` so we don't match `debugPrint(error.message)`
    // or `debugPrint(error_count)`. Whitespace around the identifier
    // is tolerated.
    final raw = RegExp(
      r'debugPrint\(\s*(e|error|err|exception|ex)\s*[\),]',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      // Skip generated files.
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }

      // Skip the logger module itself — it is allowed to fall back to
      // `debugPrint` when its own dependencies (Hive, Riverpod
      // container) are unavailable.
      // Normalise path separators so the check works on Windows.
      final normalisedPath = entity.path.replaceAll('\\', '/');
      if (normalisedPath.contains('lib/core/logging/')) {
        continue;
      }

      final src = entity.readAsStringSync();
      final lines = src.split('\n');
      for (final m in raw.allMatches(src)) {
        final lineIdx = src.substring(0, m.start).split('\n').length - 1;
        final thisLine =
            lineIdx >= 0 && lineIdx < lines.length ? lines[lineIdx] : '';
        final prevLine = lineIdx > 0 ? lines[lineIdx - 1] : '';
        if (thisLine.contains('// ignore: log_raw_debugprint') ||
            prevLine.trim().contains('// ignore: log_raw_debugprint')) {
          continue;
        }
        offenders.add('${entity.path}:${lineIdx + 1}  ${m.group(0)}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Raw `debugPrint(e)` bypasses the unified logging pipeline. '
          'Use `errorLogger.log(ErrorLayer.<layer>, e, st)` from '
          '`lib/core/logging/error_logger.dart` instead so Sentry / '
          'Glitchtip / TraceRecorder all see the error. For the rare '
          'case where this is genuinely correct, add '
          '`// ignore: log_raw_debugprint: <reason>` on or above the '
          'line.\nOffending sites:\n${offenders.join("\n")}',
    );
  });
}
