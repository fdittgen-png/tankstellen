// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan guard (#2350): no handwritten Dart file in shared `lib/`
/// code may branch on `Platform.isIOS`, `Platform.isAndroid`,
/// `Platform.isMacOS`, `Platform.isLinux`, or `Platform.isWindows`
/// outside the designated allowed locations.
///
/// **Why:** The plugin-pattern rule requires platform branching to be
/// isolated in `impl/` directories or in platform-specific wrapper
/// files (files with `ios_` / `android_` in their name). Inline
/// `Platform.isXxx` in shared code couples the shared layer to the
/// runtime platform, making unit-testing and future platform additions
/// harder.
///
/// **Allowed locations (no scan):**
/// - Any file inside an `impl/` sub-directory.
/// - Files whose base name contains `ios_`, `android_`, `_ios`, or
///   `_android` (i.e. already platform-scoped wrapper files).
/// - Files in the explicit [_allowedPlatformWrappers] set that perform
///   platform dispatch by design but are not yet named with the
///   ios/android convention.
///
/// **Grandfathered set:** Files that were already violating the rule
/// when the guard landed. The set may only **shrink** — remove a path
/// once the inline check is eliminated; never add one.
///
/// Legacy clean-up tracked by epic #2332.
void main() {
  // Files whose name or location makes them legitimate platform
  // wrappers even without ios_/android_ in the name. These are
  // exempted from the scan entirely.
  const allowedPlatformWrappers = <String>{
    'lib/features/consumption/data/obd2/obd2_permissions.dart',
  };

  // Files already violating the rule when the guard landed (#2350).
  // Debt — remove each once the inline Platform check is refactored.
  // This set may only SHRINK; target is 0. NEVER add an entry here.
  const grandfathered = <String>{
    'lib/core/background/background_price_fetcher_provider.dart',
    'lib/core/feedback/github_issue_reporter/error_reporter_context.dart',
    'lib/core/sharing/public_file_exporter.dart',
    'lib/core/telemetry/collectors/device_info_collector.dart',
    'lib/features/consumption/presentation/widgets/obd2_adapter_picker.dart',
    'lib/features/widget/data/home_widget_service.dart',
  };

  // Regex that matches an actual (non-comment) Platform.isXxx call.
  // We strip single-line comments before matching to avoid false
  // positives from doc comments that mention the API.
  final platformCheckPattern = RegExp(r'\bPlatform\.is[A-Z][a-zA-Z]+');

  bool isAllowed(String path) {
    // Normalise separators so the checks work on Windows too.
    final p = path.replaceAll(r'\', '/');
    // 1. impl/ sub-directory
    if (p.contains('/impl/')) return true;
    // 2. Platform-scoped filename convention
    final base = p.split('/').last;
    if (base.startsWith('ios_') ||
        base.startsWith('android_') ||
        base.contains('_ios.dart') ||
        base.contains('_android.dart')) {
      return true;
    }
    // 3. Explicit platform-wrapper allow-list
    if (allowedPlatformWrappers.contains(p)) return true;
    return false;
  }

  bool isScanned(String path) {
    if (!path.endsWith('.dart')) return false;
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      return false;
    }
    if (path.startsWith('lib/l10n/')) return false;
    if (isAllowed(path)) return false;
    return true;
  }

  // Strip `// …` single-line comments from a source line so that
  // doc comments mentioning Platform.isIOS do not count as violations.
  String stripLineComment(String line) {
    final idx = line.indexOf('//');
    return idx < 0 ? line : line.substring(0, idx);
  }

  test('no inline Platform.isXxx check outside impl/ or platform wrappers'
      ' (#2350)', () {
    final violations = <String>[];
    final stillViolating = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!isScanned(path)) continue;

      final lines = entity.readAsLinesSync();
      var fileHasViolation = false;
      for (var i = 0; i < lines.length; i++) {
        final code = stripLineComment(lines[i]);
        if (platformCheckPattern.hasMatch(code)) {
          fileHasViolation = true;
          if (!grandfathered.contains(path)) {
            violations.add('$path:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      if (fileHasViolation && grandfathered.contains(path)) {
        stillViolating.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Inline Platform.isXxx found in shared code outside impl/ or '
          'platform-wrapper files. Refactor behind a plugin interface in '
          'an impl/ directory instead.\n\nNew violations:\n'
          '${violations.join('\n')}',
    );

    // Ratchet: once a grandfathered file no longer contains inline
    // Platform checks it must be removed from the set so the debt
    // baseline stays honest.
    final staleBaseline = grandfathered.difference(stillViolating);
    expect(
      staleBaseline,
      isEmpty,
      reason:
          'These files no longer contain inline Platform checks — remove '
          'them from the `grandfathered` set in this test:\n'
          '${staleBaseline.join('\n')}',
    );
  });
}
