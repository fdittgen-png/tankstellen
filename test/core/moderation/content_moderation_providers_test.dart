// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/moderation/content_moderation_providers.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

/// #3726 — the device-local moderation state (block list + reported
/// ids): persistence round-trip, and the do-no-harm degrade when the
/// settings box is unavailable (the Hive-not-open harness state that
/// took TripDetailScreen down before the guard existed).
void main() {
  ProviderContainer container(SettingsStorage storage) {
    final c = ProviderContainer(
      overrides: [settingsStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('BlockedContentAuthors', () {
    test('block persists the id and reflects it in state', () async {
      final storage = _MemorySettings();
      final c = container(storage);
      expect(c.read(blockedContentAuthorsProvider), isEmpty);

      await c.read(blockedContentAuthorsProvider.notifier).block('alice');
      expect(c.read(blockedContentAuthorsProvider), {'alice'});
      expect(storage.values[StorageKeys.blockedContentAuthorIds], ['alice']);
    });

    test('unblock removes the id again (future settings-list seam)',
        () async {
      final storage = _MemorySettings()
        ..values[StorageKeys.blockedContentAuthorIds] = ['alice', 'bob'];
      final c = container(storage);
      expect(c.read(blockedContentAuthorsProvider), {'alice', 'bob'});

      await c.read(blockedContentAuthorsProvider.notifier).unblock('alice');
      expect(c.read(blockedContentAuthorsProvider), {'bob'});
      expect(storage.values[StorageKeys.blockedContentAuthorIds], ['bob']);
    });

    test('a throwing settings box degrades to empty — never propagates',
        () async {
      final c = container(_ThrowingSettings());
      expect(c.read(blockedContentAuthorsProvider), isEmpty);
      // A block while storage is down still hides for this session.
      await c.read(blockedContentAuthorsProvider.notifier).block('alice');
      expect(c.read(blockedContentAuthorsProvider), {'alice'});
    });

    test('a malformed persisted value degrades to empty', () {
      final storage = _MemorySettings()
        ..values[StorageKeys.blockedContentAuthorIds] = 'not-a-list';
      expect(container(storage).read(blockedContentAuthorsProvider), isEmpty);
    });
  });

  group('ReportedContentTargets', () {
    test('hide persists the target id', () async {
      final storage = _MemorySettings();
      final c = container(storage);
      await c.read(reportedContentTargetsProvider.notifier).hide('t1');
      expect(c.read(reportedContentTargetsProvider), {'t1'});
      expect(storage.values[StorageKeys.reportedContentTargetIds], ['t1']);
    });

    test('a throwing settings box degrades to empty — never propagates', () {
      expect(container(_ThrowingSettings()).read(reportedContentTargetsProvider),
          isEmpty);
    });
  });
}

class _MemorySettings implements SettingsStorage {
  final Map<String, dynamic> values = {};

  @override
  dynamic getSetting(String key) => values[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    values[key] = value;
  }

  @override
  bool get isSetupComplete => true;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}

/// Mimics the Hive "Box not found" harness state.
class _ThrowingSettings implements SettingsStorage {
  @override
  dynamic getSetting(String key) =>
      throw StateError('Box not found. Did you forget to call Hive.openBox()?');

  @override
  Future<void> putSetting(String key, dynamic value) async =>
      throw StateError('Box not found. Did you forget to call Hive.openBox()?');

  @override
  bool get isSetupComplete => false;

  @override
  bool get isSetupSkipped => false;

  @override
  Future<void> skipSetup() async {}

  @override
  Future<void> resetSetupSkip() async {}
}
