import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#923 phase 1): the design-system
/// contract must exist and must mention every canonical widget the
/// epic promises to build.
///
/// Phases 2+ will flesh out each widget and add real implementation
/// tests. This scan only guards the document itself — so an accidental
/// empty commit, a rename, or a typo in a widget name surfaces on CI
/// instead of on reviewer eyeballs.
void main() {
  test(
    'docs/design/DESIGN_SYSTEM.md exists and mentions PageScaffold + '
    'SectionHeader + SectionCard + SettingsMenuTile + TabSwitcher',
    () {
      final file = File('docs/design/DESIGN_SYSTEM.md');
      expect(
        file.existsSync(),
        isTrue,
        reason:
            'docs/design/DESIGN_SYSTEM.md must exist — it is the design-'
            'system contract referenced by every canonical widget in '
            'lib/core/widgets/ and by the static scans landing in phase N.',
      );
      final content = file.readAsStringSync();
      for (final widget in const [
        'PageScaffold',
        'SectionHeader',
        'SectionCard',
        'SettingsMenuTile',
        'TabSwitcher',
      ]) {
        expect(
          content,
          contains(widget),
          reason:
              'DESIGN_SYSTEM.md must document $widget — the epic promises '
              'it as a canonical widget and later phases will cite this '
              'doc as the spec.',
        );
      }
    },
  );
}
