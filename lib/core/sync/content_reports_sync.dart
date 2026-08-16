// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/error_logger.dart';
import 'sync_transport.dart';

/// Files in-app "Report content" rows against community user-generated
/// content (#3726 — the Play UGC-policy prerequisite for declaring UGC
/// in the IARC rating).
///
/// One-way write-only surface: the client only ever INSERTs a report
/// naming itself as the reporter (`reporter_user_id = auth.uid()`,
/// enforced by RLS); review happens on the self-host operator's side.
/// Rides the injectable [SyncTransport] seam (#3122) so a unit test can
/// pin the row shape without a live Supabase session.
class ContentReportsSync {
  ContentReportsSync._();

  static const _table = 'content_reports';

  /// `target_kind` for a cross-account shared trip (`trip_summaries`
  /// row read via a `trip_shares` grant).
  static const kindSharedTrip = 'trip_share';

  /// Submit one report. Returns `true` when the row reached the
  /// server, `false` when unauthenticated or the write failed — the
  /// caller surfaces the failure instead of silently claiming success.
  static Future<bool> submit({
    required String targetKind,
    required String targetId,
    String? reason,
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return false;

    try {
      // Insert-only in spirit: the row carries no `id`, so the server
      // mints a fresh uuid and the `onConflict` clause never fires.
      await t.upsert(
        _table,
        [
          {
            'reporter_user_id': t.userId,
            'target_kind': targetKind,
            'target_id': targetId,
            if (reason != null && reason.trim().isNotEmpty)
              'reason': reason.trim(),
            // `id` and `created_at` are minted server-side (uuid /
            // now() defaults) — the client never picks either.
          },
        ],
        onConflict: 'id',
      );
      debugPrint('ContentReportsSync.submit: $targetKind/$targetId reported');
      return true;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'ContentReportsSync.submit FAILED'}));
      return false;
    }
  }
}
