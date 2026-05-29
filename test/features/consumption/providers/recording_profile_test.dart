// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/consumption/domain/entities/recording_profile.dart';
import 'package:tankstellen/features/consumption/providers/recording_profile_provider.dart';

import '../../../helpers/silence_error_logger.dart';

/// In-memory [SettingsStorage] stub — only the generic getSetting /
/// putSetting surface the RecordingProfile controller touches is
/// implemented; every other member throws via noSuchMethod so an
/// accidental dependency is loud.
class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> store = {};

  @override
  dynamic getSetting(String key) => store[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    store[key] = value;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(_FakeSettings settings) {
  final c = ProviderContainer(overrides: [
    settingsStorageProvider.overrideWithValue(settings),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  silenceErrorLoggerSpool();

  group('RecordingProfile model', () {
    test('defaults are all OFF — preserves the opt-in-each-drive design', () {
      const p = RecordingProfile.defaults;
      expect(p.autoPin, isFalse);
      expect(p.autoEnterReducedOnStart, isFalse);
      expect(p.keepScreenAwake, isFalse);
      expect(p.isDefault, isTrue);
      expect(p.wantsScreenAwakeOnStart, isFalse);
    });

    test('autoPin OR keepScreenAwake imply wantsScreenAwakeOnStart', () {
      expect(const RecordingProfile(autoPin: true).wantsScreenAwakeOnStart,
          isTrue);
      expect(
          const RecordingProfile(keepScreenAwake: true).wantsScreenAwakeOnStart,
          isTrue);
    });

    test('JSON round-trips every field', () {
      const p = RecordingProfile(
        autoPin: true,
        autoEnterReducedOnStart: true,
        keepScreenAwake: true,
      );
      final back = RecordingProfile.fromJson(p.toJson());
      expect(back, p);
    });

    test('fromJson tolerates a partial / legacy payload (missing keys OFF)',
        () {
      final p = RecordingProfile.fromJson(const {'autoPin': true});
      expect(p.autoPin, isTrue);
      expect(p.autoEnterReducedOnStart, isFalse);
      expect(p.keepScreenAwake, isFalse);
    });
  });

  group('RecordingProfileController persistence (#2274 concern 1)', () {
    test('absent payload reads the all-default profile', () {
      final settings = _FakeSettings();
      final c = _container(settings);
      final profile = c.read(recordingProfileControllerProvider);
      expect(profile, RecordingProfile.defaults);
      expect(profile.autoPin, isFalse);
    });

    test('setAutoPin persists a JSON payload and republishes state',
        () async {
      final settings = _FakeSettings();
      final c = _container(settings);
      final ctrl = c.read(recordingProfileControllerProvider.notifier);

      await ctrl.setAutoPin(true);

      expect(c.read(recordingProfileControllerProvider).autoPin, isTrue);
      // Persisted as a JSON string under the global key.
      final raw = settings.store[StorageKeys.recordingProfile] as String;
      expect(jsonDecode(raw)['autoPin'], isTrue);
    });

    test('a persisted profile is read back on a fresh controller build',
        () async {
      final settings = _FakeSettings();
      settings.store[StorageKeys.recordingProfile] =
          jsonEncode(const RecordingProfile(autoPin: true).toJson());
      final c = _container(settings);
      expect(c.read(recordingProfileControllerProvider).autoPin, isTrue);
    });

    test('per-vehicle override wins over the global profile', () async {
      final settings = _FakeSettings();
      final c = _container(settings);
      final ctrl = c.read(recordingProfileControllerProvider.notifier);

      // Global: autoPin OFF. Vehicle v1: autoPin ON.
      await ctrl.setGlobal(RecordingProfile.defaults);
      await ctrl.setOverride('v1', const RecordingProfile(autoPin: true));

      expect(ctrl.effectiveFor('v1').autoPin, isTrue,
          reason: 'vehicle override applies');
      expect(ctrl.effectiveFor('v2').autoPin, isFalse,
          reason: 'unconfigured vehicle falls back to the global default');
      expect(ctrl.effectiveFor(null).autoPin, isFalse);
    });

    test('an all-default override is NOT persisted (clears the row)',
        () async {
      final settings = _FakeSettings();
      final c = _container(settings);
      final ctrl = c.read(recordingProfileControllerProvider.notifier);

      await ctrl.setOverride('v1', const RecordingProfile(autoPin: true));
      expect(ctrl.overrideFor('v1'), isNotNull);

      // Resetting to all-default clears the override → falls back to global.
      await ctrl.setOverride('v1', RecordingProfile.defaults);
      expect(ctrl.overrideFor('v1'), isNull);
    });
  });
}
