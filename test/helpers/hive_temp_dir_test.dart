// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'hive_temp_dir.dart';

/// #4398 — the race is real, and `closeHiveAndDeleteTemp` is what stops
/// it failing a test.
///
/// The first test is the *fail-before*: it drives the hand-rolled idiom
/// (a temp-dir delete that gets ahead of `Hive.close()`) and asserts that
/// Hive's own `StorageBackendVm._closeInternal` throws while unlinking
/// the box's `.lock` file — the exact `PathNotFoundException` that took
/// three CI shards down. Every following test runs the *same* setup
/// through the helper and asserts it completes.
///
/// A regression here means the helper stopped absorbing the race, or
/// (first test) that Hive stopped deleting lock files and the helper's
/// reason for existing needs re-reading.
void main() {
  /// A temp dir with Hive initialised and one open box — the shape every
  /// Hive-backed test sets up.
  Future<Directory> hiveTempDir(String boxName) async {
    final dir = Directory.systemTemp.createTempSync('hive_temp_dir_test_');
    Hive.init(dir.path);
    final box = await Hive.openBox<String>(boxName);
    await box.put('k', 'v');
    return dir;
  }

  test(
      'FAIL-BEFORE: the hand-rolled teardown throws when the delete gets '
      'ahead of the close', () async {
    final dir = await hiveTempDir('raw_race_box');

    // The racing half: something removes the directory while Hive still
    // owns the box's lock file.
    dir.deleteSync(recursive: true);

    await expectLater(
      Hive.close(),
      throwsA(
        isA<FileSystemException>()
            .having((e) => e.message, 'message', contains('Cannot delete'))
            .having((e) => e.path, 'path', endsWith('raw_race_box.lock')),
      ),
      reason: 'if this stops throwing, hive no longer unlinks the .lock in '
          'StorageBackendVm._closeInternal and #4398 is obsolete',
    );
  });

  test('PASS-AFTER: the helper absorbs exactly that failure', () async {
    final dir = await hiveTempDir('helper_race_box');

    dir.deleteSync(recursive: true);

    await expectLater(closeHiveAndDeleteTemp(dir), completes);
    expect(Hive.isBoxOpen('helper_race_box'), isFalse,
        reason: 'the boxes must still be closed — the helper absorbs the '
            'filesystem noise, not the close itself');
  });

  test('the ordinary path closes first, then removes the directory',
      () async {
    final dir = await hiveTempDir('ordinary_box');
    expect(File('${dir.path}/ordinary_box.lock').existsSync(), isTrue);

    await closeHiveAndDeleteTemp(dir);

    expect(dir.existsSync(), isFalse);
    expect(Hive.isBoxOpen('ordinary_box'), isFalse);
  });

  test('two teardowns racing each other both complete', () async {
    final dir = await hiveTempDir('concurrent_box');

    await expectLater(
      Future.wait([closeHiveAndDeleteTemp(dir), closeHiveAndDeleteTemp(dir)]),
      completes,
    );
    expect(dir.existsSync(), isFalse);
  });

  test('a directory that was never created is not an error', () async {
    final dir = Directory('${Directory.systemTemp.path}/hive_never_made_4398');
    expect(dir.existsSync(), isFalse);

    await expectLater(closeHiveAndDeleteTemp(dir), completes);
  });
}
