// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../data/storage_repository.dart';
import 'supabase_client.dart';

/// Thrown when cloud-sync setup is attempted without the Cloud Sync
/// consent (#4337). Raised before any network call.
class CloudSyncConsentRequired implements Exception {
  const CloudSyncConsentRequired();

  @override
  String toString() => 'CloudSyncConsentRequired: Cloud Sync consent is not '
      'given — nothing may be sent to the sync backend';
}

/// Open the client `SyncState.connect` sets up sync with, and return the
/// identity it should store (#4337).
///
/// * Without [consented], nothing happens: no client, no network call, no
///   identity — [CloudSyncConsentRequired] is thrown first. The setup
///   screen used to be reachable with the consent withdrawn (`enabled`
///   folds the consent in, so the section offered setup) and minted and
///   uploaded anyway.
/// * A session the SDK restored is the identity: it is returned as is.
/// * A stored `sync_user_id` with no session is NEVER papered over with a
///   fresh anonymous id — the #3449 orphaning trap. It throws a
///   [StateError] instead: the way back is re-linking (an email sign-in),
///   or an explicit "start fresh".
/// * Otherwise (a fresh device, or after a disconnect) a new anonymous
///   identity is minted.
Future<String?> openConnectSession(
  SettingsStorage storage,
  String url,
  String anonKey, {
  required bool consented,
}) async {
  if (!consented) throw const CloudSyncConsentRequired();
  await TankSyncClient.init(url: url, anonKey: anonKey);
  final sessionUserId = TankSyncClient.sessionUserId;
  if (sessionUserId != null) return sessionUserId;
  if (storage.getSetting('sync_user_id') != null) {
    throw StateError('TankSync: the stored identity has no session — '
        're-link it instead of minting a new one (#3449, #4337)');
  }
  return TankSyncClient.signInAnonymously();
}
