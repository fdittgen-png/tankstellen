// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// Applies the libre / F-Droid dependency overrides (epic #3473) by copying
// `pubspec_overrides.fdroid.yaml` -> `pubspec_overrides.yaml`. Run this BEFORE
// `flutter pub get` in the fdroid build ONLY (the fdroiddata recipe prebuild +
// .github/workflows/fdroid.yml); Play + iOS builds must NOT run it, so they
// keep the real GMS-tied plugins.
//
// `pubspec_overrides.yaml` is gitignored (a generated artifact); the committed
// source of truth is `pubspec_overrides.fdroid.yaml`.
//
// Usage:  dart run tool/apply_fdroid_overrides.dart

import 'dart:io';

void main() {
  final src = File('pubspec_overrides.fdroid.yaml');
  if (!src.existsSync()) {
    stderr.writeln(
      'ERROR: pubspec_overrides.fdroid.yaml not found — run from the repo root.',
    );
    exit(1);
  }
  File('pubspec_overrides.yaml').writeAsStringSync(src.readAsStringSync());
  stdout.writeln(
    'Applied fdroid dependency overrides -> pubspec_overrides.yaml '
    '(run `flutter pub get` next).',
  );
}
