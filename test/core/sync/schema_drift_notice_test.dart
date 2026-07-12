// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_drift_notice.dart';

/// #3560 — the outdated-self-host-schema classification + once-per-session
/// notice that replaced the per-sync-run ERROR spam (three days of field
/// logs were >80% one repeated `favorites.kind does not exist`).
void main() {
  setUp(SchemaDriftNotice.instance.reset);

  group('isSchemaDriftError', () {
    test('matches the field-log undefined-column signature (42703)', () {
      const msg =
          'PostgrestException(message: column favorites.kind does '
          'not exist, code: 42703, details: Bad Request, hint: Perhaps you '
          'meant to reference the column "favorites.id".)';
      expect(isSchemaDriftError(Exception(msg)), isTrue);
    });

    test('matches a missing-table signature (42P01 / PGRST205)', () {
      expect(
        isSchemaDriftError(
          Exception(
            'PostgrestException(message: relation "public.deletions" does '
            'not exist, code: 42P01)',
          ),
        ),
        isTrue,
      );
      expect(
        isSchemaDriftError(
          Exception(
            "PostgrestException(message: Could not find the table 'public.deletions' in the schema cache, code: PGRST205)",
          ),
        ),
        isTrue,
      );
    });

    test('does NOT match unrelated failures', () {
      expect(
        isSchemaDriftError(
          Exception(
            'TimeoutException after 0:00:15.000000: Future not completed',
          ),
        ),
        isFalse,
        reason: 'network weather must keep ERROR-logging',
      );
      expect(
        isSchemaDriftError(Exception('order id 42703 rejected')),
        isFalse,
        reason:
            'a code-like substring without the column/table wording '
            'must not be swallowed',
      );
    });
  });

  group('SchemaDriftNotice', () {
    test('note() is once-per-table-per-session and updates the notifier', () {
      final notice = SchemaDriftNotice.instance;
      expect(
        notice.note('favorites'),
        isTrue,
        reason: 'first hit earns the one actionable breadcrumb',
      );
      expect(notice.note('favorites'), isFalse, reason: 'repeats stay quiet');
      expect(notice.note('alerts'), isTrue);
      expect(notice.tables.value, {'favorites', 'alerts'});
    });
  });
}
