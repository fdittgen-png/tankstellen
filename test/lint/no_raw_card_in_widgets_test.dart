// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';

import 'design_system_scan.dart';

/// Ratchet (#3986, Epic #3953): raw Material `Card(...)` in
/// `lib/features/*/presentation/widgets/`.
///
/// `no_raw_card_in_features_test.dart` forbids the bare constructor in
/// `presentation/screens/` and deliberately stopped there, on the theory
/// that `*_card.dart` primitives in `widgets/` "are cards by contract".
/// Since the visual grammar (#3948) that is no longer true: the sanctioned
/// surfaces are `PrimaryCard` / `PanelCard` (`lib/core/widgets/`), and a
/// widget on raw `Card` gets neither the surface ramp nor the dark-theme
/// tint. Widgets are where 78 of the 84 remaining raw cards live — so
/// "clean by lint" was a statement about the screens only.
///
/// Decrease-only baseline; lower it in the PR that migrates the sites.
void main() {
  // Token boundary before `Card` so `StationCard(`, `PanelCard(` etc. are
  // not matched — identical to the screens scan.
  final re = RegExp(r'(?<![A-Za-z0-9_])Card\s*\(');

  test('matcher fidelity: finds raw Card( and ignores subclasses', () {
    expectMatcherFidelity(
      re,
      '''
      return Card(child: x);          // 1
      final w = Card (               // 2 — whitespace before paren
        child: PanelCard(child: y),  // subclass: not a match
      );
      SectionCard(child: z);         // subclass: not a match
      _StatCard(child: z);           // subclass: not a match
      ''',
      2,
    );
  });

  test(
      'raw Card( in lib/features/**/presentation/widgets/ does not grow '
      '(#3986)', () {
    final offenders = scanPresentation(re, dirs: {'widgets'});
    expectRatchet(
      offenders,
      baseline: _baseline,
      rule: 'Raw Card() in presentation/widgets',
      fix: 'Use PrimaryCard or PanelCard (lib/core/widgets/)',
      issue: '#3986',
    );
  });
}

/// Baseline as of 2026-09-08 (#3986). Only ever decreases; target 0.
const _baseline = 46;
