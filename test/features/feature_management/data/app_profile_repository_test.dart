// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/feature_management/data/app_profile_repository.dart';
import 'package:tankstellen/features/feature_management/domain/app_profile.dart';

/// Unit tests for [AppProfileRepository] (epic #1612, child #1629).
///
/// Pins the single-entry persistence contract: an empty box means "no
/// choice yet" (`load` → null, `isEmpty` → true), `save` round-trips,
/// and an unknown profile name is treated as no choice rather than
/// crashing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<dynamic> box;
  late AppProfileRepository repo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('app_profile_repo_');
    Hive.init(tmpDir.path);
    final suffix = DateTime.now().microsecondsSinceEpoch;
    box = await Hive.openBox<dynamic>('app_profile_$suffix');
    repo = AppProfileRepository(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('empty box', () {
    test('isEmpty is true and load returns null', () {
      expect(repo.isEmpty, isTrue);
      expect(repo.load(), isNull);
    });
  });

  group('save / load round-trip', () {
    for (final profile in AppProfile.values) {
      test('persists and reloads AppProfile.${profile.name}', () async {
        await repo.save(profile);
        expect(repo.isEmpty, isFalse);
        expect(repo.load(), profile);
      });
    }

    test('a second save overwrites the first choice', () async {
      await repo.save(AppProfile.basic);
      await repo.save(AppProfile.full);
      expect(repo.load(), AppProfile.full);
    });
  });

  group('corrupt data recovery', () {
    test('an unknown profile name loads as null (no choice)', () async {
      await box.put('profile', 'a_profile_from_the_future');
      expect(repo.load(), isNull);
    });

    test('a non-string value loads as null instead of throwing', () async {
      await box.put('profile', 42);
      expect(repo.load, returnsNormally);
      expect(repo.load(), isNull);
    });
  });
}
