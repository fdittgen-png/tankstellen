// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

import 'design_system_scan.dart';

/// Ratchet (#3986, Epic #3953): Material `Colors.<named>` literals in
/// feature presentation code — screens AND widgets.
///
/// `Colors.amber`, `Colors.black87`, `Colors.white` bypass both the brand
/// palette and the per-theme surface ramp (docs/design/DESIGN_SYSTEM.md):
/// the same literal is painted in light and dark, so it is wrong in one of
/// them. The sanctioned sources are `Theme.of(context).colorScheme`, the
/// semantic-role table and the price-band ramp.
///
/// `Colors.transparent` is not a colour choice and is not matched. Shade
/// suffixes (`black87`, `white70`, `grey.shade300`) ARE matched — they are
/// the same bypass with a number on it.
///
/// Decrease-only baseline; lower it in the PR that migrates the sites.
void main() {
  final re = RegExp(
    r'\bColors\.'
    r'(red|pink|purple|deepPurple|indigo|blue|lightBlue|cyan|teal|green|'
    r'lightGreen|lime|yellow|amber|orange|deepOrange|brown|grey|blueGrey|'
    r'black|white)\d*\b',
  );

  test('matcher fidelity: named colours and shades, not transparent', () {
    expectMatcherFidelity(
      re,
      '''
      color: Colors.amber,               // 1
      Colors.black87                     // 2 — shade suffix
      Colors.white.withValues(alpha: .5) // 3
      Colors.grey.shade300               // 4
      Colors.transparent                 // not a colour choice
      AppColors.black                    // not Material Colors
      colorScheme.primary                // the sanctioned source
      ''',
      4,
    );
  });

  test(
      'Colors.<named> in lib/features/**/presentation/{screens,widgets}/ '
      'does not grow (#3986)', () {
    final offenders = scanPresentation(re, dirs: {'screens', 'widgets'});
    expectRatchet(
      offenders,
      baseline: _baseline,
      rule: 'Material Colors.<named> literal in feature presentation code',
      fix: 'Use colorScheme / the semantic-role table / the price-band ramp',
      issue: '#3986',
    );
  });
}

/// Baseline as of 2026-09-08 (#3986). Only ever decreases; target 0.
const _baseline = 89;
