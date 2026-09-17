// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tanksync_relink_provider.g.dart';

/// Whether TankSync's stored identity needs re-linking — the owner of
/// `SyncConfig.relinkRequired` (#4338).
///
/// The flag used to live only on the `SyncConfig` object `SyncState`
/// published by hand, and `SyncState.build` never set it: the next
/// rebuild — a consent save, a storage swap, an `invalidate` — dropped it
/// while the session was still gone, and the re-link guidance vanished.
///
/// **Why keepAlive, and why not persisted.** It must outlive every rebuild
/// of `SyncState` in this process, so it cannot live inside it. It must
/// NOT outlive the process: whether a session is missing is re-derived at
/// every launch by the #3449 identity guard from what is actually on the
/// device, and a persisted flag would go stale the moment the keychain or
/// the settings changed underneath it (a restore, a reinstall).
///
/// Writers: the launch guard and the session gate's `signedOut` hook mark
/// it; an email sign-in, "start fresh" and disconnect clear it.
@Riverpod(keepAlive: true)
class TankSyncRelink extends _$TankSyncRelink {
  @override
  bool build() => false;

  /// A stored identity has no session.
  void mark() => state = true;

  /// The identity was re-linked, replaced knowingly, or disconnected.
  void clear() => state = false;
}
