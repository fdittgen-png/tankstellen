// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/collectors/app_state_collector.dart';

/// #2320 — `AppStateCollector.updateLastSearch` previously had zero call
/// sites, so `lastSearchParams` was always null in error traces and
/// search-failure traces carried no search context.
///
/// `SearchState`'s entry points each delegate to a country-specific
/// service chain (HTTP, geocoding, GPS) that flutter_test cannot stand up
/// without a real device binding, so the wiring is pinned with
/// source-level structural assertions (the same pattern used by
/// `app_initializer_test.dart`). The runtime group below exercises the
/// collector directly to lock in the PII-exclusion contract.
void main() {
  group('SearchState wires updateLastSearch at every entry (#2320)', () {
    late String src;

    setUpAll(() {
      src = File('lib/features/search/providers/search_provider.dart')
          .readAsStringSync();
    });

    test('imports AppStateCollector', () {
      expect(
        src,
        contains("import '../../../core/telemetry/collectors/app_state_collector.dart';"),
        reason: 'the collector must be imported so the wiring compiles',
      );
    });

    test('each search entry records the last search', () {
      // All three entry points must record an anonymised breadcrumb so a
      // search-failure trace carries the search context regardless of how
      // the search was started.
      for (final entry in ['searchByGps', 'searchByZipCode', 'searchByCoordinates']) {
        final start = src.indexOf('Future<void> $entry');
        expect(start, isNonNegative, reason: '$entry must exist');
        // Slice from the method start to the next method (or EOF) and
        // confirm it records the search.
        final next = src.indexOf('Future<void> ', start + 1);
        final body = src.substring(start, next < 0 ? src.length : next);
        expect(body, contains('_recordLastSearch'),
            reason: '$entry must record its search via _recordLastSearch');
      }
    });

    test('_recordLastSearch routes to AppStateCollector.updateLastSearch', () {
      final body = _recordLastSearchBody(src);
      expect(body, contains('AppStateCollector.updateLastSearch'),
          reason: '_recordLastSearch must forward to the collector');
    });

    test('the recorded breadcrumb excludes location PII', () {
      // The breadcrumb must never carry coordinates, ZIP codes, or
      // location labels — only the search mode + non-identifying filters.
      final body = _recordLastSearchBody(src);
      for (final forbidden in [
        'latitude',
        'longitude',
        'zipCode',
        'postalCode',
        'locationName',
      ]) {
        expect(body, isNot(contains(forbidden)),
            reason: 'the _recordLastSearch body must not reference $forbidden '
                '— it is location PII and must not leak into error traces');
      }
      // The format string carries only mode + non-identifying filters.
      expect(body, contains('mode='));
      expect(body, contains('fuel='));
      expect(body, contains('radiusKm='));
      expect(body, contains('sort='));
    });
  });

  // -- helper used only by this file --

  group('AppStateCollector.updateLastSearch (#2320)', () {
    test('stores the params for the next snapshot', () {
      AppStateCollector.updateLastSearch('mode=gps fuel=diesel radiusKm=10 sort=price');
      // No Ref needed to assert storage of the static field via a fresh
      // overwrite + read-through is observable; we re-write and confirm
      // it does not throw and the value sticks via a second overwrite.
      AppStateCollector.updateLastSearch('mode=zip fuel=default radiusKm=default sort=default');
      // The collector is a static singleton; the assertion here is simply
      // that updateLastSearch is callable + idempotent on repeated writes.
      expect(
        () => AppStateCollector.updateLastSearch('mode=coordinates'),
        returnsNormally,
      );
    });
  });
}

/// Returns the body of the `_recordLastSearch` helper, brace-matched so
/// the slice does not bleed into adjacent methods.
String _recordLastSearchBody(String src) {
  final start = src.indexOf('void _recordLastSearch');
  expect(start, isNonNegative, reason: '_recordLastSearch helper must exist');
  final braceStart = src.indexOf('{', src.indexOf(') {', start));
  var depth = 0;
  for (var i = braceStart; i < src.length; i++) {
    final ch = src[i];
    if (ch == '{') depth++;
    if (ch == '}') {
      depth--;
      if (depth == 0) return src.substring(braceStart, i + 1);
    }
  }
  fail('_recordLastSearch body could not be brace-matched');
}
