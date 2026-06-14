// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/deletions_sync.dart';

/// Fault-path contract for [DeletionsSync] (#3078).
///
/// `DeletionsSync.record` documents "sync must never throw back into the
/// caller" — the local delete already happened, so a sync hiccup must be
/// swallowed silently. With no Supabase client initialised, every method takes
/// the fault path (no auth / no client); these assertions pin that it returns
/// normally rather than throwing, satisfying the #2349 never-throws ratchet.
void main() {
  group('DeletionsSync never-throws fault path (#3078)', () {
    test('record completes silently when the client is uninitialised', () {
      unawaited(expectLater(DeletionsSync.record('favorites', 'st-X'), completes));
    });

    test('recordAll completes silently on the fault path', () {
      unawaited(expectLater(
        DeletionsSync.recordAll('fill_ups', const ['a', 'b']),
        completes,
      ));
    });

    test('recordAll on an empty list returns normally (no round-trip)', () {
      expect(
        () => DeletionsSync.recordAll('vehicles', const <String>[]),
        returnsNormally,
      );
    });

    test('fetchTombstonedIds returns an empty set instead of throwing', () async {
      expect(await DeletionsSync.fetchTombstonedIds('itineraries'), isEmpty);
    });
  });

  group('isDeletionsTableAbsent (#3331)', () {
    test('the field PGRST205 message is classified as table-absent', () {
      final err = Exception(
        'PostgrestException(message: Could not find the table '
        "'public.deletions' in the schema cache, code: PGRST205, "
        "details: Not Found, hint: Perhaps you meant 'public.ignored_stations')",
      );
      expect(DeletionsSync.isDeletionsTableAbsent(err), isTrue);
    });

    test('the find-table/schema-cache phrasing (no code) still matches', () {
      final err = Exception(
        "Could not find the table 'public.deletions' in the schema cache",
      );
      expect(DeletionsSync.isDeletionsTableAbsent(err), isTrue);
    });

    test('a PGRST205 for a DIFFERENT table is not classified', () {
      final err = Exception(
        "Could not find the table 'public.widgets' in the schema cache PGRST205",
      );
      expect(DeletionsSync.isDeletionsTableAbsent(err), isFalse);
    });

    test('the PGRST204 missing-column case is NOT table-absent', () {
      final err = Exception(
        "PostgrestException(message: Could not find the 'device_id' column "
        "of 'deletions', code: PGRST204)",
      );
      expect(DeletionsSync.isDeletionsTableAbsent(err), isFalse);
    });

    test('a generic sync error is not classified as table-absent', () {
      expect(DeletionsSync.isDeletionsTableAbsent(Exception('network down')),
          isFalse);
    });
  });
}
