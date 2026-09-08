// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Shared walker for the design-system ratchets (#3986, Epic #3953).
///
/// The three original design-system scans (`no_raw_card_in_features`,
/// `no_inline_title_theme`, `no_raw_appbar_in_features`) each carry their
/// own copy of the same file walk and only look at `presentation/screens/`.
/// That left `presentation/widgets/` — where the cards actually live —
/// unscanned, so every screen passed while its cards did not. The four
/// widened ratchets share this walker so the scope is stated once.
///
/// Not a `_test.dart` file on purpose: `flutter test` only runs files with
/// that suffix, so this is a plain helper library.
///
/// ## Ratchet contract
/// Each ratchet pins a **decrease-only** numeric baseline (CLAUDE.md, same
/// rule as `no_hardcoded_ui_strings_test.dart`). Going above it fails the
/// build; fixing sites means lowering the constant in the same PR. The
/// target is always 0.
///
/// ## Parse-fidelity self-check (#2348 lesson)
/// A ratchet that quietly stops matching reads as "0 offenders — clean".
/// Every ratchet therefore also runs its regex over an inline fixture with a
/// known count via [expectMatcherFidelity]; if the matcher drifts, that
/// test fails loudly instead of the baseline silently going green.

/// Every `.dart` file under `lib/features/*/presentation/<dir>/` for each
/// dir in [dirs], excluding generated files, as POSIX paths.
Iterable<String> presentationFiles(Set<String> dirs) sync* {
  final root = Directory('lib/features');
  if (!root.existsSync()) return;
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart') ||
        entity.path.endsWith('.freezed.dart')) {
      continue;
    }
    final posix = entity.path.replaceAll('\\', '/');
    if (dirs.any((d) => posix.contains('/presentation/$d/'))) yield posix;
  }
}

/// Every match of [re] in the files from [presentationFiles], as
/// `path:line  <matched text>`, skipping paths in [allowlist] (suffix
/// match, like the original scans).
List<String> scanPresentation(
  RegExp re, {
  required Set<String> dirs,
  Set<String> allowlist = const {},
}) {
  final offenders = <String>[];
  for (final path in presentationFiles(dirs)) {
    if (allowlist.any(path.endsWith)) continue;
    final src = File(path).readAsStringSync();
    for (final m in re.allMatches(src)) {
      final line = src.substring(0, m.start).split('\n').length;
      offenders.add('$path:$line  ${m.group(0)}');
    }
  }
  return offenders;
}

/// Asserts [re] finds exactly [expected] matches in [fixture]. Guards
/// against a matcher that silently stops matching (#2348).
void expectMatcherFidelity(RegExp re, String fixture, int expected) {
  final found = re.allMatches(fixture).length;
  expect(
    found,
    expected,
    reason: 'the matcher found $found of $expected known sites in the '
        'fixture — the scan would report a false green on real code',
  );
}

/// Decrease-only baseline assertion with the standard failure message.
void expectRatchet(
  List<String> offenders, {
  required int baseline,
  required String rule,
  required String fix,
  required String issue,
}) {
  expect(
    offenders.length,
    lessThanOrEqualTo(baseline),
    reason: '$rule: ${offenders.length} sites (baseline $baseline, '
        'decrease-only). $fix — see docs/design/DESIGN_SYSTEM.md, $issue.\n'
        'Offending sites:\n${offenders.join("\n")}',
  );
}
