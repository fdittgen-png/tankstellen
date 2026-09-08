// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

import 'design_system_scan.dart';

/// Ratchet (#3986, Epic #3953): hard `fontSize:` in feature presentation
/// code — screens AND widgets.
///
/// A literal `fontSize: 12` is a size that ignores the user's text-size
/// setting: `TextStyle(fontSize: n)` is not scaled by `MediaQuery
/// .textScaler` the way a theme role is, so the one place a user asked for
/// bigger text is the one place it stays small. The worst case is the
/// driving-mode screen (hard 12/14/20/24), the surface built entirely
/// around glanceability. Nothing scanned for this before #3986.
///
/// The sanctioned path is a type role — `AppText.*` or `textTheme.*` —
/// which scales. `fontSize` inside `lib/core/theme/` (where the scale is
/// DEFINED) is out of scope by construction: this walks features only.
///
/// Decrease-only baseline; lower it in the PR that migrates the sites.
void main() {
  final re = RegExp(r'\bfontSize:');

  test('matcher fidelity: finds fontSize: and not lookalikes', () {
    expectMatcherFidelity(
      re,
      '''
      TextStyle(fontSize: 12)            // 1
      style: const TextStyle( fontSize:  // 2
      final minFontSize = 8;             // identifier, not the named arg
      fontSizeFactor: 1.2,               // different arg
      ''',
      2,
    );
  });

  test(
      'hard fontSize: in lib/features/**/presentation/{screens,widgets}/ '
      'does not grow (#3986)', () {
    final offenders = scanPresentation(re, dirs: {'screens', 'widgets'});
    expectRatchet(
      offenders,
      baseline: _baseline,
      rule: 'Hard fontSize: in feature presentation code',
      fix: 'Use a type role (AppText.* / textTheme.*) so the size follows '
          'the text-scale setting',
      issue: '#3986',
    );
  });
}

/// Baseline as of 2026-09-08 (#3986). Only ever decreases; target 0.
const _baseline = 83;
