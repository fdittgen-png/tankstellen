// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3614 — unit tests for the shared keyed-Hive-JSON repository base
// extracted from the loyalty / achievements / service-reminder repos.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/json_box_repository.dart';

import '../../helpers/silence_error_logger.dart';

class _Thing {
  const _Thing({required this.id, required this.value});

  final String id;
  final int value;

  static _Thing? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) return null;
    return _Thing(id: id, value: (json['value'] as num?)?.toInt() ?? 0);
  }

  Map<String, dynamic> toJson() => {'id': id, 'value': value};
}

JsonBoxRepository<_Thing> _repo(Box<dynamic> box, {String prefix = ''}) =>
    JsonBoxRepository<_Thing>(
      box: box,
      fromJson: _Thing.fromJson,
      toJson: (t) => t.toJson(),
      keyOf: (t) => t.id,
      entryKeyPrefix: prefix,
      debugName: 'TestRepo',
    );

void main() {
  silenceErrorLoggerSpool();

  late Directory tempDir;
  late Box<dynamic> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('json_box_repo_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('json_box_repo_test');
    await box.clear();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('JsonBoxRepository', () {
    test('getAll is empty on a fresh box', () {
      expect(_repo(box).getAll(), isEmpty);
    });

    test('put then getAll round-trips the entity', () async {
      final repo = _repo(box);
      await repo.put(const _Thing(id: 'a', value: 1));
      await repo.put(const _Thing(id: 'b', value: 2));

      final all = repo.getAll();
      expect(all, hasLength(2));
      expect(all.map((t) => t.id).toSet(), {'a', 'b'});
    });

    test('put overwrites an existing key', () async {
      final repo = _repo(box);
      await repo.put(const _Thing(id: 'a', value: 1));
      await repo.put(const _Thing(id: 'a', value: 9));

      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.value, 9);
    });

    test('getByKey returns the entity or null when absent', () async {
      final repo = _repo(box);
      await repo.put(const _Thing(id: 'a', value: 1));
      expect(repo.getByKey('a')?.value, 1);
      expect(repo.getByKey('missing'), isNull);
    });

    test('deleteByKey removes only the targeted entry (no-op on unknown)',
        () async {
      final repo = _repo(box);
      await repo.put(const _Thing(id: 'a', value: 1));
      await repo.put(const _Thing(id: 'b', value: 2));

      await repo.deleteByKey('a');
      await repo.deleteByKey('missing');

      expect(repo.getAll().single.id, 'b');
    });

    test('entryKeyPrefix scopes keys inside a shared box', () async {
      final repo = _repo(box, prefix: 'thing:');
      await box.put('unrelated', 'not json at all');
      await box.put('other_setting', {'foo': 'bar'});
      await repo.put(const _Thing(id: 'a', value: 1));

      expect(box.get('thing:a'), isA<String>());
      expect(repo.getAll().single.id, 'a');

      await repo.clearStored();
      expect(repo.getAll(), isEmpty);
      // Unrelated sibling keys are untouched.
      expect(box.get('unrelated'), isNotNull);
      expect(box.get('other_setting'), isNotNull);
    });

    test('corrupt entries are skipped without hiding the rest', () async {
      final repo = _repo(box);
      await repo.put(const _Thing(id: 'a', value: 1));
      await box.put('garbage', 'not valid json');

      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'a');
      expect(repo.getByKey('garbage'), isNull);
    });

    test('fromJson returning null skips the entry silently', () async {
      final repo = _repo(box);
      await repo.put(const _Thing(id: 'a', value: 1));
      // Valid JSON map, but no usable id -> fromJson returns null.
      await box.put('half-valid', '{"value": 3}');

      expect(repo.getAll(), hasLength(1));
    });

    test('legacy raw-Map payloads decode via toStringDynamicMap', () async {
      final repo = _repo(box);
      await box.put('legacy', {'id': 'legacy', 'value': 7});

      final all = repo.getAll();
      expect(all, hasLength(1));
      expect(all.single.id, 'legacy');
      expect(all.single.value, 7);
    });

    test('empty-string payloads are skipped silently', () async {
      final repo = _repo(box);
      await box.put('empty', '');
      expect(repo.getAll(), isEmpty);
    });

    test('put failures propagate to the caller (no swallow in the base)',
        () async {
      final repo = JsonBoxRepository<_Thing>(
        box: _ThrowingBox(),
        fromJson: _Thing.fromJson,
        toJson: (t) => t.toJson(),
        keyOf: (t) => t.id,
        debugName: 'ThrowingRepo',
      );
      await expectLater(
        repo.put(const _Thing(id: 'a', value: 1)),
        throwsA(isA<HiveError>()),
      );
    });
  });
}

class _ThrowingBox extends Fake implements Box<dynamic> {
  @override
  Future<void> put(dynamic key, dynamic value) async =>
      throw HiveError('disk full');
}
