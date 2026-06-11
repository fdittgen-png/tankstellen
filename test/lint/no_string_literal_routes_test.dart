// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan guard (#3135): no navigation call site in `lib/` may pass a
/// string LITERAL to `go` / `push` / `pushReplacement` / `replace` /
/// `goNamed` / `pushNamed`.
///
/// Every router path lives once in `lib/core/navigation/app_routes.dart` —
/// payload-free routes navigate with a `RoutePaths` constant, data-carrying
/// routes (path parameter or `extra`) through their typed `AppRoute`
/// subclass. A string literal in a call site re-introduces the stringly
/// duplication this rule killed (63 raw literals + untyped `extra` Maps
/// before #3135) and silently de-types the payload contract between the
/// caller and the route builder.
///
/// Route TABLE declarations (`GoRoute(path: ...)`) are not matched — they
/// also use the `RoutePaths` constants, but the deep-link contract tests
/// in `test/app/routes/` pin the literal VALUES (widgets / notifications
/// depend on `/station/:id`, `/ev-station/:id`, `/trip-recording`).
///
/// Dynamic locations (e.g. `context.go(ref.read(...))`) are fine — the rule
/// only bans literals at the call site. The target is and must stay **0**:
/// never add a baseline.
void main() {
  test('no string-literal route paths in go/push call sites (#3135)', () {
    // Matches `.go('`, `.push("`, `.push<void>('`, `.pushReplacement('`,
    // `.goNamed('`, `.pushNamed('` — including a line break between the
    // opening parenthesis and the literal.
    final call = RegExp(
      r'''\.(go|push|pushReplacement|replace|goNamed|pushNamed)(<[^>(]*>)?\(\s*['"]''',
    );

    final violations = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.dart') &&
            !f.path.endsWith('.g.dart') &&
            !f.path.endsWith('.freezed.dart') &&
            !f.path.contains('lib/l10n/'));

    for (final file in files) {
      // Strip line comments so a commented-out example can't trip the scan.
      // Naive per-line stripping is safe here: a route literal never
      // legitimately contains `//`.
      final source = file
          .readAsLinesSync()
          .map((l) => l.replaceFirst(RegExp(r'//.*'), ''))
          .join('\n');
      for (final m in call.allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
        violations.add('${file.path}:$line  .${m.group(1)}(<string literal>)');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'String-literal route paths are banned (#3135). Navigate with '
          'a RoutePaths constant or a typed AppRoute subclass from '
          'lib/core/navigation/app_routes.dart instead:\n'
          '${violations.join('\n')}',
    );
  });
}
