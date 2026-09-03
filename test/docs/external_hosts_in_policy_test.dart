// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3875 (Epic #3865) — every host the app CONTACTS must be named in the
// privacy policy. The audit found logo.clearbit.com, the tile proxy, OSRM
// and Overpass receiving user data with no mention anywhere; this scan of
// `lib/` catches the next one at the PR.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hosts referenced in `lib/` that the app does NOT contact with user data:
/// deep links opened in the browser on an explicit tap, documentation
/// links shown as text, XML namespaces, our own domains. Add a host here
/// ONLY with a reason — an API endpoint belongs in the policy instead.
const _notContacted = <String, String>{
  'github.com': 'source / issue deep links (api.github.com IS in the policy)',
  'fdittgen-png.github.io': 'our own Pages site (policy, landing)',
  'sparkilo.app': 'our own share-link domain (opened by the recipient)',
  'tankstellen.app': 'XML namespace of the backup format',
  'tankstellen.de': 'XML namespace',
  'www.w3.org': 'XML namespace',
  'www.topografix.com': 'GPX namespace',
  'play.google.com': 'store deep link',
  'www.paypal.me': 'donation deep link (tap)',
  'revolut.me': 'donation deep link (tap)',
  // #3940 — the bundled brand logos are shipped as assets; the app never
  // fetches them. These two hosts appear only as ATTRIBUTION text in
  // `brand_logo_manifest_data.dart`, which the credits screen can open on
  // an explicit tap (the same shape as the documentation links above):
  // commons.wikimedia.org is each file's source page, and powerdot.eu is
  // the author string Commons records for the one CC-BY-SA file whose
  // author is a URL. No user data reaches either.
  'commons.wikimedia.org': 'bundled-logo source attribution (tap)',
  'powerdot.eu': 'CC-BY-SA author attribution for a bundled logo (tap)',
  'en.wikipedia.org': 'documentation link (tap)',
  'www.garmin.com': 'documentation link (tap)',
  'supabase.com': 'documentation link in the self-host wizard (tap)',
  'openchargemap.org': 'key-request link (tap); api.openchargemap.io is named',
  'apidocs.cne.cl': 'documentation link',
  'www.cne.cl': 'documentation link; api.cne.cl is named',
  'www.gov.uk': 'documentation link',
  'www.developer.fuel-finder.service.gov.uk': 'key-request link (tap)',
  'www.mimit.gov.it': 'documentation link; carburanti.mise.gov.it is named',
  'www.prix-carburants.gouv.fr': 'documentation link',
  'onboarding.tankerkoenig.de': 'key-request link (tap)',
  'www.spritpreisrechner.at': 'documentation link; api.e-control.at is named',
  'www.ok.dk': 'documentation link; mobility-prices.ok.dk is named',
  'www.monitorulpreturilor.info': 'www. alias of a named host',
  'datos.gob.mx': 'documentation link; publicacionexterna.azurewebsites.net is named',
};

void main() {
  test('every host contacted from lib/ is named in the privacy policy', () {
    final policy = File('docs/privacy-policy/index.html').readAsStringSync();
    final hostRe = RegExp(r'https?://([A-Za-z0-9.-]+\.[A-Za-z]{2,})');
    final found = <String, String>{};
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'))) {
      for (final m in hostRe.allMatches(f.readAsStringSync())) {
        found.putIfAbsent(m.group(1)!.toLowerCase().replaceAll(RegExp(r'\.$'), ''),
            () => f.path);
      }
    }
    expect(found, isNotEmpty);
    final missing = <String>[];
    for (final e in found.entries) {
      if (_notContacted.containsKey(e.key)) continue;
      if (!policy.contains(e.key)) missing.add('${e.key} (${e.value})');
    }
    expect(missing, isEmpty,
        reason: 'host(s) referenced in lib/ but absent from the privacy '
            'policy: $missing — name them in docs/privacy-policy (all '
            'locales) or, if the app never contacts them with user data, '
            'add them to _notContacted with a reason');
  });

  test('the not-contacted allowlist does not hide a named processor', () {
    final policy = File('docs/privacy-policy/index.html').readAsStringSync();
    for (final host in _notContacted.keys) {
      expect(policy.contains(host) && host != 'github.com', isFalse,
          reason: '$host is in the policy AND the allowlist — drop it from '
              'the allowlist');
    }
  });
}
