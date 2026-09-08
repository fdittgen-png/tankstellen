// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4007 — the two things the help surface must get right, and the one
// it must not get wrong.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/help/api.dart';

void main() {
  group('the guide a reader gets', () {
    test('a wiki language reads its own guide', () {
      for (final language in helpLocales) {
        expect(helpAssetFor(language), 'assets/help/$language.md');
        expect(helpAnchorAssetFor(language),
            'assets/help/$language.anchors.json');
      }
    });

    test('a language the wiki does not carry falls back to English', () {
      // The app speaks 23 languages; the wiki carries seven. The other
      // sixteen must read something rather than nothing — English is
      // what they get on GitHub today.
      for (final language in ['bg', 'cs', 'el', 'ja', 'pl', 'sv', 'zz']) {
        expect(helpAssetFor(language), 'assets/help/en.md',
            reason: '$language has no guide of its own and must fall back');
        expect(helpAnchorAssetFor(language), 'assets/help/en.anchors.json');
      }
    });

    test('the fallback is English, never empty', () {
      // The failure this rules out: an unknown language producing
      // `assets/help/.md`, which loads nothing and renders a blank
      // screen that looks like a broken guide rather than a missing
      // translation.
      expect(helpAssetFor(''), 'assets/help/en.md');
    });
  });
}
