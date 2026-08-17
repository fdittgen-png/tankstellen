// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tankstellen/core/sync/trip_share_transport.dart';

import '../../helpers/silence_error_logger.dart';
import 'fake_trip_share_transport.dart';

/// #3747 — the trip-share wire seam: the missing-function discriminator
/// that gates the pre-v8 fallback, and the fallback's own contract
/// (including the never-throws fault path).
void main() {
  silenceErrorLoggerSpool();

  group('isMissingFunctionError (#3747)', () {
    test('matches the PostgREST schema-cache miss (PGRST202)', () {
      expect(
        isMissingFunctionError(const PostgrestException(
          message: 'Could not find the function '
              'public.share_trip_with_email in the schema cache',
          code: 'PGRST202',
        )),
        isTrue,
      );
    });

    test('matches Postgres undefined_function (42883) and a bare 404', () {
      expect(
        isMissingFunctionError(const PostgrestException(
            message: 'function does not exist', code: '42883')),
        isTrue,
      );
      expect(
        isMissingFunctionError(
            const PostgrestException(message: 'Not Found', code: '404')),
        isTrue,
      );
    });

    test('does NOT match permission denied (42501) — a NEW schema that '
        'revoked the legacy oracle must not trigger the fallback', () {
      expect(
        isMissingFunctionError(const PostgrestException(
            message: 'permission denied for function '
                'resolve_share_recipient',
            code: '42501')),
        isFalse,
      );
    });

    test('does NOT match non-Postgrest errors', () {
      expect(isMissingFunctionError(Exception('socket closed')), isFalse);
      expect(isMissingFunctionError(StateError('boom')), isFalse);
    });
  });

  group('legacyShareWithEmail (#3747 pre-v8 fallback)', () {
    test('resolves the email then upserts the grant with owner_id = '
        'caller (byte-identical to the pre-#3747 wire path)', () async {
      final wire = FakeTripShareTransport(
        userId: 'owner-1',
        rpcResults: {'resolve_share_recipient': 'recipient-9'},
      );
      final result =
          await legacyShareWithEmail(wire, 'trip-1', 'A@Example.com ');
      expect(result, TripShareResult.shared);
      expect(wire.rpcCalls.single.fn, 'resolve_share_recipient');
      expect(wire.rpcCalls.single.params, {
        'recipient_email': 'A@Example.com ',
      });
      final upsert = wire.upsertCalls.single;
      expect(upsert.row, {
        'trip_id': 'trip-1',
        'owner_id': 'owner-1',
        'shared_with_id': 'recipient-9',
        'permission': 'read',
      });
      expect(upsert.onConflict, 'trip_id,owner_id,shared_with_id');
    });

    test('null / empty resolve → recipientNotFound, no upsert', () async {
      final wire = FakeTripShareTransport(); // resolve returns null
      expect(await legacyShareWithEmail(wire, 'trip-1', 'x@y.z'),
          TripShareResult.recipientNotFound);
      expect(wire.upsertCalls, isEmpty);
    });

    test('a throwing upsert maps to failed — never thrown (fault '
        'injection for the documented never-throws contract)', () async {
      final wire = FakeTripShareTransport(
        rpcResults: {'resolve_share_recipient': 'recipient-9'},
      )..failUpserts = true;
      await expectLater(
          legacyShareWithEmail(wire, 'trip-1', 'x@y.z'), completes);
      expect(await legacyShareWithEmail(wire, 'trip-1', 'x@y.z'),
          TripShareResult.failed);
    });

    test('a throwing resolve RPC maps to failed — never thrown', () async {
      final wire = FakeTripShareTransport(rpcErrors: {
        'resolve_share_recipient': Exception('wire down'),
      });
      expect(await legacyShareWithEmail(wire, 'trip-1', 'x@y.z'),
          TripShareResult.failed);
    });
  });
}
