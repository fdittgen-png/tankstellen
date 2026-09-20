// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';
import 'package:tankstellen/features/fleet/api.dart';

import '../../../fakes/fake_storage_repository.dart';
import 'fake_fleet_transport.dart';

/// #4399 — the static half of the invite / join contract (ADR 0025
/// D1/D2/D3/D7), asserted on the SQL a self-hoster pastes AND on the
/// versioned migration, so neither can drift from the other (HARD RULE
/// #5), plus the one thing a string assertion cannot show: that the
/// tokens the SQL raises are the tokens `FleetJoinService` maps onto
/// named refusals.
///
/// The behavioural proof (an invite from org A cannot join org B; a
/// used/expired code is refused; an anonymous identity is refused; a
/// second attempt says `already_member`; `anon` cannot execute the RPC)
/// needs a live Postgres and runs with the live-RPC skill against the
/// maintainer project, then is pasted into the PR. What CI holds is:
///
///  1. `fleet_invites` exists, has RLS on, has NO policy, and the
///     default anon/authenticated table grants are revoked;
///  2. the PLAINTEXT code is never stored — only its hash;
///  3. every code-dependent failure is the SAME `invalid_code` token,
///     and the caller-only checks run BEFORE the code is looked up, so
///     an invite is not an oracle for org existence or membership;
///  4. the RPC's parameter name is the key the client puts on the wire;
///  5. every new function is SECURITY DEFINER, pins `search_path` and
///     carries the full three-line grant block;
///  6. every token the SQL raises reaches the user as its own named
///     reason, never the `unavailable` catch-all.
///
/// Each SQL assertion is mutation-checked at the bottom, so a regex
/// that matches nothing cannot pass vacuously (the
/// `source_scanning_tests_dont_execute` lesson).
void main() {
  const newFunctions = [
    'fleet_invite_hash',
    'fleet_create_invite',
    'fleet_join',
  ];

  final wizard = buildMigrationSql(const <String, bool>{});
  final migration =
      File('supabase/migrations/20260920000001_fleet_invites.sql')
          .readAsStringSync();

  /// The body of `CREATE OR REPLACE FUNCTION public.<name>(` up to its
  /// closing dollar quote.
  String functionBody(String sql, String name) {
    final start = sql.indexOf('CREATE OR REPLACE FUNCTION public.$name(');
    expect(start, greaterThanOrEqualTo(0), reason: '$name is not defined');
    final end = sql.indexOf('\$\$;', start);
    expect(end, greaterThan(start), reason: '$name has no closing quote');
    return sql.substring(start, end);
  }

  /// Every `RAISE EXCEPTION '<token>'` inside [body], in source order.
  List<String> raisedTokens(String body) => RegExp(r"RAISE EXCEPTION '(\w+)'")
      .allMatches(body)
      .map((m) => m.group(1)!)
      .toList();

  for (final (label, sql) in [
    ('wizard SQL', wizard),
    ('migration', migration),
  ]) {
    group('$label —', () {
      test('creates fleet_invites with RLS enabled', () {
        expect(sql, contains('CREATE TABLE IF NOT EXISTS public.fleet_invites'));
        expect(
          sql,
          contains('ALTER TABLE public.fleet_invites ENABLE ROW LEVEL SECURITY'),
        );
      });

      test('fleet_invites has NO policy and loses the default table '
          'grants — the definer functions are its only readers', () {
        expect(
          RegExp(r'CREATE POLICY\s+\w+\s+ON\s+public\.fleet_invites')
              .hasMatch(sql),
          isFalse,
          reason: 'a policy on fleet_invites would expose a code hash to a '
              'client; the RPCs are the only access path',
        );
        expect(
          sql,
          contains('REVOKE ALL ON TABLE public.fleet_invites '
              'FROM anon, authenticated;'),
          reason: 'RLS alone leaves the default privileges Supabase grants '
              'on every new public table',
        );
      });

      test('the plaintext code is never stored — the key is its hash', () {
        final start =
            sql.indexOf('CREATE TABLE IF NOT EXISTS public.fleet_invites');
        final ddl = sql.substring(start, sql.indexOf(');', start));
        expect(ddl, contains('code_hash TEXT PRIMARY KEY'));
        expect(
          RegExp(r'^\s+code\s+TEXT', multiLine: true).hasMatch(ddl),
          isFalse,
          reason: 'a plaintext `code` column would make a database dump '
              'replayable',
        );
        final issuer = functionBody(sql, 'fleet_create_invite');
        expect(
          issuer,
          contains('VALUES (public.fleet_invite_hash(v_code)'),
          reason: 'the issuer must insert the hash, never the code',
        );
      });

      test('an invite is bound to one org, expires, and has a use budget',
          () {
        final start =
            sql.indexOf('CREATE TABLE IF NOT EXISTS public.fleet_invites');
        final ddl = sql.substring(start, sql.indexOf(');', start));
        expect(ddl, contains('org_id UUID NOT NULL REFERENCES '
            'public.fleet_organizations(id) ON DELETE CASCADE'));
        expect(ddl, contains('expires_at TIMESTAMPTZ NOT NULL'));
        expect(ddl, contains('max_uses INTEGER NOT NULL DEFAULT 1'));
        expect(ddl, contains('uses INTEGER NOT NULL DEFAULT 0'));
      });

      test('fleet_join takes the parameter name the client puts on the '
          'wire — a p_code signature would 404 as PGRST202', () {
        expect(sql, contains('FUNCTION public.fleet_join(p_invite_code TEXT)'));
      });

      test('the caller-only checks run BEFORE the code is looked up', () {
        final body = functionBody(sql, 'fleet_join');
        final lookup = body.indexOf('public.fleet_invite_hash(p_invite_code)');
        expect(lookup, greaterThanOrEqualTo(0));
        for (final earlier in const [
          "'not_authenticated'",
          "'identity_required'",
          "'fleet_disabled'",
          "'already_member'",
        ]) {
          expect(body.indexOf(earlier), greaterThanOrEqualTo(0),
              reason: '$earlier is not raised at all');
          expect(body.indexOf(earlier), lessThan(lookup),
              reason: '$earlier is decided after the code is hashed — a '
                  'caller could use it to probe codes');
        }
      });

      test('every code-dependent failure is the one invalid_code token '
          '— no existence oracle', () {
        final body = functionBody(sql, 'fleet_join');
        expect(raisedTokens(body), const [
          'not_authenticated',
          'identity_required',
          'fleet_disabled',
          'already_member',
          'invalid_code',
        ], reason: 'the order and the set are both the contract');
        for (final leak in const [
          'invite_not_found',
          'invite_expired',
          'invite_used',
          'invite_revoked',
          'org_not_found',
          'not_found',
        ]) {
          expect(body, isNot(contains("'$leak'")),
              reason: '"$leak" tells a guesser their code once existed');
        }
        // One probe, one branch: unknown / expired / spent are the same
        // absent row, not three tested conditions with three answers.
        expect(body, contains('WHERE i.code_hash = v_hash'));
        expect(body, contains('AND i.expires_at > now()'));
        expect(body, contains('AND i.uses < i.max_uses'));
        expect(RegExp(r"RAISE EXCEPTION 'invalid_code'").allMatches(body),
            hasLength(1));
      });

      test('redeeming spends the invite, writes the member row and an '
          'audit event (D5.4)', () {
        final body = functionBody(sql, 'fleet_join');
        expect(body, contains('FOR UPDATE'),
            reason: 'two devices on a single-use code must serialise');
        expect(body, contains('SET uses = uses + 1'));
        expect(body, contains('INSERT INTO public.fleet_members'));
        expect(body, contains('INSERT INTO public.fleet_audit_events'));
        expect(body, contains('left(v_hash, 12)'),
            reason: 'the audit target must be a prefix of the HASH, never '
                'anything replayable');
      });

      test('issuing is manager/admin only and never grants more than the '
          'issuer holds', () {
        final body = functionBody(sql, 'fleet_create_invite');
        expect(body, contains('public.fleet_role(p_org)'));
        expect(body, contains("NOT IN ('manager', 'admin')"));
        expect(body, contains("IF v_role = 'admin' AND v_caller_role <> "
            "'admin' THEN"));
      });

      test('every new function is SECURITY DEFINER, pins search_path and '
          'carries the full grant block', () {
        for (final fn in newFunctions) {
          final body = functionBody(sql, fn);
          expect(body, contains('SECURITY DEFINER'), reason: fn);
          expect(body, contains('SET search_path = public'), reason: fn);
          expect(
            RegExp('REVOKE ALL ON FUNCTION public\\.$fn\\([^)]*\\) '
                    'FROM PUBLIC;')
                .hasMatch(sql),
            isTrue,
            reason: '$fn keeps the default PUBLIC execute grant',
          );
          expect(
            RegExp('GRANT EXECUTE ON FUNCTION public\\.$fn\\([^)]*\\) '
                    'TO authenticated;')
                .hasMatch(sql),
            isTrue,
            reason: '$fn is not callable by a signed-in user',
          );
          expect(
            RegExp('REVOKE EXECUTE ON FUNCTION public\\.$fn\\([^)]*\\) '
                    'FROM anon;')
                .hasMatch(sql),
            isTrue,
            reason: '$fn is not revoked from anon — the PUBLIC revoke does '
                'not cover it (a real finding in #4049)',
          );
        }
      });

      test('the hash needs no extension — sha256/encode/convert_to are '
          'core since PostgreSQL 11', () {
        final body = functionBody(sql, 'fleet_invite_hash');
        expect(body, contains('sha256('));
        expect(body, contains('encode('));
        expect(body, contains('convert_to('));
        expect(sql, isNot(contains('CREATE EXTENSION')));
        expect(sql, isNot(contains('gen_random_bytes(')),
            reason: 'gen_random_bytes is pgcrypto; gen_random_uuid is core');
      });
    });
  }

  test('the schema version was bumped so self-hosts are flagged', () {
    expect(kSupabaseSchemaVersion, 16);
    expect(migration, contains("VALUES ('schema_version', '16', now())"));
  });

  group('the tokens the SQL raises are the ones the client names', () {
    // The server contract read straight out of the SQL, paired with the
    // refusal the user is shown. A token the client does not recognise
    // would fall through to `unavailable` — one dead end instead of an
    // actionable sentence — so this pairing is the real interface.
    const expected = <String, FleetJoinFailure>{
      'not_authenticated': FleetJoinFailure.identityRequired,
      'identity_required': FleetJoinFailure.identityRequired,
      'fleet_disabled': FleetJoinFailure.notSupported,
      'already_member': FleetJoinFailure.alreadyMember,
      'invalid_code': FleetJoinFailure.invalidCode,
    };

    test('the SQL raises exactly the tokens this table covers', () {
      final raised = raisedTokens(functionBody(wizard, 'fleet_join')).toSet();
      expect(raised, expected.keys.toSet(),
          reason: 'a token added to fleet_join without a client mapping '
              'reaches the user as "unavailable"');
    });

    for (final entry in expected.entries) {
      test('"${entry.key}" reaches the user as ${entry.value.name}',
          () async {
        final transport = FakeFleetTransport(rpcErrors: {
          FleetJoinService.joinRpc: Exception(
            // The shape PostgREST hands the client: the raised message
            // inside a JSON error body.
            '{"code":"P0002","message":"${entry.key}"}',
          ),
        });
        final service = FleetJoinService(
          transport: transport,
          storage: FakeStorageRepository(),
        );

        final outcome = await service.joinWithInviteCode('ABCDE-12345');

        expect(outcome, isA<FleetJoinRefused>());
        expect((outcome as FleetJoinRefused).failure, entry.value);
        expect(outcome.failure, isNot(FleetJoinFailure.unavailable));
      });
    }

    test('the granted role in the RPC\'s JSON object reaches the '
        'membership, instead of the employee fallback', () async {
      final storage = FakeStorageRepository();
      final transport = FakeFleetTransport(rpcResults: {
        // jsonb_build_object('org_id', …, 'role', …) decoded.
        FleetJoinService.joinRpc: {
          'org_id': '11111111-2222-3333-4444-555555555555',
          'role': 'manager',
        },
      });

      final outcome = await FleetJoinService(
        transport: transport,
        storage: storage,
      ).joinWithInviteCode('ABCDE-12345');

      expect((outcome as FleetJoined).role, FleetRole.manager);
      expect(outcome.orgId, '11111111-2222-3333-4444-555555555555');
      expect(transport.rpcCalls.single.params.keys, ['p_invite_code'],
          reason: 'the SQL signature must match this key exactly');
    });
  });

  group('mutation checks — the assertions actually bite', () {
    test('a plaintext code column is caught', () {
      final broken = wizard.replaceFirst(
          '  code_hash TEXT PRIMARY KEY,', '  code TEXT PRIMARY KEY,');
      expect(broken, isNot(wizard), reason: 'the mutation must apply');
      final start =
          broken.indexOf('CREATE TABLE IF NOT EXISTS public.fleet_invites');
      final ddl = broken.substring(start, broken.indexOf(');', start));
      expect(ddl, isNot(contains('code_hash TEXT PRIMARY KEY')));
    });

    test('a distinct "expired" token is caught', () {
      final broken = wizard.replaceFirst(
          "    RAISE EXCEPTION 'invalid_code' USING ERRCODE = 'P0002';",
          "    RAISE EXCEPTION 'invite_expired' USING ERRCODE = 'P0002';");
      expect(broken, isNot(wizard));
      final body = functionBody(broken, 'fleet_join');
      expect(raisedTokens(body), isNot(contains('invalid_code')));
      expect(body, contains("'invite_expired'"));
    });

    test('a dropped anon revoke is caught', () {
      final broken = wizard.replaceFirst(
          'REVOKE EXECUTE ON FUNCTION public.fleet_join(TEXT) FROM anon;', '');
      expect(broken, isNot(wizard));
      expect(
        RegExp(r'REVOKE EXECUTE ON FUNCTION public\.fleet_join\([^)]*\) '
                r'FROM anon;')
            .hasMatch(broken),
        isFalse,
      );
    });

    test('a code lookup moved ahead of the operator switch is caught', () {
      final body = functionBody(wizard, 'fleet_join');
      final reordered = body.replaceFirst(
          '  v_hash := public.fleet_invite_hash(p_invite_code);', '');
      expect(reordered, isNot(body), reason: 'the mutation must apply');
      expect(reordered.indexOf('public.fleet_invite_hash(p_invite_code)'), -1,
          reason: 'the ordering assertion reads this exact anchor, so a '
              'rename must break it rather than pass silently');
    });
  });
}
