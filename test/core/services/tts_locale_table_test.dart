// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/impl/flutter_tts_announcement_service.dart';

/// #4127 — every shipped language must map to a REAL BCP-47 tag.
///
/// The fallback is `'<code>-<CODE>'`, which is right for `it-IT`,
/// `pl-PL`, `hu-HU` and a dozen more — and silently wrong wherever the
/// language code is not also the country code. Slovenian shipped as
/// `sl-SL` for as long as the fallback existed. No engine has that
/// locale, so `setLanguage` failed, the failure was swallowed, and every
/// Slovenian user got the device voice reading Slovenian text.
///
/// A table is the only thing that catches this class: the code is
/// correct-looking, analyses clean, and fails only on a device set to
/// one of the affected languages.
void main() {
  /// Language code → the country subtag its voice actually uses.
  /// Deliberately spelled out rather than derived — deriving it is the
  /// bug.
  const expectedRegion = <String, String>{
    'en': 'US', 'de': 'DE', 'fr': 'FR', 'it': 'IT', 'es': 'ES',
    'nl': 'NL', 'pt': 'PT', 'da': 'DK', 'sv': 'SE', 'fi': 'FI',
    'nb': 'NO', 'pl': 'PL', 'cs': 'CZ', 'sk': 'SK', 'hu': 'HU',
    'ro': 'RO', 'bg': 'BG', 'hr': 'HR', 'sl': 'SI', 'lt': 'LT',
    'lv': 'LV', 'et': 'EE', 'el': 'GR',
  };

  test('every shipped language maps to a real locale', () {
    for (final language in AppLanguages.all) {
      final tag = FlutterTtsAnnouncementService.ttsLocaleFor(language.code);
      final expected = expectedRegion[language.code];
      expect(expected, isNotNull,
          reason: '${language.code} is shipped but this table does not say '
              'which region its voice uses — add it rather than trusting '
              'the <code>-<CODE> fallback');
      expect(tag, '${language.code}-$expected',
          reason: 'the voice tag for ${language.code} must be '
              '${language.code}-$expected');
    }
  });

  test('Slovenian is sl-SI, never sl-SL', () {
    // The specific regression, named so it cannot come back quietly.
    expect(FlutterTtsAnnouncementService.ttsLocaleFor('sl'), 'sl-SI');
  });

  test('the tag is well-formed for every shipped language', () {
    final wellFormed = RegExp(r'^[a-z]{2}-[A-Z]{2}$');
    for (final language in AppLanguages.all) {
      expect(FlutterTtsAnnouncementService.ttsLocaleFor(language.code),
          matches(wellFormed),
          reason: '${language.code} produced a malformed tag');
    }
  });

  test('the mapping is case-insensitive on input', () {
    expect(FlutterTtsAnnouncementService.ttsLocaleFor('FR'), 'fr-FR');
    expect(FlutterTtsAnnouncementService.ttsLocaleFor('Sl'), 'sl-SI');
  });
}
