import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#923 final): feature presentation files
/// MUST use `TabSwitcher` (`lib/core/widgets/tab_switcher.dart`) or
/// Material `SegmentedButton` instead of the raw Material `TabBar`
/// constructor.
///
/// `TabSwitcher` enforces the canonical chip-style segmented selector
/// the design system uses for in-page navigation. Reaching for the raw
/// `TabBar` constructor reintroduces the underline-style tab the epic
/// (#923) specifically deprecated.
///
/// The regex `(?<![A-Za-z0-9_])TabBar\s*\(` matches the constructor
/// call only — `TabBarView(`, `TabBarTheme(`, and identifiers like
/// `MyTabBar(` are excluded by the trailing `\s*\(` (which requires
/// the next non-whitespace token to be `(`) and the leading negative
/// look-behind.
void main() {
  test(
    'no raw `TabBar(...)` in lib/features/**/presentation (#923 final)',
    () {
      const allowlist = <String>{};

      // `TabBar(` only — TabBarView is excluded because the `View`
      // characters force `\s*\(` to fail.
      final re = RegExp(r'(?<![A-Za-z0-9_])TabBar\s*\(');

      final offenders = <String>[];
      for (final entity
          in Directory('lib/features').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')) {
          continue;
        }
        final posix = entity.path.replaceAll('\\', '/');
        final inScope = posix.contains('/presentation/screens/') ||
            posix.contains('/presentation/widgets/');
        if (!inScope) continue;
        if (allowlist.any(posix.endsWith)) continue;

        final src = entity.readAsStringSync();
        for (final m in re.allMatches(src)) {
          final line = src.substring(0, m.start).split('\n').length;
          offenders.add('$posix:$line  ${m.group(0)}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Raw TabBar found. Use TabSwitcher '
            '(lib/core/widgets/tab_switcher.dart) or SegmentedButton. '
            'See #923. Offending sites:\n${offenders.join("\n")}',
      );
    },
  );
}
