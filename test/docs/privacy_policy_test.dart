// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Privacy policy', () {
    late String html;

    setUpAll(() {
      final file = File('docs/privacy-policy/index.html');
      expect(file.existsSync(), isTrue,
          reason: 'Privacy policy HTML file must exist at docs/privacy-policy/index.html');
      html = file.readAsStringSync();
    });

    test('file is non-empty HTML', () {
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('</html>'));
    });

    // Section-heading checks are intentionally tolerant: the localized
    // policies (de/fr/es/…) are generated from the same template and the
    // canonical en-US wording was tightened in PR #1511 (e.g., "Data
    // collected" → "Data we use", "Data NOT collected" → "Data we do NOT
    // collect"). Match either phrasing so a future copy-edit doesn't
    // require a coupled test edit.

    test('contains a section about data the app uses', () {
      expect(
        html,
        anyOf(contains('Data we use'), contains('Data collected')),
      );
    });

    test('contains a section about data the app does NOT collect', () {
      expect(
        html,
        anyOf(
          contains('Data we do NOT collect'),
          contains('Data NOT collected'),
        ),
      );
    });

    test('contains required section: third-party services', () {
      expect(html, contains('Third-party services'));
    });

    test('contains required section: data security', () {
      expect(html, contains('Data security'));
    });

    test('contains required section: user rights', () {
      expect(html, contains('Your rights'));
    });

    test('contains required section: contact', () {
      expect(html, contains('Contact'));
      expect(html, contains('fdittgen@gmail.com'));
    });

    test('mentions location data', () {
      // Case-insensitive — the section heading uses lowercase "location"
      // ("Approximate location") since #1511.
      expect(html.toLowerCase(), contains('location'));
    });

    test('mentions API key storage', () {
      expect(html, contains('API key'));
    });

    test('mentions TankSync as optional', () {
      expect(html, contains('TankSync'));
      expect(html, contains('optional'));
    });

    test('mentions HTTPS encryption', () {
      expect(html, contains('HTTPS'));
    });

    test('#3712 — contains the account/data-deletion section Play\'s '
        'deletion URL points at', () {
      expect(html, contains('Deleting your account and data'));
      expect(html, contains('Delete account'),
          reason: 'the in-app deletion path must be named');
      expect(html, contains('including any linked e-mail address'),
          reason: 'the page must state the auth identity is deleted too, '
              'matching the delete_user RPC behavior (schema v6)');
    });

    test('#3712 — no longer claims e-mail is never collected (TankSync '
        'accounts can link one)', () {
      expect(html, isNot(contains('Name, email address or phone number')),
          reason: 'the pre-2026-08 "we never collect email" bullet '
              'contradicts the corrected Play data-safety declaration');
    });
  });
}
