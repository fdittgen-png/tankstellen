// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Auth/sync seam types shared by [SyncState] and its tests — extracted
/// from `sync_provider.dart` (#3449) so the provider file stays under the
/// 400-line cap while gaining the relink-required state. `sync_provider.dart`
/// re-exports this file, so existing imports keep resolving.
library;

/// Signature for a sync-merge that takes the device's local ids and
/// returns the union (server ∪ local) — exactly the shape of
/// `FavoritesSync.merge` / `IgnoredStationsSync.merge`. Injected as a
/// seam so the pull-persist wiring (#3076) is unit-testable without a
/// live Supabase session.
typedef IdMergeFn = Future<List<String>> Function(List<String> localIds);

/// Signature for a ratings fetch returning the server's
/// `stationId → rating` map — the shape of `RatingsSync.fetchAll`.
/// Injected as a seam so the ratings pull-persist wiring (#3077) is
/// unit-testable without a live Supabase session (the real fetch
/// returns an empty map when unauthenticated, masking the wiring).
typedef RatingsFetchFn = Future<Map<String, int>> Function();

/// Signature for an email auth call (sign-up / sign-in / anonymous-upgrade)
/// returning the resulting user id (or `null`). Mirrors the static
/// `TankSyncClient.*` methods so the auth-branch selection in
/// `SyncState.signInWithEmail` is unit-testable without a live Supabase
/// session — the same seam shape #3076 introduced with [IdMergeFn].
typedef EmailAuthFn = Future<String?> Function(String email, String password);

/// Outcome of an email auth attempt, so the UI can distinguish a completed
/// sign-in from an anonymous upgrade whose email change is still
/// **pending server-side confirmation** (#3079). The UUID is already the
/// user's in every case, so data is never orphaned.
enum EmailAuthResult {
  /// Auth completed and the session now carries the email.
  completed,

  /// The anonymous account was upgraded in place but the server requires
  /// the user to click a confirmation link before the email is active.
  /// Their data is already safe under the unchanged UUID.
  confirmationPending,

  /// No user id came back (e.g. client not initialised) — nothing changed.
  failed,
}
