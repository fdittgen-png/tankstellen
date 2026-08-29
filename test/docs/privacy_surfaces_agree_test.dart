// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3875 (Epic #3865) — the privacy surfaces cannot drift apart again.
// `docs/privacy/data_inventory.json` is the source of truth; the policy
// (every locale), Play's DATA_SAFETY.md, the iOS privacy manifest, the
// README and the in-app URL must state exactly its facts.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';

void main() {
  late Map<String, dynamic> inv;
  setUpAll(() {
    inv = jsonDecode(File('docs/privacy/data_inventory.json').readAsStringSync())
        as Map<String, dynamic>;
  });

  test('the app constant carries the inventory policy version and URL', () {
    expect(AppConstants.privacyPolicyVersion, inv['policyVersion']);
    expect(AppConstants.privacyPolicyDate, inv['policyDate']);
    expect(AppConstants.privacyPolicyUrl, inv['policyUrl']);
    expect(AppConstants.privacyPolicyUrl, endsWith('/privacy-policy/'),
        reason: 'the Pages root is the landing page since #3066 — the '
            'in-app link must open the policy, not the marketing page');
  });

  test('every locale has a policy page at the current version', () {
    for (final loc in (inv['locales'] as List).cast<String>()) {
      final path = loc == 'en'
          ? 'docs/privacy-policy/index.html'
          : 'docs/privacy-policy/$loc/index.html';
      final f = File(path);
      expect(f.existsSync(), isTrue, reason: '$path missing');
      final html = f.readAsStringSync();
      expect(html, contains('Version ${inv['policyVersion']}'),
          reason: '$path is not at policy v${inv['policyVersion']}');
      expect(html, contains('lang="$loc"'));
      expect(html, contains(inv['controller']['email'] as String));
      for (final p in (inv['processors'] as List)) {
        for (final host in ((p as Map)['hosts'] as List)) {
          expect(html, contains(host as String),
              reason: '$path does not name processor host $host');
        }
      }
    }
  });

  test('the policy states every collected category and every non-collected '
      'one', () {
    final html = File('docs/privacy-policy/index.html').readAsStringSync();
    for (final c in (inv['collected'] as List).cast<Map<String, dynamic>>()) {
      expect(html, contains(c['policyPhrase'] as String),
          reason: 'policy lacks "${c['policyPhrase']}" (${c['id']})');
    }
    for (final n in (inv['notCollected'] as List).cast<String>()) {
      expect(html, contains(n), reason: 'policy lacks non-collected "$n"');
    }
    expect(html, contains(inv['controller']['name'] as String));
  });

  test('DATA_SAFETY.md declares exactly the inventory categories', () {
    final md = File('docs/play-store/DATA_SAFETY.md').readAsStringSync();
    for (final c in (inv['collected'] as List).cast<Map<String, dynamic>>()) {
      expect(md, contains(c['playDataSafety'] as String),
          reason: 'DATA_SAFETY.md lacks "${c['playDataSafety']}"');
    }
    expect(md, contains(inv['policyUrl'] as String));
    expect(md, contains('policy v${inv['policyVersion']}'),
        reason: 'DATA_SAFETY.md must reference the current policy version');
  });

  test('PrivacyInfo.xcprivacy declares exactly the inventory categories and '
      'no tracking', () {
    final plist = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
    final declared = RegExp(r'NSPrivacyCollectedDataType[A-Za-z]+')
        .allMatches(plist)
        .map((m) => m.group(0)!)
        .where((s) =>
            !s.endsWith('DataType') &&
            !s.endsWith('DataTypes') &&
            !s.contains('Linked') &&
            !s.contains('Tracking') &&
            !s.contains('Purpose'))
        .toSet();
    final expected = (inv['collected'] as List)
        .cast<Map<String, dynamic>>()
        .map((c) => c['xcprivacy'] as String)
        .toSet();
    expect(declared, expected,
        reason: 'iOS manifest and inventory disagree on collected types');
    expect(plist, contains('<key>NSPrivacyTracking</key>\n\t<false/>'),
        reason: 'the app never tracks (inventory: tracking=false)');
    expect(inv['tracking'], isFalse);
  });

  test('README states the compliance and links the current policy', () {
    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('## Privacy & GDPR'));
    expect(readme, contains(inv['policyUrl'] as String));
    expect(readme, contains('v${inv['policyVersion']}'));
    expect(readme, isNot(contains('never leave the device')),
        reason: 'the absolute claim is false when TankSync trip sync is on');
  });
}
