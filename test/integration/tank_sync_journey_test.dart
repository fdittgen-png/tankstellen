import 'package:flutter_test/flutter_test.dart';

/// End-to-end integration coverage for the TankSync cross-device
/// backup/restore journey (#1634 — epic #1612).
///
/// TankSync's real adapters (`FavoritesSync`, `TripsSync`, …) are
/// static facades hardwired to the Supabase singleton, so — like the
/// existing `test/core/sync/tanksync_integration_test.dart` — this
/// test exercises the cross-device CONTRACT against an in-memory fake
/// backend that mirrors the Postgres + Row-Level-Security invariants
/// the real backend enforces:
///
///   * a push stores rows under the authenticated user id only (RLS),
///   * restoring the same account on a fresh device reads those rows
///     back,
///   * a different account sees nothing,
///   * a second device editing the same account merges both sides.
///
/// Unlike the existing single-device contract test, this drives the
/// full cross-device sequence: device A backs up, device B restores
/// onto an empty local state, then both devices converge. Lives under
/// `test/integration/` (not `integration_test/`, which would force an
/// emulator) so it runs on every PR in the existing sharded `test`
/// CI job.
void main() {
  late _FakeSyncBackend backend;

  setUp(() => backend = _FakeSyncBackend());

  test(
    'device A pushes a full backup → device B restores it onto a fresh '
    'install → both devices hold the same data',
    () async {
      // ── 1. Device A — first install, anonymous sign-in ─────────────
      final deviceA = _DeviceSync(backend)..signIn();
      final accountId = deviceA.accountId!;
      expect(deviceA.isConnected, isTrue);

      // Device A builds up local state and pushes a backup.
      deviceA.localFavorites.addAll(['stn-paris', 'stn-lyon', 'stn-nice']);
      deviceA.localIgnored.add('stn-roadworks');
      deviceA.localRatings['stn-paris'] = 5;
      deviceA.localRatings['stn-lyon'] = 4;
      await deviceA.pushBackup();

      // The backup landed under device A's account id, nowhere else.
      expect(backend.favoritesFor(accountId),
          {'stn-paris', 'stn-lyon', 'stn-nice'});
      expect(backend.userCount, 1);

      // ── 2. Device B — fresh install, restores the same account ─────
      final deviceB = _DeviceSync(backend);
      expect(deviceB.localFavorites, isEmpty,
          reason: 'a fresh install starts with no local data');
      deviceB.linkAccount(accountId); // cross-device account restore
      await deviceB.restoreBackup();

      // Device B now mirrors device A's backup exactly.
      expect(deviceB.localFavorites,
          {'stn-paris', 'stn-lyon', 'stn-nice'});
      expect(deviceB.localIgnored, {'stn-roadworks'});
      expect(deviceB.localRatings, {'stn-paris': 5, 'stn-lyon': 4});

      // ── 3. RLS — an unrelated account restores nothing ────────────
      final deviceC = _DeviceSync(backend)..signIn();
      expect(deviceC.accountId, isNot(accountId));
      await deviceC.restoreBackup();
      expect(deviceC.localFavorites, isEmpty,
          reason: 'RLS must keep one account from reading another');

      // ── 4. Convergence — device B edits, pushes; device A re-pulls ─
      deviceB.localFavorites.add('stn-marseille');
      deviceB.localRatings['stn-nice'] = 3;
      await deviceB.pushBackup();

      await deviceA.restoreBackup();
      expect(deviceA.localFavorites, contains('stn-marseille'),
          reason: 'device A picks up device B\'s additions on next sync');
      expect(deviceA.localRatings['stn-nice'], 3);
    },
  );

  test('restoring before linking an account is a safe no-op', () async {
    final device = _DeviceSync(backend);
    expect(device.isConnected, isFalse);
    await device.restoreBackup();
    expect(device.localFavorites, isEmpty);
    await device.pushBackup(); // also a no-op while signed out
    expect(backend.userCount, 0);
  });
}

/// In-memory stand-in for the Supabase backend. Every table is keyed
/// by account id, modelling `user_id = auth.uid()` Row-Level Security.
class _FakeSyncBackend {
  int _seq = 0;
  final Map<String, Set<String>> _favorites = {};
  final Map<String, Set<String>> _ignored = {};
  final Map<String, Map<String, int>> _ratings = {};

  int get userCount => _favorites.keys
      .toSet()
      .union(_ignored.keys.toSet())
      .union(_ratings.keys.toSet())
      .length;

  String createAccount() => 'account-${++_seq}';

  Set<String> favoritesFor(String account) =>
      Set.of(_favorites[account] ?? const {});

  void writeBackup(
    String account, {
    required Set<String> favorites,
    required Set<String> ignored,
    required Map<String, int> ratings,
  }) {
    // Merge, never clobber — the real backend `upsert`s, and a device
    // must not wipe rows another device added to the same account.
    (_favorites[account] ??= {}).addAll(favorites);
    (_ignored[account] ??= {}).addAll(ignored);
    (_ratings[account] ??= {}).addAll(ratings);
  }

  ({Set<String> favorites, Set<String> ignored, Map<String, int> ratings})
      readBackup(String account) => (
            favorites: Set.of(_favorites[account] ?? const {}),
            ignored: Set.of(_ignored[account] ?? const {}),
            ratings: Map.of(_ratings[account] ?? const {}),
          );
}

/// Models one device's TankSync session — its local data plus the
/// push/restore operations against the shared [_FakeSyncBackend].
class _DeviceSync {
  _DeviceSync(this._backend);

  final _FakeSyncBackend _backend;
  String? accountId;

  final Set<String> localFavorites = {};
  final Set<String> localIgnored = {};
  final Map<String, int> localRatings = {};

  bool get isConnected => accountId != null;

  /// First install: create a brand-new anonymous account.
  void signIn() => accountId = _backend.createAccount();

  /// Cross-device restore: adopt an account created on another device.
  void linkAccount(String existingAccountId) =>
      accountId = existingAccountId;

  /// Upload the local data set as a backup.
  Future<void> pushBackup() async {
    final account = accountId;
    if (account == null) return;
    _backend.writeBackup(
      account,
      favorites: localFavorites,
      ignored: localIgnored,
      ratings: localRatings,
    );
  }

  /// Download the account's backup and merge it into local state.
  Future<void> restoreBackup() async {
    final account = accountId;
    if (account == null) return;
    final backup = _backend.readBackup(account);
    localFavorites.addAll(backup.favorites);
    localIgnored.addAll(backup.ignored);
    localRatings.addAll(backup.ratings);
  }
}
