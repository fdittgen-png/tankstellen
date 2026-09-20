// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4217 / #4211 carry one explicit exclusion: "no sound, voice control,
// spoken notifications or audio UX". A string is how such a feature
// would first appear — a "Read aloud" switch label ships before the
// plumbing does — so the fleet copy is scanned for the vocabulary.
// ADR 0025's wording rules are checked here too, because the fleet
// fragments are the first place they bind.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The three fleet-onboarding fragments (#4217) — English, German and
/// the hand-written French.
const _fragments = <String>[
  'lib/l10n/_fragments/fleet_onboarding_en.arb',
  'lib/l10n/_fragments/fleet_onboarding_de.arb',
  'lib/l10n/_fragments/fleet_onboarding_fr.arb',
];

Map<String, String> _translatable(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: 'missing fragment: $path');
  final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final e in raw.entries)
      if (!e.key.startsWith('@') && e.value is String)
        e.key: e.value as String,
  };
}

void main() {
  group('fleet onboarding copy (#4217)', () {
    // Whole words only, matched against the key name AND the value in
    // every locale — `Button` must not read as the German `Ton`.
    final audioVocabulary = RegExp(
      r'\b(audio|voice|vocal|spoken|speak|speech|sound|aloud|tts|'
      r'sprachsteuerung|sprachausgabe|sprachbefehl|vorlesen|ansage|ton|'
      r'vocale|parl[ée]|son|annonce)\b',
      caseSensitive: false,
    );

    test('no audio / voice key or sentence exists anywhere in the fleet '
        'fragments — #4211 excludes it outright', () {
      final hits = <String>[];
      for (final path in _fragments) {
        _translatable(path).forEach((key, value) {
          for (final m in audioVocabulary.allMatches('$key $value')) {
            hits.add('$path: $key (${m.group(0)})');
          }
        });
      }
      expect(hits, isEmpty,
          reason: 'Epic #4211: no sound, voice control, spoken '
              'notification or audio UX may be introduced for fleet '
              'functionality. Remove the key, do not reword it.');
    });

    test('the three locales declare exactly the same keys', () {
      final en = _translatable(_fragments[0]).keys.toSet();
      for (final path in _fragments.skip(1)) {
        expect(_translatable(path).keys.toSet(), en,
            reason: '$path diverges from the English fragment');
      }
      expect(en, isNotEmpty);
    });

    test('French is hand-written, not the English string copied over '
        '(the wizard is a French user\'s first impression, #495)', () {
      final en = _translatable(_fragments[0]);
      final fr = _translatable(_fragments[2]);
      final untranslated = [
        for (final key in en.keys)
          if (en[key] == fr[key]) key,
      ];
      expect(untranslated, isEmpty);
    });

    test('no fleet sentence claims a tax or accounting status the '
        'deployment has not configured (ADR 0025 wording rule 2)', () {
      const forbidden = <String>[
        'deductible',
        'tax-compliant',
        'certified',
        'absetzbar',
        'steuerkonform',
        'déductible',
        'certifié',
      ];
      final hits = <String>[];
      for (final path in _fragments) {
        _translatable(path).forEach((key, value) {
          for (final word in forbidden) {
            if (value.toLowerCase().contains(word)) {
              hits.add('$path: $key ($word)');
            }
          }
        });
      }
      expect(hits, isEmpty);
    });
  });
}
