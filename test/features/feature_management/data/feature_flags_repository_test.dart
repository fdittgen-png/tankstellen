// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';

/// Unit tests for [FeatureFlagsRepository] (epic #1612, child #1629).
///
/// Pins the persistence contract: a fresh (empty) box yields the
/// manifest defaults, [saveEnabled] writes every [Feature] explicitly so
/// "user disabled it" survives a reload, and an unknown enum name left
/// behind by a downgrade is skipped instead of crashing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> box;
  late FeatureFlagsRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('feature_flags_repo_');
    Hive.init(tmpDir.path);
    final suffix = DateTime.now().microsecondsSinceEpoch;
    box = await Hive.openBox<dynamic>('feature_flags_$suffix');
    repo = FeatureFlagsRepository(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('isEmpty', () {
    test('true for a fresh box, false once written', () async {
      expect(repo.isEmpty, isTrue);
      await repo.saveEnabled({Feature.gamification});
      expect(repo.isEmpty, isFalse);
    });
  });

  group('loadEnabled', () {
    test('empty box returns the manifest defaults', () async {
      final loaded = await repo.loadEnabled();
      expect(loaded, FeatureManifest.defaultManifest.defaultEnabledSet());
    });

    test('populated box returns exactly the persisted set', () async {
      final chosen = {Feature.gamification, Feature.tankSync};
      await repo.saveEnabled(chosen);
      expect(await repo.loadEnabled(), chosen);
    });

    test('a feature explicitly disabled stays disabled across a reload',
        () async {
      // Start from the defaults, then persist a set that omits one of
      // them — the omitted feature must NOT reappear as "default on".
      final defaults = FeatureManifest.defaultManifest.defaultEnabledSet();
      expect(defaults, isNotEmpty,
          reason: 'test needs at least one default-on feature');
      final dropped = defaults.first;
      await repo.saveEnabled(defaults.difference({dropped}));
      expect((await repo.loadEnabled()).contains(dropped), isFalse);
    });

    test('skips an unknown enum name left by a downgrade', () async {
      await box.put('a_feature_removed_in_a_later_version', true);
      await box.put(Feature.tankSync.name, true);
      final loaded = await repo.loadEnabled();
      expect(loaded, contains(Feature.tankSync));
      // No crash, and the bogus key contributed nothing.
      expect(loaded.length, 1);
    });
  });

  group('saveEnabled', () {
    test('writes every Feature explicitly (true or false)', () async {
      await repo.saveEnabled({Feature.gamification});
      // One key per Feature — so a later read can tell "disabled" from
      // "first launch".
      expect(box.keys.toSet(),
          {for (final f in Feature.values) f.name});
      expect(box.get(Feature.gamification.name), isTrue);
      expect(box.get(Feature.tankSync.name), isFalse);
    });
  });
}
