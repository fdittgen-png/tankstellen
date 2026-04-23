import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan regression test (#589 / #590 / #593): every brand asset
/// that lives under `assets/` and is referenced by the app's build
/// configuration MUST be covered by `docs/design/ASSET_SPEC.md`.
///
/// The rule is intentionally narrow — the spec is a generator-ready
/// contract for the drop-in-shield branding, not a catch-all index of
/// every file in `assets/`. We scan for files that look like brand
/// artefacts (png/svg/jpg in the top-level `assets/` directory) and
/// verify the spec mentions each filename at least once.
///
/// Rationale: if a designer adds `assets/new_hero.png` and wires it into
/// the app without updating ASSET_SPEC, we lose the invariant that every
/// brand asset has a documented generator prompt. This scan catches that
/// drift at test time.
void main() {
  test('ASSET_SPEC.md exists', () {
    final spec = File('docs/design/ASSET_SPEC.md');
    expect(spec.existsSync(), isTrue,
        reason: 'docs/design/ASSET_SPEC.md must exist — it is the '
            'production-generation contract for every brand asset.');
  });

  test('ASSET_SPEC.md references every brand asset in assets/', () {
    final spec = File('docs/design/ASSET_SPEC.md');
    if (!spec.existsSync()) {
      fail('docs/design/ASSET_SPEC.md missing — see preceding test.');
    }
    final specText = spec.readAsStringSync();

    // Scan the top-level assets/ directory for image files. We skip
    // subdirectories (e.g. assets/receipt_overrides/) because they hold
    // data fixtures, not brand assets.
    final assetsDir = Directory('assets');
    if (!assetsDir.existsSync()) {
      fail('assets/ directory missing — cannot verify spec coverage.');
    }

    final brandExtensions = {'.png', '.svg', '.jpg', '.jpeg', '.webp'};
    final missing = <String>[];

    for (final entity in assetsDir.listSync(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      final ext = dot >= 0 ? name.substring(dot).toLowerCase() : '';
      if (!brandExtensions.contains(ext)) continue;

      if (!specText.contains(name)) {
        missing.add(name);
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'Every brand asset under assets/ must be referenced by name at '
          'least once in docs/design/ASSET_SPEC.md so the generator has a '
          'target path. Missing:\n${missing.join("\n")}',
    );
  });
}
