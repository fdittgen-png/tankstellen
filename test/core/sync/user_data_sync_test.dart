// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/user_data_sync.dart';

/// Contract tests for [UserDataSync] (#727 extract — retires the
/// former SyncService).
void main() {
  group('UserDataSync auth guards', () {
    test('fetchAll returns an error payload when unauthenticated',
        () async {
      final data = await UserDataSync.fetchAll();
      expect(data.containsKey('error'), isTrue);
      expect(data['error'], contains('Not authenticated'));
    });

    test('deleteAll is a no-op when unauthenticated', () async {
      // Silent on failure by design — shouldn't throw, shouldn't
      // leave the process in a bad state.
      await UserDataSync.deleteAll();
    });
  });

  /// #2292 — the GDPR right-to-be-forgotten path previously wiped only
  /// 6 tables and silently left trip history, itineraries, OBD2
  /// baselines and station ratings on the server. The wire `delete`
  /// calls can't be exercised without a live Supabase client, so the
  /// table coverage is pinned through the `@visibleForTesting`
  /// [UserDataSync.deletableTables] map (plus the trip tables wiped via
  /// `TripsSync.forgetAllForUser`). This regression-guards a future
  /// table that becomes exportable but not deletable.
  group('UserDataSync.deletableTables — GDPR coverage (#2292)', () {
    test('covers every table the old wipe handled', () {
      // The original (incomplete) deletion set.
      expect(
        UserDataSync.deletableTables.keys,
        containsAll(<String>[
          'favorites',
          'alerts',
          'push_tokens',
          'price_reports',
          'vehicles',
          'fill_ups',
        ]),
      );
    });

    test('adds the tables the regulatory defect omitted', () {
      // The #2292 additions that must now be wiped on account deletion.
      expect(
        UserDataSync.deletableTables.keys,
        containsAll(<String>[
          'itineraries',
          'obd2_baselines',
          'station_ratings',
        ]),
      );
    });

    test('price_reports keys on reporter_id, every other table on user_id',
        () {
      expect(UserDataSync.deletableTables['price_reports'], 'reporter_id');
      for (final entry in UserDataSync.deletableTables.entries) {
        if (entry.key == 'price_reports') continue;
        expect(entry.value, 'user_id',
            reason: '${entry.key} should be keyed on user_id');
      }
    });

    test(
        'every exportable table is also deletable — trip tables go via '
        'TripsSync.forgetAllForUser', () {
      // `fetchAll` reads these into the Privacy Dashboard export; a
      // right-to-be-forgotten request must wipe each one. trip_summaries
      // + trip_details are deleted by TripsSync.forgetAllForUser (called
      // inside deleteAll), so they're allowed to be absent from the map.
      const wipedViaTripsSync = {'trip_summaries', 'trip_details'};
      const exportedTables = {
        'favorites',
        'alerts',
        'push_tokens',
        // fetchAll keys this as 'reports' in the export map but reads the
        // price_reports table.
        'price_reports',
        'itineraries',
        'trip_summaries',
        'trip_details',
      };

      for (final table in exportedTables) {
        if (wipedViaTripsSync.contains(table)) continue;
        expect(UserDataSync.deletableTables.containsKey(table), isTrue,
            reason: '$table is exported by fetchAll but not wiped by '
                'deleteAll — right-to-be-forgotten would leave it behind');
      }
    });
  });
}
