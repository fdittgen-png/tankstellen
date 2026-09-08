// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

import 'design_system_scan.dart';

/// Ratchet (#3986, Epic #3953): inline `textTheme.titleMedium /
/// titleLarge / headlineSmall` reads in `presentation/widgets/`.
///
/// `no_inline_title_theme_test.dart` covers `presentation/screens/` only,
/// on the theory that widgets hold value displays rather than headings.
/// The visual grammar (#3948) gave every role its own name — `AppText`
/// type roles for values, `SectionHeader` for headings — so an inline
/// title-theme read in a widget is now always one of those two written
/// by hand. 106 of them survive in widgets.
///
/// Decrease-only baseline; lower it in the PR that migrates the sites.
void main() {
  final re = RegExp(r'textTheme\.(titleMedium|titleLarge|headlineSmall)\b');

  test('matcher fidelity: finds the three title roles only', () {
    expectMatcherFidelity(
      re,
      '''
      theme.textTheme.titleMedium      // 1
      Theme.of(c).textTheme.titleLarge // 2
      textTheme.headlineSmall          // 3
      textTheme.titleSmall             // not one of the three
      textTheme.bodyMedium             // not one of the three
      AppText.display                  // the sanctioned role
      ''',
      3,
    );
  });

  test(
      'inline title-theme reads in lib/features/**/presentation/widgets/ '
      'do not grow (#3986)', () {
    final offenders = scanPresentation(re, dirs: {'widgets'});
    expectRatchet(
      offenders,
      baseline: _baseline,
      rule: 'Inline textTheme.title* / headlineSmall in presentation/widgets',
      fix: 'Use AppText roles (lib/core/theme/app_text.dart) for values '
          'and SectionHeader for headings',
      issue: '#3986',
    );
  });
}

/// Baseline as of 2026-09-08 (#3986). Only ever decreases; target 0.
const _baseline = 106;
