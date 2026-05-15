import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd_adapter_blocklist.dart';

/// In-memory [SettingsStorage] double for deterministic blocklist
/// tests. Mirrors the shape used by the populator and plein-complet
/// hook tests so the blocklist sees a real store implementation.
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
  group('ObdAdapterBlocklist', () {
    late _FakeSettingsStorage storage;
    late ObdAdapterBlocklist blocklist;

    setUp(() {
      storage = _FakeSettingsStorage();
      blocklist = ObdAdapterBlocklist(storage);
    });

    test('recall returns null on miss', () async {
      final v = await blocklist.recall('ELM327 v1.5');
      expect(v, isNull);
    });

    test('recordBelief + recall round-trips a confidence value', () async {
      await blocklist.recordBelief('ELM327 v1.5', 0.82);
      final v = await blocklist.recall('ELM327 v1.5');
      expect(v, closeTo(0.82, 1e-9));
    });

    test(
        'recordBelief is idempotent — second call with a different value '
        'overwrites the first', () async {
      await blocklist.recordBelief('ELM327 v1.5', 0.4);
      await blocklist.recordBelief('ELM327 v1.5', 0.9);
      final v = await blocklist.recall('ELM327 v1.5');
      expect(v, closeTo(0.9, 1e-9));
    });

    test('different ELM IDs are isolated in storage', () async {
      await blocklist.recordBelief('ELM327 v1.5', 0.85);
      await blocklist.recordBelief('STN1110 v4.0.4', 0.10);
      expect(await blocklist.recall('ELM327 v1.5'), closeTo(0.85, 1e-9));
      expect(await blocklist.recall('STN1110 v4.0.4'), closeTo(0.10, 1e-9));
    });

    test('empty ELM ID is a no-op for both record and recall', () async {
      await blocklist.recordBelief('', 0.99);
      // Record must not write anything.
      expect(storage.data.keys, isEmpty);
      // Recall on empty must be null without reading storage.
      expect(await blocklist.recall(''), isNull);
    });

    test('settings-box key is namespaced under obdAdapterBroken:', () async {
      await blocklist.recordBelief('ELM327 v2.2', 0.55);
      expect(storage.data.keys, contains('obdAdapterBroken:ELM327 v2.2'));
    });

    test(
        'recall tolerates legacy num values (int round-tripped to double)',
        () async {
      // Pre-existing entry stored as int (e.g. hand-edited or a stale
      // schema). Recall must coerce to double rather than crashing.
      storage.data['obdAdapterBroken:ELM327 v1.5'] = 1;
      final v = await blocklist.recall('ELM327 v1.5');
      expect(v, closeTo(1.0, 1e-9));
    });

    test('recall returns null on a non-numeric stored value', () async {
      storage.data['obdAdapterBroken:ELM327 v1.5'] = 'corrupted';
      final v = await blocklist.recall('ELM327 v1.5');
      expect(v, isNull);
    });

    // #1622 — list + clear surface for the diagnostics card.
    group('entries() + clearEntry() (#1622)', () {
      test('entries() is empty before anything is recorded', () async {
        expect(await blocklist.entries(), isEmpty);
      });

      test('entries() returns every recorded adapter with its confidence',
          () async {
        await blocklist.recordBelief('ELM327 v2.1', 0.85);
        await blocklist.recordBelief('STN1110 v4.0.4', 0.72);
        final entries = await blocklist.entries();
        expect(entries.length, 2);
        expect(entries['ELM327 v2.1'], closeTo(0.85, 1e-9));
        expect(entries['STN1110 v4.0.4'], closeTo(0.72, 1e-9));
      });

      test('recording the same adapter twice yields one index entry',
          () async {
        await blocklist.recordBelief('ELM327 v2.1', 0.5);
        await blocklist.recordBelief('ELM327 v2.1', 0.9);
        final entries = await blocklist.entries();
        expect(entries.length, 1);
        expect(entries['ELM327 v2.1'], closeTo(0.9, 1e-9));
      });

      test(
          'clearEntry removes the adapter from entries() AND neutralises '
          'recall', () async {
        await blocklist.recordBelief('ELM327 v2.1', 0.85);
        await blocklist.recordBelief('STN1110 v4.0.4', 0.72);

        await blocklist.clearEntry('ELM327 v2.1');

        final entries = await blocklist.entries();
        expect(entries.keys, isNot(contains('ELM327 v2.1')));
        expect(entries.keys, contains('STN1110 v4.0.4'));
        // recall must behave as if the adapter was never observed —
        // otherwise the populator keeps short-circuiting on a stale
        // warning.
        expect(await blocklist.recall('ELM327 v2.1'), isNull);
      });

      test('clearEntry on an unknown id does not throw', () async {
        await blocklist.recordBelief('ELM327 v2.1', 0.85);
        await blocklist.clearEntry('never-seen');
        expect((await blocklist.entries()).keys, contains('ELM327 v2.1'));
      });

      test('clearEntry with an empty id is a no-op', () async {
        await blocklist.recordBelief('ELM327 v2.1', 0.85);
        await blocklist.clearEntry('');
        expect((await blocklist.entries()).length, 1);
      });
    });
  });
}
