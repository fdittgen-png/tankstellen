// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4225 — the preset bundles must be satisfiable on their own terms.
//
// `applyBundle` deliberately does NOT run the per-feature `requires`
// guard: #1765 found that routing a preset through `enable` crashed the
// moment a dependent's prerequisite was absent from the bundle, and a
// preset is meant to be a complete, intentional set. That decision
// stands — but it means nothing checks the bundles themselves, so a
// future edit could ship a preset that enables a feature whose
// prerequisite it forgot, and the guard that would have caught it is
// the one #1765 removed.
//
// The audit on #4225 measured zero violations today. This locks that.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/app_profile.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

void main() {
  const manifest = FeatureManifest.defaultManifest;

  group('preset bundles are internally satisfiable (#4225)', () {
    for (final entry in appProfileBundles.entries) {
      test('${entry.key.name} satisfies every members requires closure', () {
        final bundle = entry.value;
        final unsatisfied = <String>[];
        for (final feature in bundle) {
          final missing = manifest
              .entryFor(feature)
              .requires
              .where((r) => !bundle.contains(r));
          for (final m in missing) {
            unsatisfied.add('${feature.name} requires ${m.name}');
          }
        }
        expect(unsatisfied, isEmpty,
            reason: 'applyBundle skips the requires guard by design '
                '(#1765), so an unsatisfiable preset would silently ship '
                'a feature whose prerequisite is off');
      });

      test('${entry.key.name} declares only features the manifest knows', () {
        expect(
          entry.value.where((f) => !manifest.entries.containsKey(f)),
          isEmpty,
        );
      });

      test('${entry.key.name} is available in the production channel', () {
        // #1674 drops channel-unavailable features on apply. A preset
        // that names one is not wrong, but the user would silently get
        // a smaller set than the preset claims.
        final dropped = entry.value.where((f) =>
            !manifest.entryFor(f).isAvailableIn(BuildChannel.production));
        expect(dropped, isEmpty,
            reason: 'applyBundle would drop these, so the preset does not '
                'describe what the user actually gets');
      });
    }

    test('the bundles stay distinct — a preset that equals another is a '
        'choice the user cannot act on', () {
      final seen = <Set<Feature>>[];
      for (final b in appProfileBundles.values) {
        expect(seen.any((s) => s.length == b.length && s.containsAll(b)),
            isFalse);
        seen.add(b);
      }
    });

    test('every bundle round-trips through detectProfileFromFlags', () {
      for (final entry in appProfileBundles.entries) {
        expect(detectProfileFromFlags(entry.value), entry.key,
            reason: 'a preset the detector cannot recognise shows as '
                'Custom the instant it is applied');
      }
    });
  });
}
