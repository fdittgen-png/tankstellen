import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#1103): every `catch (e)` block in `lib/`
/// must capture the stack trace as `catch (e, st)` so `Sentry`,
/// `TraceRecorder.record`, and `debugPrint` triage have a usable trace.
///
/// Without `, st` Dart synthesises an empty stack at the throw point and
/// crash reports become anonymous strings (`PlatformException`, `RangeError`,
/// `StateError`) with no callsite. Adding the second positional makes
/// every catch self-diagnosing.
///
/// Escape hatch: a catch where capturing the stack is genuinely useless
/// (typically catches that just `rethrow;` — Dart preserves the stack
/// across `rethrow`) can opt out with `// ignore: catch_no_st` on the
/// same line as the catch keyword OR on the line directly above it.
/// Use sparingly; the default expectation is `catch (e, st)`.
///
/// Generated files (`.g.dart`, `.freezed.dart`) are not scanned — they
/// don't follow handwritten conventions.
void main() {
  test('every catch (e) in lib/ captures stack trace (#1103)', () {
    final offenders = <String>[];

    // Matches `catch (foo) {` — single named identifier, no comma.
    // `catch (_) {` (silent catch) is the responsibility of
    // `no_silent_catch_test.dart` and is excluded here. The first char of
    // the variable must be a letter (we use `[A-Za-z]` rather than `\w`
    // because `\w` includes the underscore).
    // Allows `on Type catch (e)` because we anchor on `catch (`.
    final singleArgCatch = RegExp(
      r'catch\s*\(\s*[A-Za-z]\w*\s*\)\s*\{',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Skip generated files — they don't follow handwritten conventions.
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }

      final src = entity.readAsStringSync();
      final lines = src.split('\n');
      for (final m in singleArgCatch.allMatches(src)) {
        final lineIdx = src.substring(0, m.start).split('\n').length - 1;
        final thisLine = lineIdx >= 0 && lineIdx < lines.length
            ? lines[lineIdx]
            : '';
        final prevLine = lineIdx > 0 ? lines[lineIdx - 1] : '';
        if (thisLine.contains('// ignore: catch_no_st') ||
            prevLine.trim().contains('// ignore: catch_no_st')) {
          continue;
        }
        offenders.add('${entity.path}:${lineIdx + 1}  ${m.group(0)}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Every `catch (e)` must capture the stack trace as `catch (e, st)` '
          'so Sentry / TraceRecorder.record / debugPrint output is '
          'diagnosable. Add `, st` to the signature and pipe `st` to the '
          'logger. For genuine opt-out cases (rethrow-only blocks), '
          'add `// ignore: catch_no_st` on or directly above the catch.\n'
          'Offending sites:\n${offenders.join("\n")}',
    );
  });
}
