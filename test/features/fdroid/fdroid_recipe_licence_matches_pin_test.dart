// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The F-Droid recipes' `License:` field must describe the artifact each
/// one actually ships — and the two recipes ship different things (#4445,
/// ADR 0028).
///
/// ADR 0028 relicensed the repository to AGPL-3.0-or-later on 2026-09-20.
/// That did **not** make every `License: MIT` in the tree wrong, and
/// getting this backwards in either direction misstates the terms to
/// users:
///
///  * `fdroid/metadata/…` is the SELF-HOSTED repo. It ships a prebuilt
///    APK that `scripts/fdroid_publish.sh` builds from whatever is
///    current, and the next `v*` tag builds from an AGPL master — so it
///    says **AGPL-3.0-or-later**.
///  * `metadata/…` is the source of the official **fdroiddata** recipe.
///    Its `Builds:` entries pin ONE commit, and the field describes that
///    commit, not this branch. The pin is `506fcf502` (v6.0.5,
///    2026-08-10), which is MIT — so it says **MIT**, correctly.
///
/// The pair is asserted together, because the failure mode is forgetting
/// the second half: someone moves the pin to a post-relicense release and
/// leaves `License: MIT` behind, and F-Droid then publishes an AGPL build
/// under an MIT label. This test fails the moment the pin moves and tells
/// them what to change.
///
/// This is the `fdroid_pin_vs_define` rule as a gate: a claim in the
/// recipe is a claim about the PINNED COMMIT, never about HEAD.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The last commit pinned by the official recipe while the project was
/// still MIT. ADR 0028 landed after it.
const _lastMitPin = '506fcf502d6d0d64f527b2f215f19cc8107361e1';

const _agpl = 'AGPL-3.0-or-later';
const _mit = 'MIT';

String _read(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is missing');
  return file.readAsStringSync();
}

/// The value of the recipe's own top-level `License:` key. Deliberately
/// anchored to the line start so the commentary above it — which names
/// both identifiers on purpose — cannot satisfy or break the match.
String _licenceField(String yaml) {
  final line = yaml
      .split('\n')
      .firstWhere((l) => l.startsWith('License:'), orElse: () => '');
  expect(line, isNotEmpty, reason: 'no top-level License: key found');
  return line.substring('License:'.length).trim();
}

Set<String> _pinnedCommits(String yaml) => yaml
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.startsWith('commit:'))
    .map((l) => l.substring('commit:'.length).trim())
    .toSet();

void main() {
  group('F-Droid recipe licence matches what it ships (#4445, ADR 0028)', () {
    test('the self-hosted recipe says $_agpl — it ships a build of HEAD', () {
      final yaml = _read('fdroid/metadata/de.tankstellen.fuelprices.yml');
      expect(_licenceField(yaml), _agpl,
          reason: 'fdroid/metadata ships whatever scripts/fdroid_publish.sh '
              'builds, and master is AGPL since ADR 0028. A stale MIT here '
              'labels an AGPL artifact as MIT.');
    });

    test('the official recipe pins exactly one commit', () {
      final pins = _pinnedCommits(_read('metadata/de.tankstellen.fuelprices.yml'));
      expect(pins, hasLength(1),
          reason: 'this gate reasons about "the pinned commit"; if the '
              'recipe ever pins several, the licence rule below has to be '
              'decided per Builds entry instead: $pins');
    });

    test('the official recipe\'s licence matches the era of its pin', () {
      final yaml = _read('metadata/de.tankstellen.fuelprices.yml');
      final pin = _pinnedCommits(yaml).single;
      final licence = _licenceField(yaml);

      if (pin == _lastMitPin) {
        expect(licence, _mit,
            reason: 'the recipe still pins the pre-relicense v6.0.5 commit '
                '($_lastMitPin), which IS MIT. Saying $_agpl here would '
                'misstate the terms of the build F-Droid actually produces.');
      } else {
        expect(licence, _agpl,
            reason: 'the pin moved to $pin, which is after ADR 0028 '
                '(2026-09-20) — so the build F-Droid produces is AGPL and '
                'this field must say so. Update `License:` in the SAME '
                'commit that moves the pin, and update the fdroiddata MR '
                'copy from this source (see #4023: edit here, run '
                '`dart run tool/fdroid_canonicalize.dart`, copy the body up).');
      }
    });

    test('both recipes name a licence F-Droid accepts', () {
      // A non-free identifier is what ADR 0028 spent its Context section
      // avoiding; assert it rather than trusting the prose.
      const free = {_mit, _agpl};
      for (final path in const [
        'metadata/de.tankstellen.fuelprices.yml',
        'fdroid/metadata/de.tankstellen.fuelprices.yml',
      ]) {
        expect(free, contains(_licenceField(_read(path))),
            reason: '$path declares a licence outside the set this project '
                'has decided on. `fdroid lint` validates this field against '
                "F-Droid's free list, and a non-free value closes the "
                'listing (ADR 0028).');
      }
    });
  });
}
