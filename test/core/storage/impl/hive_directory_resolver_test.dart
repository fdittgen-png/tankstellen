// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/impl/hive_directory_resolver.dart';

/// #3747 (item 3) — the iOS Hive dir migration: Documents → Application
/// Support, one-time MOVE, never-throws with rollback on failure.
void main() {
  late Directory root;
  late Directory legacy;
  late Directory target;

  setUp(() {
    root = Directory.systemTemp.createTempSync('hive_dir_resolver_test');
    legacy = Directory('${root.path}/Documents')..createSync();
    target = Directory('${root.path}/ApplicationSupport');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  File seed(Directory dir, String name, [String content = 'data']) =>
      File('${dir.path}/$name')..writeAsStringSync(content);

  List<String> names(Directory dir) => dir
      .listSync()
      .map((e) => e.path.split(Platform.pathSeparator).last)
      .toList()
    ..sort();

  group('HiveDirectoryResolver.migrateAndResolve', () {
    test('fresh install (no legacy boxes) → target dir, created', () {
      final dir = HiveDirectoryResolver.migrateAndResolve(legacy, target);
      expect(dir, target.path);
      expect(target.existsSync(), isTrue);
    });

    test('missing legacy dir → target dir (no throw)', () {
      legacy.deleteSync();
      expect(
        () => HiveDirectoryResolver.migrateAndResolve(legacy, target),
        returnsNormally,
      );
      expect(HiveDirectoryResolver.migrateAndResolve(legacy, target),
          target.path);
    });

    test('moves .hive and .hivec files, leaves .lock behind', () {
      seed(legacy, 'favorites.hive', 'fav-bytes');
      seed(legacy, 'cache.hivec');
      seed(legacy, 'favorites.lock');
      seed(legacy, 'export.csv'); // user export — must never be touched

      final dir = HiveDirectoryResolver.migrateAndResolve(legacy, target);

      expect(dir, target.path);
      expect(names(target), ['cache.hivec', 'favorites.hive']);
      expect(names(legacy), ['export.csv', 'favorites.lock']);
      // MOVE semantics: content survives byte-for-byte.
      expect(File('${target.path}/favorites.hive').readAsStringSync(),
          'fav-bytes');
    });

    test('target already holds Hive files → uses target, never moves on '
        'top of newer data', () {
      target.createSync();
      seed(target, 'favorites.hive', 'new-data');
      seed(legacy, 'favorites.hive', 'stale-legacy');

      final dir = HiveDirectoryResolver.migrateAndResolve(legacy, target);

      expect(dir, target.path);
      expect(File('${target.path}/favorites.hive').readAsStringSync(),
          'new-data');
      expect(File('${legacy.path}/favorites.hive').existsSync(), isTrue,
          reason: 'the stale legacy file is left alone, not clobbered');
    });

    test('second call after a successful migration is a no-op on target',
        () {
      seed(legacy, 'settings.hive');
      final first = HiveDirectoryResolver.migrateAndResolve(legacy, target);
      final second = HiveDirectoryResolver.migrateAndResolve(legacy, target);
      expect(first, target.path);
      expect(second, target.path);
      expect(names(target), ['settings.hive']);
    });

    test('FAULT INJECTION: a move failing mid-migration returns normally, '
        'rolls the already-moved files back and answers the legacy dir '
        '(never-throws contract)', () {
      seed(legacy, 'a.hive', 'a-bytes');
      seed(legacy, 'b.hive', 'b-bytes');
      seed(legacy, 'c.hive', 'c-bytes');

      var moves = 0;
      String? dir;
      expect(
        () => dir = HiveDirectoryResolver.migrateAndResolve(
          legacy,
          target,
          move: (file, newPath) {
            if (++moves == 2) {
              throw const FileSystemException('disk full');
            }
            file.renameSync(newPath);
          },
        ),
        returnsNormally,
      );

      expect(dir, legacy.path,
          reason: 'this launch must run fully from the legacy dir');
      expect(names(legacy), ['a.hive', 'b.hive', 'c.hive'],
          reason: 'the already-moved file must be rolled back — the box '
              'set is never split across two directories');
      expect(target.existsSync() ? names(target) : <String>[], isEmpty);
      expect(File('${legacy.path}/a.hive').readAsStringSync(), 'a-bytes');
    });

    test('FAULT INJECTION: a failed migration retries (and succeeds) on '
        'the next launch', () {
      seed(legacy, 'a.hive');
      seed(legacy, 'b.hive');

      final failed = HiveDirectoryResolver.migrateAndResolve(
        legacy,
        target,
        move: (file, newPath) => throw const FileSystemException('busy'),
      );
      expect(failed, legacy.path);

      final retried = HiveDirectoryResolver.migrateAndResolve(legacy, target);
      expect(retried, target.path);
      expect(names(target), ['a.hive', 'b.hive']);
    });
  });
}
