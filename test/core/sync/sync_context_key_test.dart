// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_context_key.dart';

/// Fault-path coverage for the `ScopedIdSets` "no method throws" contract
/// (#4047, enforced by `test/lint/never_throws_contract_test.dart`).
///
/// The contract is the whole point of the class: it backs two *resilience*
/// features — the durable deletion journal (#3123) and the after-wipe
/// retention set (#4046) — and both are called from the middle of a user
/// action. A settings-box fault while recording an intent must cost the
/// intent, never the delete the user asked for.
void main() {
  const ctx = SyncContextKey('example.org|user-1');

  group('SyncContextKey.of', () {
    test('collapses a null or empty backend to a stable placeholder', () {
      expect(SyncContextKey.of(backendUrl: null, userId: 'u').value,
          '(default)|u');
      expect(
          SyncContextKey.of(backendUrl: '', userId: 'u').value, '(default)|u');
    });

    test('reduces a URL to its lowercased host, so scheme and path drop', () {
      expect(
        SyncContextKey.of(backendUrl: 'https://ABC.supabase.co/', userId: 'u')
            .value,
        'abc.supabase.co|u',
      );
      expect(
        SyncContextKey.of(backendUrl: 'https://abc.supabase.co', userId: 'u'),
        SyncContextKey.of(backendUrl: 'https://ABC.supabase.co/rest/v1/',
            userId: 'u'),
      );
    });

    // #4058 — production hands us TankSyncClient.backendHost, which is
    // `uri.host`: a BARE host, no scheme. `Uri.parse('abc.supabase.co').host`
    // is '' (it parses as a path), so the first cut collapsed every real
    // key to '|<userId>' and the backend half was inert. These tests feed
    // the shape production actually sends.
    test('accepts the bare host TankSyncClient.backendHost really produces',
        () {
      expect(SyncContextKey.of(backendUrl: 'abc.supabase.co', userId: 'u').value,
          'abc.supabase.co|u');
      expect(SyncContextKey.of(backendUrl: 'ABC.Supabase.co', userId: 'u').value,
          'abc.supabase.co|u');
    });

    test('the bare host and its URL form are the SAME context', () {
      expect(
        SyncContextKey.of(backendUrl: 'abc.supabase.co', userId: 'u'),
        SyncContextKey.of(backendUrl: 'https://abc.supabase.co/', userId: 'u'),
      );
    });

    test('two bare hosts with the same user are DIFFERENT contexts', () {
      expect(
        SyncContextKey.of(backendUrl: 'a.example', userId: 'u'),
        isNot(SyncContextKey.of(backendUrl: 'b.example', userId: 'u')),
      );
    });

    test('a bare host never aliases the null-backend placeholder', () {
      expect(SyncContextKey.of(backendUrl: 'a.example', userId: 'u').value,
          isNot(startsWith('|')));
      expect(SyncContextKey.of(backendUrl: 'a.example', userId: 'u'),
          isNot(SyncContextKey.of(backendUrl: null, userId: 'u')));
    });

    test('separates the same account on two different backends', () {
      expect(
        SyncContextKey.of(backendUrl: 'https://a.example', userId: 'u'),
        isNot(SyncContextKey.of(backendUrl: 'https://b.example', userId: 'u')),
      );
    });
  });

  group('a load() that throws', () {
    ScopedIdSets sets() => ScopedIdSets(
          () => throw StateError('settings box is closed'),
          (_) async {},
        );

    test('reads degrade to empty instead of propagating', () {
      expect(() => sets().idsFor(ctx, 'favorites'), returnsNormally);
      expect(sets().idsFor(ctx, 'favorites'), isEmpty);
      expect(() => sets().tablesFor(ctx), returnsNormally);
      expect(() => sets().foreignContexts(ctx).toList(), returnsNormally);
    });

    test('writes still complete — the read fault does not surface', () async {
      await expectLater(sets().add(ctx, 'favorites', ['a']), completes);
      await expectLater(sets().remove(ctx, 'favorites', ['a']), completes);
      await expectLater(sets().clearContext(ctx), completes);
    });
  });

  group('a malformed blob', () {
    test('is treated as nothing recorded, not as a crash', () {
      final sets = ScopedIdSets(() => '{not json at all', (_) async {});
      expect(sets.idsFor(ctx, 'favorites'), isEmpty);
      expect(sets.tablesFor(ctx), isEmpty);
    });

    test('of the wrong SHAPE is ignored key by key', () {
      // Valid JSON, wrong types at every level: a string where a table map
      // belongs, a number where an id list belongs.
      final sets = ScopedIdSets(
        () => '{"example.org|user-1":{"favorites":7},"other":"nope"}',
        (_) async {},
      );
      expect(sets.idsFor(ctx, 'favorites'), isEmpty);
      expect(sets.foreignContexts(ctx), isEmpty);
    });
  });

  group('a persist() that throws', () {
    ScopedIdSets sets(String? stored) => ScopedIdSets(
          () => stored,
          (_) => Future<void>.error(StateError('disk is full')),
        );

    test('add completes — the caller\'s delete is not derailed', () async {
      await expectLater(sets(null).add(ctx, 'favorites', ['a']), completes);
    });

    test('remove completes', () async {
      await expectLater(
        sets('{"example.org|user-1":{"favorites":["a"]}}')
            .remove(ctx, 'favorites', ['a']),
        completes,
      );
    });

    test('clearContext completes', () async {
      await expectLater(
        sets('{"example.org|user-1":{"favorites":["a"]}}').clearContext(ctx),
        completes,
      );
    });
  });

  test('an empty id list is a no-op that never reaches persistence', () async {
    var persisted = false;
    final sets = ScopedIdSets(() => null, (_) async => persisted = true);
    await sets.add(ctx, 'favorites', const []);
    expect(persisted, isFalse);
  });
}
