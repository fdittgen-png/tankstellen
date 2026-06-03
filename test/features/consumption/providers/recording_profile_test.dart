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
    test('defaults: autoPin ON (#2785), the rest OFF', () {
      const p = RecordingProfile.defaults;
      expect(p.autoPin, isTrue);
      expect(p.autoEnterReducedOnStart, isFalse);
      expect(p.keepScreenAwake, isFalse);
      expect(p.isDefault, isTrue);
      // autoPin implies the screen stays awake on start.
      expect(p.wantsScreenAwakeOnStart, isTrue);
    });

    test('isDefault compares against defaults — an autoPin-OFF profile is '
        'NOT the default (a real opt-out), so a per-vehicle row persists', () {
      expect(const RecordingProfile(autoPin: false).isDefault, isFalse);
      expect(const RecordingProfile().isDefault, isTrue);
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

    test('fromJson: missing autoPin defaults ON (#2785), other missing keys OFF',
        () {
      final p = RecordingProfile.fromJson(const {});
      expect(p.autoPin, isTrue, reason: 'absent autoPin → the true default');
      expect(p.autoEnterReducedOnStart, isFalse);
      expect(p.keepScreenAwake, isFalse);
    });

    test('fromJson honours a stored explicit autoPin:false (deliberate opt-out)',
        () {
      final p = RecordingProfile.fromJson(const {'autoPin': false});
      expect(p.autoPin, isFalse,
          reason: 'an explicitly-saved false must never be coerced back to true');
    });
  });

  group('RecordingProfileController persistence (#2274 concern 1)', () {
    test('absent payload reads the default profile (autoPin ON)', () {
      final settings = _FakeSettings();
      final c = _container(settings);
      final profile = c.read(recordingProfileControllerProvider);
      expect(profile, RecordingProfile.defaults);
      expect(profile.autoPin, isTrue);
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

      // Global: autoPin ON (the #2785 default). Vehicle v1 opts OUT
      // (autoPin OFF — a non-default override, so it is persisted).
      await ctrl.setGlobal(RecordingProfile.defaults);
      await ctrl.setOverride('v1', const RecordingProfile(autoPin: false));

      expect(ctrl.effectiveFor('v1').autoPin, isFalse,
          reason: 'vehicle override applies (opt-out wins over the global ON)');
      expect(ctrl.effectiveFor('v2').autoPin, isTrue,
          reason: 'unconfigured vehicle falls back to the global ON default');
      expect(ctrl.effectiveFor(null).autoPin, isTrue);
    });

    test('a matches-default override is NOT persisted (clears the row)',
        () async {
      final settings = _FakeSettings();
      final c = _container(settings);
      final ctrl = c.read(recordingProfileControllerProvider.notifier);

      // A non-default override (keepScreenAwake on) persists.
      await ctrl.setOverride(
          'v1', const RecordingProfile(keepScreenAwake: true));
      expect(ctrl.overrideFor('v1'), isNotNull);

      // Resetting to the default profile clears the override → global wins.
      await ctrl.setOverride('v1', RecordingProfile.defaults);
      expect(ctrl.overrideFor('v1'), isNull);
    });

    test('a per-vehicle autoPin:false override IS persisted (#2785 — a real '
        'opt-out is not mistaken for the default and silently dropped)',
        () async {
      final settings = _FakeSettings();
      final c = _container(settings);
      final ctrl = c.read(recordingProfileControllerProvider.notifier);

      await ctrl.setOverride('v1', const RecordingProfile(autoPin: false));
      expect(ctrl.overrideFor('v1'), isNotNull);
      expect(ctrl.effectiveFor('v1').autoPin, isFalse,
          reason: 'the vehicle keeps auto-pin OFF despite the global ON default');
    });
  });
}
