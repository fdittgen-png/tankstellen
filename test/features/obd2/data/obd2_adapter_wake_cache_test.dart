// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/obd2/data/obd2_adapter_wake_cache.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import '../../../helpers/silence_error_logger.dart';

/// In-memory [SettingsStorage] double — mirrors the blocklist test's
/// fake so the wake cache sees a real store implementation.
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};

  @override
  dynamic getSetting(String key) => data[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    data[key] = value;
  }

  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

void main() {
  silenceErrorLoggerSpool();

  group('Obd2AdapterWakeCache (#2268 concern 3)', () {
    late _FakeSettingsStorage storage;
    late Obd2AdapterWakeCache cache;

    setUp(() {
      storage = _FakeSettingsStorage();
      cache = Obd2AdapterWakeCache(storage);
    });

    test('recall returns null on a never-observed MAC', () async {
      expect(await cache.recall('AA:BB:CC:DD:EE:FF'), isNull);
    });

    test('record(true) + recall round-trips wakeNeeded', () async {
      await cache.record('AA:BB:CC:DD:EE:FF', true);
      expect(await cache.recall('AA:BB:CC:DD:EE:FF'), isTrue);
    });

    test('record(false) + recall round-trips never-needed', () async {
      await cache.record('AA:BB:CC:DD:EE:FF', false);
      expect(await cache.recall('AA:BB:CC:DD:EE:FF'), isFalse);
    });

    test('keys are namespaced under obdAdapterWake: and lower-cased',
        () async {
      await cache.record('AA:BB:CC', true);
      expect(storage.data.keys, contains('obdAdapterWake:aa:bb:cc'));
    });

    test('MAC is keyed case-insensitively — same physical device', () async {
      await cache.record('AA:BB:CC', true);
      expect(await cache.recall('aa:bb:cc'), isTrue,
          reason: 'capitalisation must never split one device into two '
              'cache entries');
    });

    test('empty MAC is a no-op for both record and recall', () async {
      await cache.record('', true);
      expect(storage.data.keys, isEmpty);
      expect(await cache.recall(''), isNull);
    });

    test('a later observation overwrites the earlier one', () async {
      await cache.record('AA:BB:CC', true);
      await cache.record('AA:BB:CC', false);
      expect(await cache.recall('AA:BB:CC'), isFalse);
    });

    test('recall returns null on a non-bool legacy value (type drift)',
        () async {
      storage.data['obdAdapterWake:aa:bb:cc'] = 'corrupted';
      expect(await cache.recall('AA:BB:CC'), isNull);
    });

    group('entries() + clearEntry()', () {
      test('entries() is empty before anything is recorded', () async {
        expect(await cache.entries(), isEmpty);
      });

      test('entries() returns every recorded MAC with its flag', () async {
        await cache.record('aa', true);
        await cache.record('bb', false);
        final entries = await cache.entries();
        expect(entries.length, 2);
        expect(entries['aa'], isTrue);
        expect(entries['bb'], isFalse);
      });

      test('clearEntry removes the MAC from entries() and neutralises recall',
          () async {
        await cache.record('aa', true);
        await cache.record('bb', false);
        await cache.clearEntry('aa');
        final entries = await cache.entries();
        expect(entries.keys, isNot(contains('aa')));
        expect(entries.keys, contains('bb'));
        expect(await cache.recall('aa'), isNull);
      });
    });

    group('overrideFor — drives wake-window suppression (#2268)', () {
      test('a MAC recorded false yields a no-op suppression override',
          () async {
        await cache.record('aa', false);
        final override = await cache.overrideFor('aa');
        expect(override, isNotNull);
        expect(override!.isActive, isFalse,
            reason: 'a never-needed MAC must suppress the window via a '
                'no-op WakePolicy');
      });

      test('a MAC recorded true yields null (honour the adapter policy)',
          () async {
        await cache.record('aa', true);
        expect(await cache.overrideFor('aa'), isNull);
      });

      test('an unknown MAC yields null (honour the adapter policy)', () async {
        expect(await cache.overrideFor('never-seen'), isNull);
      });
    });

    group('recordObservation — only learns from observed outcomes (#2268)',
        () {
      test('answeredImmediately records never-needed (false)', () async {
        await cache.recordObservation('aa', WakeObservation.answeredImmediately);
        expect(await cache.recall('aa'), isFalse);
      });

      test('wokeAfterNudge records wakeNeeded (true)', () async {
        await cache.recordObservation('aa', WakeObservation.wokeAfterNudge);
        expect(await cache.recall('aa'), isTrue);
      });

      test('notRun records NOTHING — no evidence either way', () async {
        await cache.recordObservation('aa', WakeObservation.notRun);
        expect(await cache.recall('aa'), isNull);
        expect(storage.data.keys, isEmpty);
      });

      test('failed records NOTHING — a failed connect is not positive proof',
          () async {
        await cache.recordObservation('aa', WakeObservation.failed);
        expect(await cache.recall('aa'), isNull);
        expect(storage.data.keys, isEmpty);
      });
    });
  });
}
