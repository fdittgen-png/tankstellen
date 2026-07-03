// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/tanksync_init.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

/// #3449 — the launch identity guard. The forbidden move: a stored
/// `sync_user_id` with no live session gets silently replaced by a fresh
/// `signInAnonymously()` UUID, orphaning every server row the old
/// identity owns. The guard stands down (relinkRequired) instead; only a
/// fresh install (no stored id) may mint an anonymous identity.
void main() {
  silenceErrorLoggerSpool();

  late FakeHiveStorage storage;
  late List<String> calls;

  setUp(() {
    TankSyncInit.resetForTest();
    storage = FakeHiveStorage();
    calls = [];
  });

  Future<void> configureSync({String? storedUserId}) async {
    await storage.putSetting('sync_enabled', true);
    await storage.putSetting('supabase_url', 'https://test.supabase.co');
    await storage.setSupabaseAnonKey('key');
    if (storedUserId != null) {
      await storage.putSetting('sync_user_id', storedUserId);
    }
  }

  Future<TankSyncInitOutcome> run({
    String? sessionId,
    String? mintedAnonId,
  }) {
    var session = sessionId;
    return TankSyncInit.run(
      storage,
      init: ({required String url, required String anonKey}) async {
        calls.add('init');
      },
      sessionUserId: () => session,
      signInAnonymously: () async {
        calls.add('signInAnonymously');
        session = mintedAnonId;
        return mintedAnonId;
      },
      ensurePublicUser: (userId) async => calls.add('ensureUser:$userId'),
    );
  }

  group('#3449 identity guard', () {
    test('stored id + NO session → relinkRequired: no anonymous sign-in, '
        'stored id untouched', () async {
      await configureSync(storedUserId: 'old-uuid');

      final outcome = await run(sessionId: null, mintedAnonId: 'new-uuid');

      expect(outcome, TankSyncInitOutcome.relinkRequired);
      expect(TankSyncInit.lastOutcome, TankSyncInitOutcome.relinkRequired);
      expect(calls, isNot(contains('signInAnonymously')),
          reason: 'minting a fresh UUID would orphan every server row the '
              'stored identity owns — the exact #3449 bug');
      expect(storage.getSetting('sync_user_id'), 'old-uuid',
          reason: 'the stored identity must never be overwritten');
    });

    test('fresh install (no stored id) + no session → anonymous sign-in, '
        'minted id persisted (unchanged behaviour)', () async {
      await configureSync();

      final outcome = await run(sessionId: null, mintedAnonId: 'new-uuid');

      expect(outcome, TankSyncInitOutcome.ready);
      expect(calls, contains('signInAnonymously'));
      expect(storage.getSetting('sync_user_id'), 'new-uuid');
      expect(calls, contains('ensureUser:new-uuid'),
          reason: 'the public.users FK row must exist for the new id');
    });

    test('live session matching the stored id → ready, nothing rewritten',
        () async {
      await configureSync(storedUserId: 'uuid-1');

      final outcome = await run(sessionId: 'uuid-1');

      expect(outcome, TankSyncInitOutcome.ready);
      expect(calls, isNot(contains('signInAnonymously')));
      expect(storage.getSetting('sync_user_id'), 'uuid-1');
    });

    test('live session DIFFERING from the stored id (e.g. an email '
        'sign-in) → adopt the session id, as before', () async {
      await configureSync(storedUserId: 'old-uuid');

      final outcome = await run(sessionId: 'email-uuid');

      expect(outcome, TankSyncInitOutcome.ready);
      expect(storage.getSetting('sync_user_id'), 'email-uuid',
          reason: 'an existing session is authoritative — only the '
              'no-session path is guarded');
    });

    test('sync disabled / missing credentials → notConfigured without '
        'touching the client', () async {
      expect(await run(), TankSyncInitOutcome.notConfigured);
      expect(calls, isEmpty);

      await storage.putSetting('sync_enabled', true);
      expect(await run(), TankSyncInitOutcome.notConfigured,
          reason: 'enabled but no url/key stored');
      expect(calls, isEmpty);
    });

    test('a thrown init records failed (the #3450 retry trigger) and '
        'propagates to the caller\'s timeout telemetry', () async {
      await configureSync(storedUserId: 'old-uuid');

      await expectLater(
        TankSyncInit.run(
          storage,
          init: ({required String url, required String anonKey}) async {
            throw StateError('DNS down');
          },
          sessionUserId: () => null,
          signInAnonymously: () async => fail('must not be reached'),
          ensurePublicUser: (_) async {},
        ),
        throwsStateError,
      );
      expect(TankSyncInit.lastOutcome, TankSyncInitOutcome.failed);
    });

    test('a failing users-upsert is non-fatal (logged, still ready) — '
        'unchanged from the previous inline flow', () async {
      await configureSync(storedUserId: 'uuid-1');

      var session = 'uuid-1';
      final outcome = await TankSyncInit.run(
        storage,
        init: ({required String url, required String anonKey}) async {},
        sessionUserId: () => session,
        signInAnonymously: () async => session,
        ensurePublicUser: (_) async => throw StateError('RLS hiccup'),
      );

      expect(outcome, TankSyncInitOutcome.ready);
    });
  });
}
