// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../features/consumption/data/trip_history_repository.dart';
import '../../core/logging/error_logger.dart';
import 'supabase_client.dart';

/// One cross-account share grant — either a row I created (listing who
/// I've shared a trip with) or a row pointing at me (a trip shared
/// WITH me). Mirrors the `public.trip_shares` columns from the
/// migration in `supabase/migrations/20260529000001_trip_shares.sql`.
@immutable
class TripShare {
  /// The share-grant row id (`trip_shares.id`).
  final String id;

  /// The shared trip's `trip_summaries.id`.
  final String tripId;

  /// The owner account that granted the share.
  final String ownerId;

  /// The recipient account, or `null` for an unclaimed link/token
  /// share.
  final String? sharedWithId;

  /// The claim token for a link share, or `null` for a direct share.
  final String? shareToken;

  const TripShare({
    required this.id,
    required this.tripId,
    required this.ownerId,
    this.sharedWithId,
    this.shareToken,
  });

  /// Decode one `trip_shares` row. Returns `null` when the row is
  /// missing the non-null columns so a single malformed row never
  /// aborts a whole list.
  static TripShare? fromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final tripId = row['trip_id'];
    final ownerId = row['owner_id'];
    if (id is! String || tripId is! String || ownerId is! String) {
      return null;
    }
    final sharedWith = row['shared_with_id'];
    final token = row['share_token'];
    return TripShare(
      id: id,
      tripId: tripId,
      ownerId: ownerId,
      sharedWithId: sharedWith is String ? sharedWith : null,
      shareToken: token is String ? token : null,
    );
  }
}

/// Outcome of a [TripSharesSync.shareWithEmail] call so the UI can show
/// a precise message instead of a generic failure.
enum TripShareResult {
  /// The share row was created (recipient resolved + grant inserted).
  shared,

  /// No TankSync account matched the recipient email.
  recipientNotFound,

  /// The caller isn't signed into a TankSync account.
  notAuthenticated,

  /// The wire call threw — surfaced as a soft failure.
  failed,
}

/// Cross-account trip sharing wire helper (#2240).
///
/// Sibling to [TripsSync]. Where `TripsSync` moves a user's OWN trips
/// between their devices (RLS `user_id = auth.uid()`), this moves a
/// single trip ACROSS accounts via the `public.trip_shares` grant
/// table + its additive read policies.
///
/// Same do-no-harm contract as the other sync helpers:
/// - unauthenticated callers return a benign empty / failure result;
/// - wire failures are logged and swallowed — never thrown at the UI.
///
/// The TankSync consent gate (`tripSharesSyncEnabledProvider`, mirroring
/// `tripsSyncEnabled`) lives next to the toggle; this stays a pure I/O
/// helper whose `currentUser == null` early-return is only a safety net.
class TripSharesSync {
  TripSharesSync._();

  /// Share [tripId] with the account that owns [recipientEmail].
  ///
  /// Resolves the email → user id through the `resolve_share_recipient`
  /// SECURITY DEFINER RPC (clients can't read `auth.users` directly),
  /// then inserts a `read`-permission grant. Returns a [TripShareResult] so
  /// the sheet can distinguish "no such account" from a wire failure.
  static Future<TripShareResult> shareWithEmail(
    String tripId,
    String recipientEmail,
  ) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('TripSharesSync.shareWithEmail: not authenticated');
      return TripShareResult.notAuthenticated;
    }
    try {
      final resolved = await client.rpc<dynamic>(
        'resolve_share_recipient',
        params: {'recipient_email': recipientEmail},
      );
      if (resolved is! String || resolved.isEmpty) {
        return TripShareResult.recipientNotFound;
      }
      await client.from('trip_shares').upsert(
        {
          'trip_id': tripId,
          'owner_id': userId,
          'shared_with_id': resolved,
          'permission': 'read',
        },
        onConflict: 'trip_id,owner_id,shared_with_id',
      );
      debugPrint('TripSharesSync.shareWithEmail: shared $tripId');
      return TripShareResult.shared;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': 'TripSharesSync.shareWithEmail FAILED for $tripId'}));
      return TripShareResult.failed;
    }
  }

  /// Mint an unguessable link/token share for [tripId]. Inserts a row
  /// with a `share_token` and a null `shared_with_id` (the recipient
  /// claims it later via `claim_trip_share`). Returns the token on
  /// success, or `null` when unauthenticated or the insert fails — the
  /// caller wraps the token in a shareable link.
  static Future<String?> createShareLink(String tripId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('TripSharesSync.createShareLink: not authenticated');
      return null;
    }
    final token = generateShareToken();
    try {
      await client.from('trip_shares').insert({
        'trip_id': tripId,
        'owner_id': userId,
        'share_token': token,
        'permission': 'read',
      });
      debugPrint('TripSharesSync.createShareLink: minted token for $tripId');
      return token;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': 'TripSharesSync.createShareLink FAILED for $tripId'}));
      return null;
    }
  }

  /// Claim a link/token share so the current account becomes its
  /// recipient. Delegates to the `claim_trip_share` SECURITY DEFINER
  /// RPC (the recipient isn't the owner, so plain RLS would block the
  /// UPDATE). Returns `true` when a still-unclaimed token matched.
  static Future<bool> claimShareLink(String token) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('TripSharesSync.claimShareLink: not authenticated');
      return false;
    }
    try {
      final claimed = await client.rpc<dynamic>(
        'claim_trip_share',
        params: {'token': token},
      );
      return claimed is String && claimed.isNotEmpty;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'TripSharesSync.claimShareLink FAILED'}));
      return false;
    }
  }

  /// List the shares I created for [tripId] — i.e. who this trip is
  /// shared with. Powers the "shared with …" / revoke list in the
  /// share sheet. Empty when unauthenticated or on failure.
  static Future<List<TripShare>> listSharesForTrip(String tripId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const [];
    try {
      final rows = await client
          .from('trip_shares')
          .select('id, trip_id, owner_id, shared_with_id, share_token')
          .eq('owner_id', userId)
          .eq('trip_id', tripId);
      return parseShareRows(rows);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': 'TripSharesSync.listSharesForTrip FAILED for $tripId'}));
      return const [];
    }
  }

  /// Revoke a share I created (deletes the grant row). The recipient's
  /// additive read access drops as soon as the row is gone. Silent on
  /// failure — the owner can retry.
  static Future<void> revoke(String shareId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client
          .from('trip_shares')
          .delete()
          .eq('id', shareId)
          .eq('owner_id', userId);
      debugPrint('TripSharesSync.revoke: revoked $shareId');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': 'TripSharesSync.revoke FAILED for $shareId'}));
    }
  }

  /// Fetch the trips shared WITH me as read-only [TripHistoryEntry]s.
  ///
  /// Two-step, mirroring [TripsSync.merge]'s split: first read the
  /// grant rows pointing at me (`trip_shares.shared_with_id =
  /// auth.uid()`, allowed by the recipient SELECT policy), then read
  /// the matching `trip_summaries` rows — readable thanks to the
  /// additive `trip_summaries_shared_read` policy. Returns the decoded
  /// summary entries (samples empty — the heavy blob arrives on demand
  /// from `trip_details`, also recipient-readable). Empty when
  /// unauthenticated or on failure.
  static Future<List<TripHistoryEntry>> fetchSharedWithMe() async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const [];
    try {
      final shareRows = await client
          .from('trip_shares')
          .select('trip_id')
          .eq('shared_with_id', userId);
      final tripIds = <String>{};
      for (final r in shareRows) {
        final id = r['trip_id'];
        if (id is String) tripIds.add(id);
      }
      if (tripIds.isEmpty) return const [];

      // The additive `trip_summaries_shared_read` RLS policy is what
      // makes these rows visible despite their `user_id` being the
      // OWNER's, not mine — we filter by id, not by user_id.
      final summaryRows = await client
          .from('trip_summaries')
          .select('id, data')
          .inFilter('id', tripIds.toList());
      return parseSharedSummaries(summaryRows);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'TripSharesSync.fetchSharedWithMe FAILED'}));
      return const [];
    }
  }

  // ── Pure, testable seams ──────────────────────────────────────────

  /// Pure decode of the raw `trip_shares` rows into [TripShare]s,
  /// dropping any malformed row. Extracted so a unit test can pin the
  /// shape without a live client.
  @visibleForTesting
  static List<TripShare> parseShareRows(List<Map<String, dynamic>> rows) {
    final out = <TripShare>[];
    for (final r in rows) {
      final share = TripShare.fromRow(r);
      if (share != null) out.add(share);
    }
    return out;
  }

  /// Pure decode of `trip_summaries` rows shared with me into read-only
  /// [TripHistoryEntry]s. A row that fails to decode is dropped rather
  /// than aborting the list — same resilience as [TripsSync.mergeRows].
  @visibleForTesting
  static List<TripHistoryEntry> parseSharedSummaries(
    List<Map<String, dynamic>> rows,
  ) {
    final out = <TripHistoryEntry>[];
    for (final r in rows) {
      final data = r['data'];
      if (data is! Map) continue;
      try {
        out.add(TripHistoryEntry.fromJson(data.cast<String, dynamic>()));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.sync, e, st,
            context: {'where': 'TripSharesSync.parseSharedSummaries decode failed for ${r['id']}'}));
      }
    }
    return out;
  }

  /// Generate an unguessable URL-safe share token. 32 base32-ish chars
  /// from a [Random.secure] source — ~160 bits of entropy, plenty for
  /// a non-enumerable claim link. Extracted + visible so a test can
  /// assert the alphabet / length contract.
  @visibleForTesting
  static String generateShareToken({Random? random}) {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = random ?? Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < 32; i++) {
      buf.write(alphabet[rng.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }
}
