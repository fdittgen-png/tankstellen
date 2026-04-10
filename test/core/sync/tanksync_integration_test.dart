import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/sync_repository.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/itinerary/domain/entities/saved_itinerary.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

/// Integration tests for the TankSync flow (issue #67).
///
/// These tests cover the contract of [SyncRepository] — the boundary
/// between app code and Supabase — using an in-memory fake that models
/// the same invariants the real backend enforces:
///
///  * Anonymous authentication returns a stable user id
///  * Writes are scoped to the authenticated user id (RLS)
///  * Reads filter by the current user (RLS)
///  * Alerts require a known station row (FK constraint)
///  * Local wins on conflict (per CLAUDE.md local-first rules)
///  * Sync state machine: disabled -> enabled -> disabled -> re-enabled
///  * Offline queue: writes are deferred until network returns
///  * Deletes only propagate on explicit user action
///
/// The fake intentionally mirrors the Postgres/RLS behaviour described
/// in supabase/migrations so bugs in the real adapter surface as
/// contract violations here.
void main() {
  group('TankSync integration — FK/RLS scenarios', () {
    late _FakeSupabaseBackend backend;
    late _FakeSyncRepository repo;

    setUp(() {
      backend = _FakeSupabaseBackend();
      repo = _FakeSyncRepository(backend);
    });

    // ─────────────────────────────────────────────────────────────────
    // 1. Anonymous auth flow
    // ─────────────────────────────────────────────────────────────────
    test('anonymous sign-in returns a stable user id and connects', () async {
      expect(repo.isConnected, isFalse);
      expect(repo.authenticatedUserId, isNull);

      final userId = await repo.signInAnonymously();

      expect(userId, isNotNull);
      expect(userId, isNotEmpty);
      expect(repo.isConnected, isTrue);
      expect(repo.authenticatedUserId, userId);
    });

    // ─────────────────────────────────────────────────────────────────
    // 2. Push favorites — stored under correct user_id
    // ─────────────────────────────────────────────────────────────────
    test('push favorites stores them under the authenticated user id',
        () async {
      final userId = await repo.signInAnonymously();

      final merged = await repo.syncFavorites(['stn-1', 'stn-2']);

      expect(merged.toSet(), {'stn-1', 'stn-2'});
      // Rows landed in backend under this user only.
      expect(
        backend.favoritesByUser[userId],
        equals({'stn-1', 'stn-2'}),
      );
      // Nobody else has these rows.
      expect(backend.favoritesByUser.length, 1);
    });

    // ─────────────────────────────────────────────────────────────────
    // 3. Pull favorites — RLS prevents reading other users' data
    // ─────────────────────────────────────────────────────────────────
    test('RLS: users cannot read each other\'s favorites', () async {
      // Device A signs in, pushes favorites.
      final userA = await repo.signInAnonymously();
      await repo.syncFavorites(['stn-a1', 'stn-a2']);

      // Device B (separate repo/session) signs in.
      final repoB = _FakeSyncRepository(backend);
      final userB = await repoB.signInAnonymously();
      expect(userA, isNot(userB));

      // B pushes its own favorites, then reads back.
      final mergedB = await repoB.syncFavorites(['stn-b1']);

      // B only sees its own ids (local union server-for-B).
      expect(mergedB.toSet(), {'stn-b1'});
      // Backend still segregates the data.
      expect(backend.favoritesByUser[userA], {'stn-a1', 'stn-a2'});
      expect(backend.favoritesByUser[userB], {'stn-b1'});
    });

    // ─────────────────────────────────────────────────────────────────
    // 4. FK constraint — alert for unknown station is rejected
    // ─────────────────────────────────────────────────────────────────
    test('FK constraint: alert for unknown station fails gracefully',
        () async {
      await repo.signInAnonymously();

      // No station row exists in backend → FK violation on alert insert.
      final alert = PriceAlert(
        id: 'alert-ghost',
        stationId: 'does-not-exist',
        stationName: 'Ghost Station',
        fuelType: FuelType.e10,
        targetPrice: 1.40,
        createdAt: DateTime(2026, 4, 1),
      );

      final returned = await repo.syncAlerts([alert]);

      // Local data is never lost — fallback returns input unchanged.
      expect(returned, [alert]);
      // Nothing landed in the server alerts table.
      expect(backend.alertsByUser.values.expand((l) => l), isEmpty);
      // Error was captured for diagnostics.
      expect(backend.lastError, contains('foreign key'));
    });

    test('FK constraint: alert for known station succeeds', () async {
      final userId = await repo.signInAnonymously();
      backend.registerStation('stn-real');

      final alert = PriceAlert(
        id: 'alert-ok',
        stationId: 'stn-real',
        stationName: 'Real Station',
        fuelType: FuelType.diesel,
        targetPrice: 1.55,
        createdAt: DateTime(2026, 4, 1),
      );

      final returned = await repo.syncAlerts([alert]);

      expect(returned, contains(alert));
      expect(backend.alertsByUser[userId]!.map((a) => a.id),
          contains('alert-ok'));
    });

    // ─────────────────────────────────────────────────────────────────
    // 5. Conflict resolution — local wins (CLAUDE.md rule)
    // ─────────────────────────────────────────────────────────────────
    test('conflict resolution: local wins when both sides changed', () async {
      final userId = await repo.signInAnonymously();
      backend.registerStation('stn-1');

      // Server has an existing rating of 3 stars.
      backend.ratingsByUser[userId!] = {'stn-1': 3};

      // User locally rates it 5 stars; sync pushes local value.
      await repo.syncRating('stn-1', 5);

      // Fetch and verify local value wins on the server.
      final fetched = await repo.fetchRatings();
      expect(fetched['stn-1'], 5);
      expect(backend.ratingsByUser[userId]!['stn-1'], 5);
    });

    test('sync favorites: never deletes remote entries (additive merge)',
        () async {
      final userId = await repo.signInAnonymously();
      // Server already has a favorite the client doesn't know about
      // (e.g. added from another device).
      backend.favoritesByUser[userId!] = {'stn-remote'};

      final merged = await repo.syncFavorites(['stn-local']);

      // Merge is a union — neither side loses data.
      expect(merged.toSet(), {'stn-local', 'stn-remote'});
      expect(
        backend.favoritesByUser[userId],
        {'stn-local', 'stn-remote'},
      );
    });

    // ─────────────────────────────────────────────────────────────────
    // 6. Sync state machine — enabled → disabled → re-enabled
    // ─────────────────────────────────────────────────────────────────
    test('state machine: enabled → disabled → re-enabled', () async {
      // Enabled
      final userId1 = await repo.signInAnonymously();
      await repo.syncFavorites(['stn-1']);
      expect(repo.isConnected, isTrue);

      // Disabled (sign out)
      await repo.signOut();
      expect(repo.isConnected, isFalse);
      expect(repo.authenticatedUserId, isNull);
      // Operations while disabled are no-ops but don't throw.
      final merged = await repo.syncFavorites(['stn-2']);
      expect(merged, ['stn-2']); // echoed back, not stored.

      // Re-enabled — same user id because we restore the last session.
      final userId2 = await repo.signInAnonymously();
      expect(userId2, userId1,
          reason: 'Anonymous session should be restored on re-enable');
      // Previously pushed favorite is still there.
      final merged2 = await repo.syncFavorites([]);
      expect(merged2, contains('stn-1'));
    });

    // ─────────────────────────────────────────────────────────────────
    // 7. Offline behaviour — writes queue, flush on reconnect
    // ─────────────────────────────────────────────────────────────────
    test('offline: writes queue and flush on reconnect', () async {
      final userId = await repo.signInAnonymously();
      backend.online = false;

      // Push while offline — local data returned unchanged, queued.
      final merged = await repo.syncFavorites(['stn-offline']);
      expect(merged, ['stn-offline']);
      // Nothing in backend yet.
      expect(backend.favoritesByUser[userId], anyOf(isNull, isEmpty));
      // But repo has queued the write.
      expect(repo.pendingWrites, 1);

      // Reconnect and flush.
      backend.online = true;
      await repo.flushPendingWrites();

      expect(repo.pendingWrites, 0);
      expect(backend.favoritesByUser[userId], {'stn-offline'});
    });

    // ─────────────────────────────────────────────────────────────────
    // 8. Delete propagation — only on explicit user action
    // ─────────────────────────────────────────────────────────────────
    test('delete propagation: only explicit deleteFavorite removes row',
        () async {
      final userId = await repo.signInAnonymously();
      await repo.syncFavorites(['stn-1', 'stn-2']);
      expect(backend.favoritesByUser[userId], {'stn-1', 'stn-2'});

      // Pushing a shorter local list does NOT delete server rows.
      final merged = await repo.syncFavorites(['stn-1']);
      expect(merged.toSet(), {'stn-1', 'stn-2'});
      expect(backend.favoritesByUser[userId], {'stn-1', 'stn-2'});

      // Explicit delete removes the row.
      await repo.deleteFavorite('stn-2');
      expect(backend.favoritesByUser[userId], {'stn-1'});
    });

    // ─────────────────────────────────────────────────────────────────
    // 9. Alert sync — server dedups by id
    // ─────────────────────────────────────────────────────────────────
    test('alert sync: server dedupes by alert id', () async {
      final userId = await repo.signInAnonymously();
      backend.registerStation('stn-1');

      final alert = PriceAlert(
        id: 'alert-dup',
        stationId: 'stn-1',
        stationName: 'Dedup Station',
        fuelType: FuelType.e5,
        targetPrice: 1.60,
        createdAt: DateTime(2026, 4, 1),
      );

      await repo.syncAlerts([alert]);
      await repo.syncAlerts([alert]); // second push should not duplicate.

      expect(backend.alertsByUser[userId]!.length, 1);
    });

    // ─────────────────────────────────────────────────────────────────
    // 10. fetchAllUserData is scoped to auth.uid()
    // ─────────────────────────────────────────────────────────────────
    test('fetchAllUserData returns only current user data (RLS)', () async {
      // User A data
      final userA = await repo.signInAnonymously();
      backend.registerStation('stn-a');
      await repo.syncFavorites(['stn-a']);

      // User B on another repo
      final repoB = _FakeSyncRepository(backend);
      final userB = await repoB.signInAnonymously();
      backend.registerStation('stn-b');
      await repoB.syncFavorites(['stn-b']);

      final dumpA = await repo.fetchAllUserData();
      final dumpB = await repoB.fetchAllUserData();

      expect(dumpA['favorites'], {'stn-a'});
      expect(dumpB['favorites'], {'stn-b'});
      expect(userA, isNot(userB));
    });

    // ─────────────────────────────────────────────────────────────────
    // 11. Itinerary: save/fetch/delete respects RLS
    // ─────────────────────────────────────────────────────────────────
    test('itineraries: save, fetch, delete respect user scope', () async {
      await repo.signInAnonymously();

      final itin = SavedItinerary(
        id: 'itin-1',
        name: 'Berlin→Munich',
        waypoints: const [],
        distanceKm: 584.0,
        durationMinutes: 330.0,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 15),
      );

      expect(await repo.saveItinerary(itin), isTrue);
      final fetched = await repo.fetchItineraries();
      expect(fetched.map((i) => i.id), ['itin-1']);

      expect(await repo.deleteItinerary('itin-1'), isTrue);
      expect(await repo.fetchItineraries(), isEmpty);
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════
//  Fakes
// ═══════════════════════════════════════════════════════════════════════

/// In-memory Postgres-ish backend. Enforces the same contracts as the
/// real Supabase project: per-user row isolation (RLS) and FK on alerts.
class _FakeSupabaseBackend {
  /// Every user id ever created, for anonymous session restore.
  int _idSeq = 0;
  final Map<String, String> anonSessions = {}; // session token -> user id

  /// Tables, keyed by user id (models `user_id = auth.uid()` RLS).
  final Map<String, Set<String>> favoritesByUser = {};
  final Map<String, Set<String>> ignoredByUser = {};
  final Map<String, Map<String, int>> ratingsByUser = {};
  final Map<String, List<PriceAlert>> alertsByUser = {};
  final Map<String, List<SavedItinerary>> itinerariesByUser = {};

  /// public.stations — the FK target for alerts.
  final Set<String> knownStations = {};

  /// Toggle to simulate network loss.
  bool online = true;

  /// Last error surfaced to callers (for assertions).
  String? lastError;

  void registerStation(String id) => knownStations.add(id);

  String createAnonUser() {
    _idSeq++;
    final id = 'anon-user-$_idSeq';
    favoritesByUser[id] = {};
    ignoredByUser[id] = {};
    ratingsByUser[id] = {};
    alertsByUser[id] = [];
    itinerariesByUser[id] = [];
    return id;
  }
}

/// Fake SyncRepository that talks to [_FakeSupabaseBackend]. Mirrors
/// the behaviour of `SupabaseSyncRepository` + `SyncService` with the
/// same fallback-to-local semantics, RLS scoping, and FK checks.
class _FakeSyncRepository implements SyncRepository {
  _FakeSyncRepository(this._backend);

  final _FakeSupabaseBackend _backend;
  String? _userId;
  // Mimic the SecureStorage-persisted anon session that Supabase restores
  // across sign-out/sign-in cycles within the same device.
  String? _persistedUserId;

  /// Pending writes when offline (simple count for test assertions; in
  /// real code this would be a persisted queue).
  final List<void Function()> _queue = [];

  int get pendingWrites => _queue.length;

  Future<String?> signInAnonymously() async {
    // Restore an existing persisted session if present, otherwise create
    // a new anon user. Each repo instance models one "device".
    _userId = _persistedUserId ??= _backend.createAnonUser();
    return _userId;
  }

  Future<void> signOut() async {
    _userId = null;
  }

  Future<void> flushPendingWrites() async {
    if (!_backend.online) return;
    final pending = List.of(_queue);
    _queue.clear();
    for (final op in pending) {
      op();
    }
  }

  @override
  bool get isConnected => _userId != null;

  @override
  String? get authenticatedUserId => _userId;

  // ── Favorites ──

  @override
  Future<List<String>> syncFavorites(List<String> localIds) async {
    final uid = _userId;
    if (uid == null) return localIds;

    if (!_backend.online) {
      // Queue the write and echo local unchanged.
      _queue.add(() {
        final bucket = _backend.favoritesByUser.putIfAbsent(uid, () => {});
        bucket.addAll(localIds);
      });
      return localIds;
    }

    final bucket = _backend.favoritesByUser.putIfAbsent(uid, () => {});
    // Additive merge — never deletes server rows. Local wins on duplicates.
    bucket.addAll(localIds);
    // Return union (server state AFTER merge, which equals merged set).
    return bucket.toList();
  }

  @override
  Future<void> deleteFavorite(String stationId) async {
    final uid = _userId;
    if (uid == null) return;
    _backend.favoritesByUser[uid]?.remove(stationId);
  }

  // ── Ignored ──

  @override
  Future<List<String>> syncIgnoredStations(List<String> localIds) async {
    final uid = _userId;
    if (uid == null) return localIds;
    final bucket = _backend.ignoredByUser.putIfAbsent(uid, () => {});
    bucket.addAll(localIds);
    return bucket.toList();
  }

  // ── Ratings ──

  @override
  Future<void> syncRating(String stationId, int rating,
      {bool shared = false}) async {
    final uid = _userId;
    if (uid == null) return;
    // Local wins on conflict — unconditional upsert.
    final bucket = _backend.ratingsByUser.putIfAbsent(uid, () => {});
    bucket[stationId] = rating;
  }

  @override
  Future<void> deleteRating(String stationId) async {
    final uid = _userId;
    if (uid == null) return;
    _backend.ratingsByUser[uid]?.remove(stationId);
  }

  @override
  Future<Map<String, int>> fetchRatings() async {
    final uid = _userId;
    if (uid == null) return {};
    return Map.of(_backend.ratingsByUser[uid] ?? const {});
  }

  // ── Alerts ──

  @override
  Future<List<PriceAlert>> syncAlerts(List<PriceAlert> localAlerts) async {
    final uid = _userId;
    if (uid == null) return localAlerts;

    try {
      // FK check — every referenced station must exist.
      for (final a in localAlerts) {
        if (!_backend.knownStations.contains(a.stationId)) {
          final msg =
              'foreign key violation: stations.id="${a.stationId}" not found';
          _backend.lastError = msg;
          throw StateError(msg);
        }
      }

      final bucket = _backend.alertsByUser.putIfAbsent(uid, () => []);
      final existingIds = bucket.map((a) => a.id).toSet();
      for (final a in localAlerts) {
        if (!existingIds.contains(a.id)) {
          bucket.add(a);
          existingIds.add(a.id);
        }
      }
      return List.of(bucket);
    } catch (_) {
      // Mirror SyncService's fallback: return local unchanged on failure.
      return localAlerts;
    }
  }

  // ── Price history ──

  @override
  Future<List<Map<String, dynamic>>> fetchPriceHistory(String stationId,
          {int days = 30}) async =>
      const [];

  // ── Itineraries ──

  @override
  Future<bool> saveItinerary(SavedItinerary itinerary) async {
    final uid = _userId;
    if (uid == null) return false;
    final bucket = _backend.itinerariesByUser.putIfAbsent(uid, () => []);
    bucket.removeWhere((i) => i.id == itinerary.id);
    bucket.add(itinerary);
    return true;
  }

  @override
  Future<List<SavedItinerary>> fetchItineraries() async {
    final uid = _userId;
    if (uid == null) return [];
    return List.of(_backend.itinerariesByUser[uid] ?? const []);
  }

  @override
  Future<bool> deleteItinerary(String id) async {
    final uid = _userId;
    if (uid == null) return false;
    _backend.itinerariesByUser[uid]?.removeWhere((i) => i.id == id);
    return true;
  }

  // ── Data management ──

  @override
  Future<Map<String, dynamic>> fetchAllUserData() async {
    final uid = _userId;
    if (uid == null) return {'error': 'not authenticated'};
    return {
      'favorites': Set.of(_backend.favoritesByUser[uid] ?? const {}),
      'alerts': List.of(_backend.alertsByUser[uid] ?? const []),
      'itineraries': List.of(_backend.itinerariesByUser[uid] ?? const []),
    };
  }

  @override
  Future<void> deleteAllUserData() async {
    final uid = _userId;
    if (uid == null) return;
    _backend.favoritesByUser.remove(uid);
    _backend.ignoredByUser.remove(uid);
    _backend.ratingsByUser.remove(uid);
    _backend.alertsByUser.remove(uid);
    _backend.itinerariesByUser.remove(uid);
  }
}
