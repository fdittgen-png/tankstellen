// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';

/// #4215 — an EXECUTABLE guard for the `erase_my_data()` object sweep.
///
/// ## Why a runnable model and not another `contains`
///
/// The first version of the sweep was a bare
/// `DELETE FROM storage.objects …`, and the static contract test
/// asserted that text was present. It was. It also aborted account
/// deletion for **every** user of the app.
///
/// Supabase ships `protect_objects_delete` on `storage.objects`: a
/// `BEFORE DELETE FOR EACH STATEMENT` trigger that raises `42501` for a
/// direct SQL delete. Statement-level means it fires when the statement
/// matches **zero rows** — so a fleet-free personal user, deleting
/// their account, hit it too, and `erase_my_data()` rolled back having
/// erased nothing. A GDPR Art. 17 regression (#3865) that a text
/// assertion is structurally incapable of catching, because the defect
/// was never in the text: it was in what executing the text does.
///
/// So this file EXECUTES the function body against a model of that
/// trigger. [_ErasePlan] is not Postgres and does not pretend to be —
/// it models exactly three rules, the three the incident turned on:
///
///  1. a `DELETE FROM storage.objects` raises `42501` unless
///     `set_config('storage.allow_delete_query', 'true', …)` ran before
///     it in the same transaction — **whether or not it matches rows**;
///  2. a raise inside a `BEGIN … EXCEPTION WHEN OTHERS … END` block is
///     caught there;
///  3. an uncaught raise aborts the function, so NOTHING is erased.
///
/// The mutations at the bottom restore the shipped-then-reviewed shapes
/// and require each to fail, so the model cannot pass vacuously.

/// A Postgres error, as much of one as this model needs.
class _PgError implements Exception {
  const _PgError(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => '$code: $message';
}

/// What running `erase_my_data()` did.
typedef _EraseOutcome = ({
  /// Tables the FOREACH loop reached, in order.
  List<String> erasedTables,

  /// True when the object sweep's DELETE actually executed.
  bool sweptObjects,

  /// Set when the sweep raised and its own handler swallowed it.
  String? sweepWarning,

  /// Set when a raise escaped and aborted the whole function.
  _PgError? aborted,
});

/// A tiny sequential model of the `erase_my_data()` body.
class _ErasePlan {
  _ErasePlan(this.body);

  /// The plpgsql between `AS $$` and the closing `$$` of the function.
  final String body;

  /// The `ARRAY['<table>', '<column>']` entries of the FOREACH loop, in
  /// order — what the function would erase if it reaches the loop.
  List<String> get _loopTables => RegExp(r"ARRAY\['([a-z0-9_]+)',\s*'[a-z0-9_]+'\]")
      .allMatches(body)
      .map((m) => m.group(1)!)
      .toList();

  /// The storage-sweep region: `IF to_regclass('storage.objects') …`
  /// up to the `FOREACH` loop that follows it. Delimited by the loop
  /// rather than by the first `END IF;`, because the sweep nests one
  /// (the trigger-existence check) and matching the inner one would
  /// cut the region off before the DELETE — which would make this
  /// model silently report "no sweep" and pass everything.
  String get _sweepRegion {
    final start = body.indexOf("IF to_regclass('storage.objects')");
    if (start < 0) return '';
    final loop = body.indexOf('FOREACH', start);
    return body.substring(start, loop < 0 ? body.length : loop);
  }

  _EraseOutcome run() {
    final region = _sweepRegion;
    if (region.isEmpty) {
      // No sweep at all: the loop runs and the bytes are simply left.
      return (
        erasedTables: _loopTables,
        sweptObjects: false,
        sweepWarning: null,
        aborted: null,
      );
    }

    final deleteAt = region.indexOf('DELETE FROM storage.objects');
    if (deleteAt < 0) {
      return (
        erasedTables: _loopTables,
        sweptObjects: false,
        sweepWarning: null,
        aborted: null,
      );
    }

    // Rule 1 — the trigger fires on the STATEMENT, so the row count is
    // irrelevant; only the transaction-local switch matters, and it has
    // to have been set before this statement.
    final allowed = RegExp(
      r"set_config\(\s*'storage\.allow_delete_query'\s*,\s*'true'",
    ).allMatches(region).any((m) => m.start < deleteAt);

    if (allowed) {
      return (
        erasedTables: _loopTables,
        sweptObjects: true,
        sweepWarning: null,
        aborted: null,
      );
    }

    const raised = _PgError(
      '42501',
      'Direct deletion from storage tables is not allowed. '
          'Use the Storage API instead.',
    );

    // Rule 2 — is the DELETE inside a block with an OTHERS handler?
    final blockStart = region.lastIndexOf('BEGIN', deleteAt);
    final handlerAt = region.indexOf('EXCEPTION WHEN OTHERS', deleteAt);
    final handled = blockStart >= 0 && handlerAt > deleteAt;

    // Rule 3 — otherwise it escapes, and the transaction is gone.
    return (
      erasedTables: handled ? _loopTables : const <String>[],
      sweptObjects: false,
      sweepWarning: handled ? raised.message : null,
      aborted: handled ? null : raised,
    );
  }
}

/// The `erase_my_data()` plpgsql body inside [sql].
String _eraseBody(String sql) {
  final start = sql.indexOf('CREATE OR REPLACE FUNCTION public.erase_my_data()');
  // A throw, not an expect(): this runs while the groups are being
  // DECLARED, where there is no test to fail.
  if (start < 0) throw StateError('no erase_my_data() in the SQL');
  final open = sql.indexOf(r'$$', start);
  final close = sql.indexOf(r'$$;', open + 2);
  return sql.substring(open + 2, close);
}

void main() {
  final wizard = buildMigrationSql(const <String, bool>{});
  final migration =
      File('supabase/migrations/20260918000002_fleet_expenses.sql')
          .readAsStringSync();

  group('the model itself bites (fidelity)', () {
    test('a bare DELETE on storage.objects aborts the whole function — '
        'the exact #4215 regression', () {
      final outcome = _ErasePlan('''
  IF to_regclass('storage.objects') IS NOT NULL THEN
    DELETE FROM storage.objects o
      USING public.fleet_documents d
      WHERE o.name = d.object_key AND d.user_id = uid;
  END IF;
  FOREACH spec SLICE 1 IN ARRAY ARRAY[
    ARRAY['fill_ups', 'user_id'],
    ARRAY['users',    'id']
  ]
''').run();

      expect(outcome.aborted?.code, '42501');
      expect(outcome.erasedTables, isEmpty,
          reason: 'an aborted transaction erases nothing — including for '
              'the personal user who has no fleet rows at all');
    });

    test('the switch alone lets the sweep through', () {
      final outcome = _ErasePlan('''
  IF to_regclass('storage.objects') IS NOT NULL THEN
    PERFORM set_config('storage.allow_delete_query', 'true', true);
    DELETE FROM storage.objects o WHERE o.name = 'x';
  END IF;
  FOREACH spec SLICE 1 IN ARRAY ARRAY[
    ARRAY['users', 'id']
  ]
''').run();

      expect(outcome.aborted, isNull);
      expect(outcome.sweptObjects, isTrue);
      expect(outcome.erasedTables, ['users']);
    });

    test('a handler alone keeps the erasure alive but skips the bytes', () {
      final outcome = _ErasePlan('''
  IF to_regclass('storage.objects') IS NOT NULL THEN
    BEGIN
      DELETE FROM storage.objects o WHERE o.name = 'x';
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'skipped';
    END;
  END IF;
  FOREACH spec SLICE 1 IN ARRAY ARRAY[
    ARRAY['users', 'id']
  ]
''').run();

      expect(outcome.aborted, isNull);
      expect(outcome.sweptObjects, isFalse);
      expect(outcome.sweepWarning, isNotNull);
      expect(outcome.erasedTables, ['users']);
    });
  });

  for (final (label, sql) in [
    ('wizard SQL', wizard),
    ('migration', migration),
  ]) {
    group('$label — erase_my_data() runs to completion', () {
      final outcome = _ErasePlan(_eraseBody(sql)).run();

      test('it is not aborted by the storage trigger', () {
        expect(outcome.aborted, isNull,
            reason: 'account deletion must not depend on a storage-side '
                'guard: ${outcome.aborted}');
      });

      test('the sweep executes rather than being swallowed', () {
        expect(outcome.sweptObjects, isTrue,
            reason: 'the allow_delete_query switch must precede the DELETE');
        expect(outcome.sweepWarning, isNull);
      });

      test('every user table is still erased, fleet rows included', () {
        expect(outcome.erasedTables, containsAll(<String>[
          'fleet_expenses',
          'fleet_documents',
          'vehicle_assignments',
          'fleet_members',
          'fill_ups',
          'users',
        ]));
        expect(outcome.erasedTables.last, 'users',
            reason: 'children before parents — the FK target goes last');
      });

      test('the switch is set only where the trigger exists, so a '
          'self-host without it is unaffected', () {
        final body = _eraseBody(sql);
        expect(body, contains("tgname = 'protect_objects_delete'"));
        expect(body, contains("set_config('storage.allow_delete_query'"));
      });
    });
  }

  group('mutation checks — each shipped-then-reviewed shape fails', () {
    final body = _eraseBody(wizard);

    test('dropping the set_config leaves the erasure alive (the handler '
        'holds) but silently stops removing bytes', () {
      final broken = body.replaceFirst(
          RegExp(r"\s*PERFORM set_config\('storage\.allow_delete_query'[^;]*;"),
          '');
      expect(broken, isNot(body), reason: 'the mutation must apply');
      final outcome = _ErasePlan(broken).run();
      expect(outcome.sweptObjects, isFalse);
      expect(outcome.sweepWarning, isNotNull);
      expect(outcome.aborted, isNull);
    });

    test('dropping BOTH guards reproduces the regression: nothing is '
        'erased, for anybody', () {
      var broken = body.replaceFirst(
          RegExp(r"\s*PERFORM set_config\('storage\.allow_delete_query'[^;]*;"),
          '');
      broken = broken.replaceFirst(
          RegExp(r'\s*EXCEPTION WHEN OTHERS THEN[\s\S]*?SQLERRM;'), '');
      expect(broken, isNot(body));
      final outcome = _ErasePlan(broken).run();
      expect(outcome.aborted?.code, '42501');
      expect(outcome.erasedTables, isEmpty);
    });
  });
}
