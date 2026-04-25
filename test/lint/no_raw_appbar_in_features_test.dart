import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#923 final): feature presentation files
/// MUST use `PageScaffold` (`lib/core/widgets/page_scaffold.dart`) instead
/// of a raw `Scaffold(appBar: AppBar(...))` pattern.
///
/// The design-system epic (#923) migrated every feature screen across
/// phases 3a–3t. This scan locks the migration in: a future PR that
/// reaches for the bare `AppBar` constructor inside
/// `lib/features/**/presentation/` trips the test and is forced back
/// onto `PageScaffold` (which already centralises title/leading/actions
/// styling, system-nav padding, and bottom-sheet helpers).
///
/// Allowlist: `lib/features/station_detail/presentation/screens/
/// station_detail_screen.dart` is the one screen still on raw `AppBar`.
/// It uses a `Hero`-flighted custom title widget, which `PageScaffold`
/// cannot express until the `title: Widget` variant lands (deferred,
/// tracked separately under #923-deferred). When that variant ships,
/// remove the entry below.
void main() {
  test(
    'no raw `appBar: AppBar(...)` in lib/features/**/presentation '
    '(#923 final)',
    () {
      // Posix paths so the allowlist matches on every host OS.
      // Deferred — needs PageScaffold `title: Widget` variant for the
      // Hero-flighted station-name title. See #923-deferred.
      const allowlist = <String>{
        'lib/features/station_detail/presentation/screens/station_detail_screen.dart',
      };

      // Match `appBar: AppBar(` with optional whitespace. Paired
      // constructor-name boundary: an identifier char before `AppBar`
      // would mean a subclass like `MyAppBar` and is allowed.
      final re = RegExp(r'appBar:\s*(?<![A-Za-z0-9_])AppBar\b');

      final offenders = <String>[];
      for (final entity
          in Directory('lib/features').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')) {
          continue;
        }
        final posix = entity.path.replaceAll('\\', '/');
        // Scope: only presentation/screens/* and presentation/widgets/*
        // — providers/models/data files have no UI.
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
        reason: 'Raw AppBar found in feature presentation file. Use '
            'PageScaffold (lib/core/widgets/page_scaffold.dart) instead. '
            'See docs/design/DESIGN_SYSTEM.md and #923. Offending sites:\n'
            '${offenders.join("\n")}',
      );
    },
  );
}
