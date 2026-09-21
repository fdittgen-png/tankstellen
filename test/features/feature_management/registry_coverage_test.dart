// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4224 — the coverage report has to stay true, or it becomes a list
// someone wrote once and nobody trusts.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/feature_management/domain/registry_coverage.dart';

void main() {
  const manifest = FeatureManifest.defaultManifest;

  test('the registry itself is complete — every Feature has an entry', () {
    expect(registryIsComplete(manifest), isTrue);
    expect(registeredCapabilityCount(manifest), Feature.values.length);
  });

  test('no gap names a setting that has SINCE gained a Feature', () {
    // The audit on #4224 listed the haptic eco-coach and baseline sync
    // as unmapped. Both have Feature values, so both are registered —
    // the StorageKeys entries survive only as migration sources. This
    // stops that class of stale claim coming back.
    final featureNames = Feature.values.map((f) => f.name.toLowerCase());
    for (final gap in RegistryGap.values) {
      final key = gap.key.replaceAll('_', '').toLowerCase();
      final collides =
          featureNames.where((n) => n.replaceAll('_', '') == key);
      expect(collides, isEmpty,
          reason: '${gap.key} now has a Feature — remove it from the gap '
              'list instead of reporting it as unmapped');
    }
  });

  test('every gap carries a non-empty key and user-facing name', () {
    for (final gap in RegistryGap.values) {
      expect(gap.key, isNotEmpty);
      expect(gap.what, isNotEmpty);
    }
  });

  test('the migration backlog is exactly the unmapped user capabilities', () {
    expect(unmappedUserCapabilities.map((g) => g.name),
        containsAll(<String>['evShowOnMap', 'autoSwitchProfile']));
    for (final gap in unmappedUserCapabilities) {
      expect(gap.classification, GapClassification.unmappedUserCapability);
    }
  });

  test('parameters and internal state are NOT in the backlog — the '
      'registry rule is that technical capabilities never become '
      'primary user choices', () {
    final backlog = unmappedUserCapabilities.toSet();
    expect(backlog.contains(RegistryGap.obd2DebugOverlay), isFalse);
    expect(backlog.contains(RegistryGap.recordingProfile), isFalse);
    expect(backlog.contains(RegistryGap.tileProxy), isFalse);
  });
}
