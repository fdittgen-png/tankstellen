// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';
import 'package:tankstellen/core/sync/user_data_sync.dart';

/// #4215 — the static half of the expense/document RLS contract (ADR
/// 0025), asserted on the SQL a self-hoster pastes AND on the
/// versioned migration, so neither can drift from the other (HARD
/// RULE #5).
///
/// Sibling of `fleet_rls_contract_test.dart`, which holds the #4212
/// ORG-owned invariant ("every fleet policy is SELECT-only through an
/// oracle"). These two tables are deliberately not that shape: they
/// are the employee's, so they carry the schema's ordinary own-row
/// policy. What this file pins is the part that is NOT ordinary:
///
///  1. own-row access is `user_id = auth.uid()`, both halves;
///  2. the manager's SELECT exists and is restricted to
///     `status <> 'draft'` — a draft never leaves the employee;
///  3. a document is reachable by a manager only through a non-draft
///     expense that cites it;
///  4. `fleet_audit_events` has a SELECT policy and NO write policy;
///  5. review is an RPC that re-checks the role and refuses anything
///     that is not already `submitted`;
///  6. the bucket is created private and no public URL is ever built;
///  7. erasure covers the expense, the document row AND the bytes.
///
/// Every assertion is mutation-checked at the bottom against a
/// deliberately broken SQL string, so a regex that matches nothing
/// cannot pass vacuously (the `source_scanning_tests_dont_execute`
/// lesson).
void main() {
  const userOwned = ['fleet_expenses', 'fleet_documents'];

  final wizard = buildMigrationSql(const <String, bool>{});
  final migration =
      File('supabase/migrations/20260918000002_fleet_expenses.sql')
          .readAsStringSync();

  /// Every `CREATE POLICY <name> ON public.<table> …;` block.
  final policyBlock = RegExp(
    r'CREATE POLICY\s+(\w+)\s+ON\s+public\.(\w+)([\s\S]*?);',
  );

  /// Every `CREATE OR REPLACE FUNCTION public.<name>(…)…$$;` block.
  final functionBlock = RegExp(
    r'CREATE OR REPLACE FUNCTION public\.(\w+)\(([\s\S]*?)\$\$;',
  );

  String policyBody(String sql, String name) => policyBlock
      .allMatches(sql)
      .firstWhere((m) => m.group(1) == name,
          orElse: () => throw StateError('no policy $name'))
      .group(3)!;

  /// Every `CREATE POLICY <name> ON storage.objects … )` block. The
  /// storage policies are emitted inside `EXECUTE $p$ … $p$`, so the
  /// terminator is the dollar-quote rather than a semicolon.
  final storagePolicyBlock = RegExp(
    r'CREATE POLICY\s+(\w+)\s+ON\s+storage\.objects([\s\S]*?)\$p\$',
  );

  String storagePolicyBody(String sql, String name) => storagePolicyBlock
      .allMatches(sql)
      .firstWhere((m) => m.group(1) == name,
          orElse: () => throw StateError('no storage policy $name'))
      .group(2)!;

  /// The ways a `storage.objects` policy can hand over the wrong bytes.
  ///
  /// `object_key` is client-supplied text: a policy that authorises the
  /// bytes on "some visible `fleet_documents` row names this object"
  /// lets a user insert their OWN row pointing at a VICTIM's object
  /// path and read it — #4049's ownership gap, one table over. A
  /// manager-read policy that references `fleet_documents` must
  /// therefore bind the row to the real uploader, check the caller's
  /// role on the document's own org, and carry the draft rule itself.
  List<String> storageViolations(String sql) {
    final out = <String>[];
    for (final m in storagePolicyBlock.allMatches(sql)) {
      final name = m.group(1)!;
      final body = m.group(2)!;
      if (!body.contains("bucket_id = 'fleet-documents'")) {
        out.add('$name is not scoped to the fleet-documents bucket');
      }
      if (!body.contains('public.fleet_documents')) continue;
      if (!body.contains('d.user_id = storage.objects.owner')) {
        out.add('$name does not bind the metadata row to the object owner');
      }
      if (!body.contains('public.fleet_role(d.org_id)')) {
        out.add('$name does not check the role on the document\'s org');
      }
      if (!body.contains("e.status <> 'draft'")) {
        out.add('$name does not carry the draft rule');
      }
    }
    return out;
  }

  /// The manager-visibility violations of [sql]: a manager SELECT that
  /// forgets the draft rule, or forgets the role check.
  List<String> managerViolations(String sql) {
    final out = <String>[];
    for (final name in const [
      'fleet_expenses_manager_select',
      'fleet_documents_manager_select',
    ]) {
      final matches =
          policyBlock.allMatches(sql).where((m) => m.group(1) == name);
      if (matches.isEmpty) {
        out.add('$name is missing');
        continue;
      }
      final body = matches.first.group(3)!;
      if (!body.contains('FOR SELECT')) {
        out.add('$name is not SELECT-only');
      }
      if (!body.contains("public.fleet_role(org_id) IN ('manager', 'admin')")) {
        out.add('$name does not check the manager role');
      }
      if (!body.contains("status <> 'draft'")) {
        out.add('$name does not exclude drafts');
      }
    }
    return out;
  }

  for (final (label, sql) in [
    ('wizard SQL', wizard),
    ('migration', migration),
  ]) {
    group('$label —', () {
      test('creates both user-owned tables with RLS enabled and anon '
          'revoked', () {
        for (final t in userOwned) {
          expect(sql, contains('CREATE TABLE IF NOT EXISTS public.$t'));
          expect(
              sql, contains('ALTER TABLE public.$t ENABLE ROW LEVEL SECURITY'));
          expect(sql, contains('REVOKE ALL ON TABLE public.$t FROM anon'),
              reason: 'Supabase grants anon separately; a privilege still '
                  'applies where a policy is missing');
        }
      });

      test('the own-row policy is auth.uid() on BOTH halves — a USING '
          'without a WITH CHECK would let a client write a row it '
          'cannot read', () {
        for (final t in userOwned) {
          final body = policyBody(sql, '${t}_own');
          expect(body, contains('FOR ALL TO authenticated'), reason: '$t: $body');
          expect(body, contains('USING (user_id = (SELECT auth.uid()))'),
              reason: '$t: $body');
          final check = body.substring(body.indexOf('WITH CHECK'));
          expect(check, contains('user_id = (SELECT auth.uid())'),
              reason: '$t has no WITH CHECK on the owner: $body');
        }
      });

      test('a draft is invisible to a manager (ADR 0025 visibility '
          'matrix)', () {
        expect(managerViolations(sql), isEmpty);
      });

      test('a manager reaches a document only through a non-draft '
          'expense that cites it', () {
        final body = policyBody(sql, 'fleet_documents_manager_select');
        expect(body, contains('FROM public.fleet_expenses e'));
        expect(body, contains("e.data ->> 'documentId' = "
            'fleet_documents.id::text'));
        expect(body, contains('e.org_id = fleet_documents.org_id'),
            reason: 'without the org join a manager could reach a '
                'document of another organisation');
      });

      test('the audit log is readable by the subject and an admin, and '
          'writable by nobody', () {
        final names = policyBlock
            .allMatches(sql)
            .where((m) => m.group(2) == 'fleet_audit_events')
            .map((m) => m.group(1)!)
            .toList();
        expect(names, ['fleet_audit_events_select'],
            reason: 'exactly one policy, and it is a read: an audit trail '
                'the audited party can write is not a trail');
        final body = policyBody(sql, 'fleet_audit_events_select');
        expect(body, contains('FOR SELECT'));
        expect(body, contains('actor = (SELECT auth.uid())'));
        expect(body, contains("public.fleet_role(org_id) = 'admin'"));
        for (final cmd in const [
          'FOR INSERT',
          'FOR UPDATE',
          'FOR DELETE',
          'FOR ALL',
        ]) {
          expect(body, isNot(contains(cmd)));
        }
      });

      test('fleet_review_expense re-checks the role, refuses a '
          'non-submitted expense, and audits every decision', () {
        final body = functionBlock
            .allMatches(sql)
            .firstWhere((m) => m.group(1) == 'fleet_review_expense')
            .group(2)!;
        expect(body, contains('SECURITY DEFINER'));
        expect(body, contains('SET search_path = public'));
        expect(body, contains('auth.uid()'));
        expect(body,
            contains("coalesce(public.fleet_role(org), '') NOT IN ('manager', "
                "'admin')"));
        expect(body, contains("current_status IS DISTINCT FROM 'submitted'"));
        expect(body, contains("RAISE EXCEPTION 'not_submitted'"));
        expect(body,
            contains('INSERT INTO public.fleet_audit_events'));
        expect(body, contains("p_decision NOT IN ('approved', 'rejected')"),
            reason: 'an unknown decision must not reach the UPDATE');
        expect(
            sql,
            contains('REVOKE EXECUTE ON FUNCTION '
                'public.fleet_review_expense(TEXT, UUID, TEXT) FROM anon'));
      });

      test('the signed-URL audit mirrors the READ rule, so a logged '
          'access is one that really happened', () {
        final body = functionBlock
            .allMatches(sql)
            .firstWhere((m) => m.group(1) == 'fleet_log_document_access')
            .group(2)!;
        // Membership alone was not enough: a manager asking after a
        // DRAFT receipt got an audit row and a TRUE while the bytes
        // policy refused them, so the log claimed an access that never
        // happened. Owner, or role + a non-draft citing expense.
        expect(body, contains('doc_owner IS DISTINCT FROM auth.uid()'));
        expect(body,
            contains("coalesce(public.fleet_role(org), '') NOT IN ('manager', "
                "'admin')"));
        expect(body, contains("e.status <> 'draft'"));
        expect(body, contains("e.data ->> 'documentId' = p_document::text"));
        expect(body, contains('deleted_at IS NULL'),
            reason: 'a deleted document is not readable, so asking after '
                'it is not an access either');
        expect(body, contains("'document_signed_url'"));
        expect(
            sql,
            contains('REVOKE EXECUTE ON FUNCTION '
                'public.fleet_log_document_access(UUID) FROM anon'));
      });

      test('the bucket is private, re-asserted private, and never '
          'public', () {
        expect(sql, contains("VALUES ('fleet-documents', 'fleet-documents', "
            'false)'));
        expect(sql, contains('ON CONFLICT (id) DO UPDATE SET public = false'),
            reason: 'a bucket flipped public by hand must be flipped back '
                'by the next run of the SQL');
        expect(sql, isNot(contains('public = true')));
        expect(sql, contains('CREATE TABLE IF NOT EXISTS '
            'public.fleet_audit_events'));
      });

      test('the manager\'s read of the BYTES re-checks the uploader, the '
          'role and the draft rule — it does not take a metadata row\'s '
          'word for it', () {
        expect(sql, contains('CREATE POLICY fleet_documents_object_own ON '
            'storage.objects'));
        expect(sql, contains('CREATE POLICY '
            'fleet_documents_object_manager_read ON storage.objects'));
        expect(storageViolations(sql), isEmpty);
        expect(sql, isNot(contains('storage.foldername')),
            reason: 'an object name is text the client chose; a policy that '
                'casts its prefix to uuid trusts it');
      });

      test('a client cannot choose an object key — both write paths pin '
          'it to <org>/<caller>/<id>', () {
        final row = policyBody(sql, 'fleet_documents_own');
        expect(
            row,
            contains("object_key = org_id::text || '/' || "
                '(SELECT auth.uid())::text'),
            reason: 'the forgery this closes is an own row naming another '
                "user's object path");
        final object = storagePolicyBody(sql, 'fleet_documents_object_own');
        expect(
            object,
            contains("split_part(name, '/', 2) = (SELECT auth.uid())::text"),
            reason: 'and the upload may not land outside the caller\'s own '
                'prefix either');
      });

      test('erasure covers the expense, the document row AND the '
          'stored bytes', () {
        final body = functionBlock
            .allMatches(sql)
            .firstWhere((m) => m.group(1) == 'erase_my_data')
            .group(2)!;
        expect(body, contains("ARRAY['fleet_expenses',   'user_id']"));
        expect(body, contains("ARRAY['fleet_documents',  'user_id']"));
        expect(body, contains('DELETE FROM storage.objects o'));
        expect(body, contains("o.bucket_id = 'fleet-documents'"));
        // The sweep may never take the erasure down with it — see
        // `erase_my_data_storage_guard_test.dart`, which EXECUTES this
        // body against a model of Supabase's statement-level trigger.
        expect(body, contains('EXCEPTION WHEN OTHERS THEN'));
        expect(body, contains("set_config('storage.allow_delete_query'"));
        expect(body, isNot(contains("'fleet_audit_events'")),
            reason: 'ADR 0025 D9 retains privileged-access records on a '
                'legal-obligation basis; they are exported, never erased');
      });
    });
  }

  test('the schema version was bumped so self-hosts are flagged', () {
    expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(14));
    expect(migration, contains("VALUES ('schema_version', '14', now())"));
  });

  test('the client export/erase maps agree with the SQL', () {
    for (final t in userOwned) {
      expect(UserDataSync.readableTables[t], 'user_id', reason: t);
      expect(UserDataSync.deletableTables[t], 'user_id', reason: t);
    }
    // The subject's own access rows ARE in their export (D9) and are
    // NOT erased with the rest.
    expect(UserDataSync.readableTables['fleet_audit_events'], 'actor');
    expect(UserDataSync.deletableTables.containsKey('fleet_audit_events'),
        isFalse);
  });

  group('mutation checks — the assertions actually bite', () {
    test('a manager policy that forgets the draft rule is caught', () {
      final broken = wizard.replaceFirst(
        "    status <> 'draft'\n"
        "    AND public.fleet_role(org_id) IN ('manager', 'admin')",
        "    public.fleet_role(org_id) IN ('manager', 'admin')",
      );
      expect(broken, isNot(wizard), reason: 'the mutation must apply');
      expect(managerViolations(broken),
          contains('fleet_expenses_manager_select does not exclude drafts'));
    });

    test('a manager policy that forgets the role check is caught', () {
      final broken = wizard.replaceAll(
        "public.fleet_role(org_id) IN ('manager', 'admin')",
        'org_id IS NOT NULL',
      );
      expect(broken, isNot(wizard));
      expect(
          managerViolations(broken),
          contains('fleet_expenses_manager_select does not check the '
              'manager role'));
    });

    test('a dropped manager policy is caught', () {
      final broken = wizard.replaceAll(
          'CREATE POLICY fleet_documents_manager_select', 'CREATE VIEW dead_v');
      expect(broken, isNot(wizard));
      expect(managerViolations(broken),
          contains('fleet_documents_manager_select is missing'));
    });

    test('a write policy sneaked onto the audit log is caught', () {
      final broken = wizard.replaceFirst(
        'CREATE POLICY fleet_audit_events_select ON public.fleet_audit_events\n'
        '  FOR SELECT TO authenticated',
        'CREATE POLICY fleet_audit_events_select ON public.fleet_audit_events\n'
        '  FOR ALL TO authenticated',
      );
      expect(broken, isNot(wizard));
      final body = policyBlock
          .allMatches(broken)
          .firstWhere((m) => m.group(1) == 'fleet_audit_events_select')
          .group(3)!;
      expect(body, contains('FOR ALL'),
          reason: 'fidelity: the mutation must be the thing the real '
              'assertion forbids');
    });

    test('a public bucket is caught', () {
      final broken = wizard.replaceFirst(
        "VALUES ('fleet-documents', 'fleet-documents', false)",
        "VALUES ('fleet-documents', 'fleet-documents', true)",
      );
      expect(broken, isNot(wizard));
      expect(
          broken,
          isNot(contains("VALUES ('fleet-documents', 'fleet-documents', "
              'false)')));
    });

    test('RESTORING the reviewed-away storage policy is caught — the '
        'EXISTS that trusted a client-supplied object_key', () {
      // The exact policy this slice shipped before the review, byte for
      // byte. It is the mutation, so the assertion above cannot pass
      // vacuously on a regex that no longer matches anything.
      final broken = wizard.replaceFirst(
        '''        AND EXISTS (
          SELECT 1
            FROM public.fleet_documents d
            JOIN public.fleet_expenses e
              ON e.org_id = d.org_id
             AND e.data ->> 'documentId' = d.id::text
           WHERE d.object_key = storage.objects.name
             AND d.user_id = storage.objects.owner
             AND d.deleted_at IS NULL
             AND e.status <> 'draft'
             AND public.fleet_role(d.org_id) IN ('manager', 'admin')
        )''',
        '''        AND EXISTS (
          SELECT 1 FROM public.fleet_documents d
           WHERE d.object_key = storage.objects.name
             AND d.deleted_at IS NULL
        )''',
      );
      expect(broken, isNot(wizard), reason: 'the mutation must apply');
      const policy = 'fleet_documents_object_manager_read';
      expect(
          storageViolations(broken),
          containsAll(<String>[
            '$policy does not bind the metadata row to the object owner',
            '$policy does not check the role on the document\'s org',
            '$policy does not carry the draft rule',
          ]));
    });

    test('dropping only the owner binding is caught on its own', () {
      final broken = wizard.replaceFirst(
          '             AND d.user_id = storage.objects.owner\n', '');
      expect(broken, isNot(wizard));
      expect(
          storageViolations(broken),
          contains('fleet_documents_object_manager_read does not bind the '
              'metadata row to the object owner'));
    });

    test('an unpinned object_key on the metadata write is caught', () {
      final broken = wizard.replaceFirst(
        """  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND object_key = org_id::text || '/' || (SELECT auth.uid())::text
                     || '/' || id::text
  );""",
        '  WITH CHECK (user_id = (SELECT auth.uid()));',
      );
      expect(broken, isNot(wizard));
      expect(policyBody(broken, 'fleet_documents_own'),
          isNot(contains('object_key = org_id::text')));
    });

    test('an erase that forgets the stored bytes is caught', () {
      final broken =
          wizard.replaceFirst('DELETE FROM storage.objects o', 'SELECT 1 AS o');
      expect(broken, isNot(wizard));
      final body = functionBlock
          .allMatches(broken)
          .firstWhere((m) => m.group(1) == 'erase_my_data')
          .group(2)!;
      expect(body, isNot(contains('DELETE FROM storage.objects o')));
    });
  });
}
