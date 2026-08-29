// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'sync_provider.dart';

/// Account deletion of [SyncState] (#3868, Epic #3865) — a part so the
/// provider file stays under the #1680 file-length cap.
extension SyncStateAccount on SyncState {
  /// Delete the user's account: wipe server data, sign out, clear local sync state.
  ///
  /// Works in every mode, including community (#3081). Every synced table's
  /// RLS policy is `FOR ALL USING (user_id = auth.uid())`, so
  /// [UserDataSync.deleteAll] can only ever remove the *caller's own* rows —
  /// deleting your own data can never reach another community user's rows in
  /// the shared database. The destructive UI action stays gated behind a
  /// confirmation dialog before this runs.
  Future<ServerErasureResult> deleteAccount() async {
    var result = const ServerErasureResult(failedTables: ['not-connected']);
    try {
      result = await UserDataSync.deleteAll();
      // #3712 — Play's account-deletion requirement: the auth identity
      // (e-mail) must go too, not just the data rows. The delete_user()
      // RPC (schema v6) deletes the caller's own auth.users record.
      // Best-effort in its own guard: a self-host schema older than v6
      // lacks the RPC, and the wipe + sign-out must still complete —
      // the verifier's version check flags the outdated schema.
      try {
        await TankSyncClient.client?.rpc<void>('delete_user');
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.sync, e, st,
            context: const {'where': 'delete_user RPC failed (schema < v6?)'}));
      }
      await TankSyncClient.signOut();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'Delete account failed'}));
    }
    await disconnect();
    return result;
  }
}
