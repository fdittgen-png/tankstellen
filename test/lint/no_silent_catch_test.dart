import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#565): no `catch (_) {}` (silent) or
/// `catch (e) {}` (stored-but-unused) blocks in `lib/`. Silent catches
/// hide root causes — replace with at least `debugPrint('context: $e')`
/// or route through `TraceRecorder.recordError(e)`.
///
/// The scan uses a simple regex that tolerates optional whitespace and
/// the Dart `on T catch` form. False positives should add a minimal log
/// line rather than relaxing this scan.
void main() {
  test('no silent catch blocks in lib/ (#565)', () {
    final offenders = <String>[];

    // Matches `catch (_) {}` and `catch (e) {}` (with optional whitespace).
    // Does NOT match catches that contain a statement — the body has to be
    // literally empty (whitespace/newlines only) to qualify as "silent".
    final silent = RegExp(
      r'catch\s*\(\s*\w+\s*\)\s*\{\s*\}',
    );

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Skip generated files — they don't follow handwritten conventions.
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) continue;

      final src = entity.readAsStringSync();
      for (final m in silent.allMatches(src)) {
        final line = src.substring(0, m.start).split('\n').length;
        offenders.add('${entity.path}:$line  ${m.group(0)}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Silent catch hides the root cause. Replace with at least '
          '`debugPrint("context: \$e")` so the reason ends up in logs. '
          'Offending sites:\n${offenders.join("\n")}',
    );
  });
}
