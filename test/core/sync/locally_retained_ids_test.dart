// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/locally_retained_ids.dart';

import 'fake_sync_transport.dart';

/// Fault-path coverage for `LocallyRetainedIds.retain`'s "never throws"
/// contract (#4046, enforced by `test/lint/never_throws_contract_test.dart`),
/// plus the context scoping the retention set inherits from #4047.
///
/// Why the contract matters here specifically: `retain` is called from
/// `SyncedDataDeletion` **before** the server rows are deleted. If a
/// settings-box fault propagated out of it, the user's "delete my server
/// data, keep it here" action would abort half-done — and the failure mode
/// would be the exact one #4046 exists to prevent.
void main() {
  tearDown(LocallyRetainedIds.resetForTest);

  /// Swap the persistence seams for an in-memory blob.
  String? blob;
  void inMemory() {
    blob = null;
    LocallyRetainedIds.load = () => blob;
    LocallyRetainedIds.persist = (json) async => blob = json;
  }

  group('the happy path the fault tests are measured against', () {
    test('a retained id is readable back under the same transport', () async {
      inMemory();
      final t = FakeSyncTransport(userId: 'account-A', tables: {});
      await LocallyRetainedIds.retain('fill_ups', ['f1', 'f2'], transport: t);
      expect(LocallyRetainedIds.forTable('fill_ups', transport: t),
          {'f1', 'f2'});
    });

    test('and is invisible to a different account on the same backend',
        () async {
      inMemory();
      final a = FakeSyncTransport(userId: 'account-A', tables: {});
      final b = FakeSyncTransport(userId: 'account-B', tables: {});
      await LocallyRetainedIds.retain('fill_ups', ['f1'], transport: a);
      expect(LocallyRetainedIds.forTable('fill_ups', transport: b), isEmpty);
    });

    test('and to the same account on a different backend', () async {
      inMemory();
      final a = FakeSyncTransport(userId: 'u', tables: {})
        ..backendUrl = 'https://one.example';
      final b = FakeSyncTransport(userId: 'u', tables: {})
        ..backendUrl = 'https://two.example';
      await LocallyRetainedIds.retain('fill_ups', ['f1'], transport: a);
      expect(LocallyRetainedIds.forTable('fill_ups', transport: b), isEmpty);
    });

    test('release drops the retention so the set cannot grow unbounded',
        () async {
      inMemory();
      final t = FakeSyncTransport(userId: 'u', tables: {});
      await LocallyRetainedIds.retain('fill_ups', ['f1'], transport: t);
      await LocallyRetainedIds.release('fill_ups', ['f1'], transport: t);
      expect(LocallyRetainedIds.forTable('fill_ups', transport: t), isEmpty);
    });

    test('clearContext wipes the account on erasure', () async {
      inMemory();
      final t = FakeSyncTransport(userId: 'u', tables: {});
      await LocallyRetainedIds.retain('fill_ups', ['f1'], transport: t);
      await LocallyRetainedIds.clearContext(transport: t);
      expect(LocallyRetainedIds.forTable('fill_ups', transport: t), isEmpty);
    });
  });

  group('a settings box that throws on read', () {
    setUp(() {
      LocallyRetainedIds.load = () => throw StateError('box not open');
      LocallyRetainedIds.persist = (_) async {};
    });

    test('forTable reports "nothing retained" rather than throwing', () {
      final t = FakeSyncTransport(userId: 'u', tables: {});
      expect(() => LocallyRetainedIds.forTable('fill_ups', transport: t),
          returnsNormally);
      expect(LocallyRetainedIds.forTable('fill_ups', transport: t), isEmpty);
    });

    test('retain still completes', () async {
      final t = FakeSyncTransport(userId: 'u', tables: {});
      await expectLater(
          LocallyRetainedIds.retain('fill_ups', ['f1'], transport: t),
          completes);
    });
  });

  group('a settings box that throws on write', () {
    setUp(() {
      LocallyRetainedIds.load = () => null;
      LocallyRetainedIds.persist =
          (_) => Future<void>.error(StateError('disk is full'));
    });

    test('retain completes — the server delete it precedes still runs',
        () async {
      final t = FakeSyncTransport(userId: 'u', tables: {});
      await expectLater(
          LocallyRetainedIds.retain('fill_ups', ['f1'], transport: t),
          completes);
    });

    test('release and clearContext complete', () async {
      final t = FakeSyncTransport(userId: 'u', tables: {});
      await expectLater(
          LocallyRetainedIds.release('fill_ups', ['f1'], transport: t),
          completes);
      await expectLater(
          LocallyRetainedIds.clearContext(transport: t), completes);
    });
  });

  test('no transport yet — the unbound context, never another account\'s',
      () async {
    inMemory();
    final t = FakeSyncTransport(userId: 'u', tables: {});
    await LocallyRetainedIds.retain('fill_ups', ['f1']);
    expect(LocallyRetainedIds.forTable('fill_ups'), {'f1'});
    expect(LocallyRetainedIds.forTable('fill_ups', transport: t), isEmpty);
  });
}
