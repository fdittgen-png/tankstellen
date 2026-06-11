// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan guard (#2350, extended in #3163): no handwritten Dart
/// file in shared `lib/` code may branch on `Platform.isIOS`,
/// `Platform.isAndroid`, `Platform.isMacOS`, `Platform.isLinux`,
/// `Platform.isWindows` — or on `defaultTargetPlatform` (#3163) —
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

  // Sanctioned `defaultTargetPlatform` dispatch seams (#3163). These
  // files exist to resolve platform-specific behavior by design (BLE
  // transport selection, recording/PiP/auto-record orchestration,
  // platform-resolved onboarding steps) but live outside impl/ and
  // don't carry the ios_/android_ filename convention. Adding an entry
  // requires the same justification as `allowedPlatformWrappers`: the
  // file's *purpose* must be platform dispatch — never add one to
  // silence the guard for an inline branch in shared presentation or
  // business logic (that's exactly the hole #3163 closed).
  const sanctionedDefaultTargetPlatformSeams = <String>{
    'lib/core/location/recording_location_settings.dart',
    'lib/features/consumption/data/obd2/flutter_blue_plus_elm_channel.dart',
    'lib/features/consumption/data/obd2/obd2_connect_by_mac.dart',
    'lib/features/consumption/data/obd2/obd2_connection_service.dart',
    'lib/features/consumption/data/pip_controller.dart',
    'lib/features/consumption/providers/auto_record_orchestrator_factories.dart',
    'lib/features/setup/providers/onboarding_platform_steps_provider.dart',
    // #3169 — the SLC-wake factory seam (no-op off-iOS by design) and the
    // iOS-only best-effort disclosure render gate.
    'lib/core/background/slc_wake_monitor.dart',
    'lib/features/alerts/presentation/widgets/alerts_best_effort_note.dart',
    // #3170 — the Live Activity capability gate (ActivityKit is iOS-only).
    'lib/features/consumption/data/live_activity_controller.dart',
  };

  // Files already violating the rule when the guard landed (#2350).
  // Debt — remove each once the inline Platform check is refactored.
  // This set may only SHRINK; target is 0. NEVER add an entry here.
  const grandfathered = <String>{
    'lib/core/background/background_price_fetcher_provider.dart',
    'lib/core/feedback/github_issue_reporter/error_reporter_context.dart',
    'lib/core/sharing/public_file_exporter.dart',
    'lib/core/telemetry/collectors/device_info_collector.dart',
    // #3168 — obd2_adapter_picker.dart removed: its identity capture moved
    // to the data-layer Obd2AdapterIdentity seam (UUID-shape discriminator,
    // no Platform check).
    'lib/features/widget/data/home_widget_service.dart',
  };

  // Regex that matches an actual (non-comment) Platform.isXxx call.
  // We strip single-line comments before matching to avoid false
  // positives from doc comments that mention the API.
  final platformCheckPattern = RegExp(r'\bPlatform\.is[A-Z][a-zA-Z]+');

  // Foundation's `defaultTargetPlatform` is the same inline-branching
  // hole through a different API (#3163) — it used to be invisible to
  // this guard. `debugDefaultTargetPlatformOverride` (the test seam) is
  // not matched: it is a distinct identifier, so `\b…\b` excludes it.
  final defaultTargetPlatformPattern = RegExp(r'\bdefaultTargetPlatform\b');

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

  test('no inline defaultTargetPlatform check outside impl/, platform '
      'wrappers, or sanctioned dispatch seams (#3163)', () {
    final violations = <String>[];
    final stillUsing = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!isScanned(path)) continue;

      final lines = entity.readAsLinesSync();
      var fileUses = false;
      for (var i = 0; i < lines.length; i++) {
        final code = stripLineComment(lines[i]);
        if (defaultTargetPlatformPattern.hasMatch(code)) {
          fileUses = true;
          if (!sanctionedDefaultTargetPlatformSeams.contains(path)) {
            violations.add('$path:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      if (fileUses && sanctionedDefaultTargetPlatformSeams.contains(path)) {
        stillUsing.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Inline defaultTargetPlatform branching found in shared code '
          '(#3163). Resolve the platform behind a provider or an impl/ '
          'dispatch seam instead (see '
          'onboarding_platform_steps_provider.dart for the pattern).\n\n'
          'New violations:\n${violations.join('\n')}',
    );

    // Ratchet: a seam that no longer uses defaultTargetPlatform must be
    // removed from the set so the allow-list stays honest.
    final staleSeams =
        sanctionedDefaultTargetPlatformSeams.difference(stillUsing);
    expect(
      staleSeams,
      isEmpty,
      reason:
          'These files no longer use defaultTargetPlatform — remove them '
          'from `sanctionedDefaultTargetPlatformSeams`:\n'
          '${staleSeams.join('\n')}',
    );
  });

  // Regression cases for the #3163 hole: pin the patterns so they keep
  // matching real branches and keep ignoring comments / the test seam.
  group('pattern regression (#3163)', () {
    test('defaultTargetPlatform branch is matched', () {
      expect(
        defaultTargetPlatformPattern.hasMatch(
          'final isIos = defaultTargetPlatform == TargetPlatform.iOS;',
        ),
        isTrue,
      );
    });

    test('debugDefaultTargetPlatformOverride (test seam) is not matched',
        () {
      expect(
        defaultTargetPlatformPattern.hasMatch(
          'debugDefaultTargetPlatformOverride = TargetPlatform.iOS;',
        ),
        isFalse,
      );
    });

    test('comment mentions are not matched after stripping', () {
      expect(
        defaultTargetPlatformPattern.hasMatch(
          stripLineComment('// uses defaultTargetPlatform internally'),
        ),
        isFalse,
      );
      expect(
        platformCheckPattern.hasMatch(
          stripLineComment('// Platform.isIOS would be wrong here'),
        ),
        isFalse,
      );
    });

    test('Platform.isXxx branch is still matched', () {
      expect(
        platformCheckPattern.hasMatch('if (Platform.isAndroid) {'),
        isTrue,
      );
    });
  });
}
