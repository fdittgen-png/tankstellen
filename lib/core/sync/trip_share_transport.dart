// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/error_logger.dart';
import 'supabase_client.dart';

/// Outcome of a `TripSharesSync.shareWithEmail` call so the UI can show
/// a precise message instead of a generic failure. Re-exported by
/// `trip_shares_sync.dart` (its original home before #3747).
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

/// Minimal wire seam for the trip-share email flow (#3747), mirroring
/// the [SyncTransport] pattern (#3122): production passes nothing and
/// gets [SupabaseTripShareTransport.currentOrNull]; tests inject a fake
/// so the new-RPC path and the legacy fallback are unit-testable
/// without a live Supabase session.
abstract class TripShareTransport {
  /// The authenticated caller's user id.
  String get userId;

  /// `POST /rpc/[fn]` with [params]; returns the decoded response body.
  Future<dynamic> rpc(String fn, Map<String, dynamic> params);

  /// Upsert one `trip_shares` grant [row] resolving conflicts on
  /// [onConflict] (the legacy pre-v8 share path).
  Future<void> upsertShare(
    Map<String, dynamic> row, {
    required String onConflict,
  });
}

/// The production [TripShareTransport] over the live [TankSyncClient].
class SupabaseTripShareTransport implements TripShareTransport {
  final SupabaseClient _client;

  @override
  final String userId;

  SupabaseTripShareTransport._(this._client, this.userId);

  /// The transport for the current session, or `null` when the client
  /// is not initialised / no user is signed in.
  static TripShareTransport? currentOrNull() {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;
    return SupabaseTripShareTransport._(client, userId);
  }

  @override
  Future<dynamic> rpc(String fn, Map<String, dynamic> params) =>
      _client.rpc<dynamic>(fn, params: params);

  @override
  Future<void> upsertShare(
    Map<String, dynamic> row, {
    required String onConflict,
  }) =>
      _client.from('trip_shares').upsert(row, onConflict: onConflict);
}

/// True when [error] is PostgREST's "no such function" response — the
/// signal that the connected schema predates v8 (`share_trip_with_email`
/// missing on an older self-host), so the caller may fall back to the
/// legacy resolve+insert path. Anything else (permission denied,
/// network, …) is a real failure and must NOT trigger the fallback.
bool isMissingFunctionError(Object error) {
  if (error is! PostgrestException) return false;
  // PGRST202: PostgREST could not find the function in its schema
  // cache; 42883: Postgres undefined_function; 404: older PostgREST
  // versions surface a bare not-found for an unknown RPC.
  const missingFunctionCodes = {'PGRST202', '42883', '404'};
  return missingFunctionCodes.contains(error.code);
}

/// Pre-v8 self-host fallback for `TripSharesSync.shareWithEmail`:
/// resolve the email to a UUID via the legacy oracle RPC (still granted
/// EXECUTE on schemas older than v8), then insert the grant client-side
/// — byte-identical to the pre-#3747 wire behaviour. Failures are
/// logged and mapped to [TripShareResult.failed], never thrown.
Future<TripShareResult> legacyShareWithEmail(
  TripShareTransport wire,
  String tripId,
  String recipientEmail,
) async {
  try {
    final resolved = await wire.rpc(
      'resolve_share_recipient',
      {'recipient_email': recipientEmail},
    );
    if (resolved is! String || resolved.isEmpty) {
      return TripShareResult.recipientNotFound;
    }
    await wire.upsertShare(
      {
        'trip_id': tripId,
        'owner_id': wire.userId,
        'shared_with_id': resolved,
        'permission': 'read',
      },
      onConflict: 'trip_id,owner_id,shared_with_id',
    );
    debugPrint('TripSharesSync.shareWithEmail: shared $tripId (legacy)');
    return TripShareResult.shared;
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {
      'where': 'TripSharesSync.shareWithEmail legacy FAILED for $tripId'
    }));
    return TripShareResult.failed;
  }
}
