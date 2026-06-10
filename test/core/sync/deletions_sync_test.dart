// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
      expectLater(DeletionsSync.record('favorites', 'st-X'), completes);
    });

    test('recordAll completes silently on the fault path', () {
      expectLater(
        DeletionsSync.recordAll('fill_ups', const ['a', 'b']),
        completes,
      );
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
}
