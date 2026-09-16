// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4224 — the hierarchy is only worth having if it stays complete and
// unambiguous. These are the invariants #4227's migration matrix and
// #4226's process cards both assume.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/domain/capability_ownership.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/feature_management/domain/process_taxonomy.dart';

void main() {
  group('the taxonomy partitions cleanly', () {
    test('every subprocess belongs to exactly one process, and every '
        'process is reachable', () {
      final seen = <SparkiloProcess, int>{};
      for (final s in SparkiloSubprocess.values) {
        seen.update(s.owner, (v) => v + 1, ifAbsent: () => 1);
      }
      expect(seen.keys.toSet(), SparkiloProcess.values.toSet(),
          reason: 'a process with no subprocess cannot be opened');
    });

    test('subprocessesOf partitions the whole set — no subprocess is '
        'listed twice or lost', () {
      final collected = [
        for (final p in SparkiloProcess.values) ...subprocessesOf(p),
      ];
      expect(collected.length, SparkiloSubprocess.values.length);
      expect(collected.toSet(), SparkiloSubprocess.values.toSet());
    });
  });

  group('every capability has exactly one owner (#4224)', () {
    test('no Feature is unowned', () {
      expect(unownedCapabilities, isEmpty,
          reason: 'a new Feature must be given a process owner in '
              'capability_ownership.dart — #4227 assigns EVERY existing '
              'user-facing setting an owner, and an unowned one is '
              'invisible to the process model');
      expect(capabilityOwner.length, Feature.values.length);
    });

    test('ownerOf and processOf agree with the map', () {
      for (final f in Feature.values) {
        expect(ownerOf(f), capabilityOwner[f]);
        expect(processOf(f), capabilityOwner[f]!.owner);
      }
    });

    test('capabilitiesOf partitions the features across processes', () {
      final collected = [
        for (final p in SparkiloProcess.values) ...capabilitiesOf(p),
      ];
      expect(collected.length, Feature.values.length,
          reason: 'duplicate process ownership is what #4227 forbids');
      expect(collected.toSet(), Feature.values.toSet());
    });

    test('the manifest and the ownership map describe the same universe',
        () {
      const manifest = FeatureManifest.defaultManifest;
      expect(capabilityOwner.keys.toSet(), manifest.entries.keys.toSet(),
          reason: 'the registry is the single source; ownership that '
              'names a feature the manifest does not declare (or misses '
              'one it does) is a second, disagreeing source');
    });
  });

  group('the two empty processes are empty ON PURPOSE', () {
    // Encoded so nobody "completes" them by inventing flags.
    test('manageVehicle owns no Feature — vehicle identity and adapter '
        'pairing are screens, not toggles', () {
      expect(capabilitiesOf(SparkiloProcess.manageVehicle), isEmpty);
      expect(subprocessesOf(SparkiloProcess.manageVehicle), isNotEmpty,
          reason: 'the process exists in the taxonomy either way');
    });

    test('manageFleet owns no Feature — the fleet does not exist yet '
        '(#4212-#4219 is where it gains capabilities)', () {
      expect(capabilitiesOf(SparkiloProcess.manageFleet), isEmpty);
    });

    test('every OTHER process owns at least one capability', () {
      const knownEmpty = {
        SparkiloProcess.manageVehicle,
        SparkiloProcess.manageFleet,
      };
      for (final p in SparkiloProcess.values) {
        if (knownEmpty.contains(p)) continue;
        expect(capabilitiesOf(p), isNotEmpty, reason: '${p.name} is empty');
      }
    });
  });
}
