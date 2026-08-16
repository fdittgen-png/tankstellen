// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/content_reports_sync.dart';
import '../../helpers/silence_error_logger.dart';
import 'fake_sync_transport.dart';

/// #3726 — the in-app "Report content" write path (Play UGC policy).
///
/// Drives [ContentReportsSync.submit] through the injectable
/// [FakeSyncTransport] to pin the exact `content_reports` row shape the
/// RLS INSERT policy expects (`reporter_user_id = auth.uid()`), plus
/// the unauthenticated / offline do-no-harm guards.
void main() {
  silenceErrorLoggerSpool();

  group('ContentReportsSync.submit', () {
    test('writes one row naming the caller as reporter', () async {
      final transport = FakeSyncTransport(userId: 'reporter-1');
      final ok = await ContentReportsSync.submit(
        targetKind: ContentReportsSync.kindSharedTrip,
        targetId: 'trip-42',
        transport: transport,
      );
      expect(ok, isTrue);

      final rows = transport.upsertedRows('content_reports');
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row['reporter_user_id'], 'reporter-1',
          reason: 'RLS only accepts a report naming the caller');
      expect(row['target_kind'], 'trip_share');
      expect(row['target_id'], 'trip-42');
      expect(row.containsKey('reason'), isFalse,
          reason: 'no reason given → column omitted (stays NULL)');
      expect(row.containsKey('id'), isFalse,
          reason: 'the server mints the uuid — the client never picks ids');
    });

    test('carries a trimmed reason when one is given', () async {
      final transport = FakeSyncTransport(userId: 'reporter-1');
      await ContentReportsSync.submit(
        targetKind: ContentReportsSync.kindSharedTrip,
        targetId: 'trip-42',
        reason: '  offensive  ',
        transport: transport,
      );
      expect(
          transport.upsertedRows('content_reports').single['reason'],
          'offensive');
    });

    test('returns false when unauthenticated (no transport)', () async {
      expect(
        await ContentReportsSync.submit(
          targetKind: ContentReportsSync.kindSharedTrip,
          targetId: 'trip-42',
        ),
        isFalse,
        reason: 'no session → the caller must NOT claim the report was sent',
      );
    });

    test('returns false (never throws) when the write fails', () async {
      final transport = FakeSyncTransport(userId: 'reporter-1')
        ..failUpserts = true;
      expect(
        await ContentReportsSync.submit(
          targetKind: ContentReportsSync.kindSharedTrip,
          targetId: 'trip-42',
          transport: transport,
        ),
        isFalse,
      );
    });
  });
}
