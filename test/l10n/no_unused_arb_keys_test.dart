// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet — no unused ARB keys (#3743).
///
/// Every translatable key in `lib/l10n/app_en.arb` must be referenced
/// somewhere in the codebase. An unreferenced key is dead weight times 24:
/// the autofill pipeline (#2335) fans every English key out to all shipped
/// locales plus the `en_XA` pseudo-locale, so one dead key means ~24 dead
/// translations that translators keep reviewing and CI keeps checking.
/// The 2026-08 audit found 183 such keys (#3743) and removed them.
///
/// ## Detection (conservative by construction)
///
/// A key counts as *used* when its name appears as an identifier-shaped
/// token in **any** `.dart` file under `lib/`, `test/`,
/// `integration_test/` or `tool/` — excluding `lib/l10n/` itself (the
/// generated `app_localizations_*.dart` getters and the ARB files would
/// otherwise mark every key alive). Tokenizing the whole file means:
///
///   * `l10n.myKey` getter access counts (the normal case);
///   * a key named inside a string literal counts too — so tests that pin
///     specific keys (e.g. `test/l10n/localization_completeness_test.dart`
///     asserting `contains('appTitle')`) keep those keys alive;
///   * comments count. That is deliberate over-approximation: this gate
///     must never flag a live key, and a key kept alive only by a comment
///     will be caught by the next manual audit, not by CI red.
///
/// Dart has no reflective getter access (no `dart:mirrors` in Flutter), so
/// a key can only be consumed through its generated getter — which names
/// the key as an identifier and is therefore always visible to this scan.
/// The `featureLabel_*` / `featureDescription_*` / `featureBlockedEnable_*`
/// families are resolved via explicit `switch` statements in
/// `lib/features/profile/presentation/widgets/feature_management/feature_localization.dart`,
/// not via string-built lookups — audited for #3743.
///
/// ## Allowlist — dynamically-derived keys
///
/// If a key family is ever looked up through a string-keyed map or any
/// mechanism this scan cannot see, add its prefix (or exact name) here
/// with a comment explaining the lookup site. Audited empty as of #3743.
const List<String> kDynamicallyLookedUpPrefixes = <String>[];

/// Baseline of known-unused keys. Per the house ratchet convention this
/// list may only ever **shrink** — the target is the empty list, and the
/// #3743 cleanup reached it. Never add to it to "make the gate pass";
/// either reference the new key or do not add it to the ARB.
const Set<String> kUnusedKeyBaseline = <String>{};

void main() {
  test('every app_en.arb key is referenced outside lib/l10n (#3743)', () {
    final arbFile = File('lib/l10n/app_en.arb');
    expect(arbFile.existsSync(), isTrue,
        reason: 'lib/l10n/app_en.arb must exist — run from the repo root');

    final arb = jsonDecode(arbFile.readAsStringSync()) as Map<String, dynamic>;
    final keys = arb.keys.where((k) => !k.startsWith('@')).toSet();
    expect(keys, isNotEmpty);

    // Collect every identifier-shaped token from the scanned sources.
    final identifier = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');
    final l10nDir = '${Directory.current.path}/lib/l10n';
    final tokens = <String>{};
    for (final root in const ['lib', 'test', 'integration_test', 'tool']) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.absolute.path.startsWith(l10nDir)) continue;
        final content = entity.readAsStringSync();
        for (final m in identifier.allMatches(content)) {
          tokens.add(m.group(0)!);
        }
      }
    }

    final unused = keys
        .where((k) => !tokens.contains(k))
        .where(
          (k) => !kDynamicallyLookedUpPrefixes.any(k.startsWith),
        )
        .toSet();

    final newViolations = unused.difference(kUnusedKeyBaseline);
    expect(
      newViolations,
      isEmpty,
      reason: 'Unused ARB key(s) detected — each one fans out to 24 dead '
          'translations. Either reference the key from Dart code or remove '
          'it from its lib/l10n/_fragments/ fragment (en + de) and rerun '
          'the ARB pipeline (CLAUDE.md HARD RULE #4). If the key is looked '
          'up dynamically, add its prefix to kDynamicallyLookedUpPrefixes '
          'with a comment naming the lookup site. Never grow '
          'kUnusedKeyBaseline. New unused keys:\n  '
          '${(newViolations.toList()..sort()).join('\n  ')}',
    );

    // Ratchet: entries that got cleaned up must leave the baseline.
    final fixed = kUnusedKeyBaseline.difference(unused);
    expect(
      fixed,
      isEmpty,
      reason: 'These baselined keys are no longer unused — remove them from '
          'kUnusedKeyBaseline so the ratchet only ever tightens:\n  '
          '${(fixed.toList()..sort()).join('\n  ')}',
    );
  });
}
