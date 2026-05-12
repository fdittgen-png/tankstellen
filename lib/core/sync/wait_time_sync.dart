import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'supabase_client.dart';

/// Default UUID v4 generator for `session_id` values. Pulled out so
/// tests can inject deterministic ids.
String _defaultSessionId() => const Uuid().v4();

/// Aggregate hint surfaced on the station-detail screen. Returned by
/// [WaitTimeSync.fetchAggregateForStation].
///
/// Mirrors the relevant subset of the `wait_time_aggregates` table —
/// the `aggregate-wait-times` Edge Function (#1119 phase 1) drops any
/// bucket with fewer than 5 samples, so a non-null hint is always
/// based on at least five distinct sessions.
@immutable
class WaitTimeHint {
  final int medianWaitSeconds;
  final int sampleCount;
  final DateTime computedAt;

  const WaitTimeHint({
    required this.medianWaitSeconds,
    required this.sampleCount,
    required this.computedAt,
  });

  /// Convenience: rounded minutes for the UI label. Always returns a
  /// non-negative integer; sub-30s buckets round to 0 which the UI
  /// renders as "<1 min" via the localised string.
  int get medianMinutes => (medianWaitSeconds / 60).round();
}

/// Client wire-up for community wait-time pings (#1119 phase 2).
///
/// Sibling pattern to [FillUpsSync]. Same shape: pull the auth context
/// off [TankSyncClient.client], guard the unauthenticated path with a
/// `debugPrint`, swallow errors with a `debugPrint` instead of letting
/// them surface to the UI — wait-time is an opt-in soft signal and the
/// user shouldn't see error toasts when a ping fails.
///
/// Two write paths and one read path:
///
///  * [recordArrival] — inserts an `'arrived'` row and returns the
///    generated `session_id` so the caller can pair it with the
///    matching [recordDeparture].
///  * [recordDeparture] — inserts the `'left'` row using the session
///    id captured at arrival time.
///  * [fetchAggregateForStation] — reads the most recent
///    `wait_time_aggregates` row for the station, or returns null when
///    the bucket is too sparse (server-side `< 5` samples drop) or the
///    request fails.
///
/// The schema's `user_id` column is filled by the RLS policy from
/// `auth.uid()`; clients never set it. `recorded_at` defaults to
/// `now()` server-side. Clients only supply `session_id`,
/// `station_id`, `country_code`, `event_type`.
class WaitTimeSync {
  WaitTimeSync._();

  /// Insert an `'arrived'` ping. Returns the `session_id` used so the
  /// caller can pair it with the matching [recordDeparture] later.
  ///
  /// Returns null when not authenticated, when [consentEnabled] is
  /// false, or when the request fails. The opt-in soft-signal contract
  /// is "under-trigger" — never raise to the UI for a missed ping.
  static Future<String?> recordArrival({
    required String stationId,
    required String countryCode,
    required bool consentEnabled,
    String Function() sessionIdGenerator = _defaultSessionId,
  }) async {
    if (!consentEnabled) {
      debugPrint('WaitTimeSync.recordArrival: consent OFF — skip');
      return null;
    }
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('WaitTimeSync.recordArrival: not authenticated');
      return null;
    }

    final sessionId = sessionIdGenerator();
    try {
      await client.from('wait_time_pings').insert({
        'session_id': sessionId,
        'station_id': stationId,
        'country_code': countryCode,
        'event_type': 'arrived',
      });
      return sessionId;
    } catch (e, st) {
      debugPrint('WaitTimeSync.recordArrival FAILED: $e\n$st');
      return null;
    }
  }

  /// Insert the matching `'left'` ping for a session previously
  /// started by [recordArrival]. No-op when consent is OFF, the user
  /// is not authenticated, or the request fails.
  static Future<void> recordDeparture({
    required String sessionId,
    required String stationId,
    required String countryCode,
    required bool consentEnabled,
  }) async {
    if (!consentEnabled) {
      debugPrint('WaitTimeSync.recordDeparture: consent OFF — skip');
      return;
    }
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      debugPrint('WaitTimeSync.recordDeparture: not authenticated');
      return;
    }

    try {
      await client.from('wait_time_pings').insert({
        'session_id': sessionId,
        'station_id': stationId,
        'country_code': countryCode,
        'event_type': 'left',
      });
    } catch (e, st) {
      debugPrint('WaitTimeSync.recordDeparture FAILED: $e\n$st');
    }
  }

  /// Look up the most recent aggregate row for [stationId]. Returns
  /// null when:
  ///  * no aggregate row exists (sparse data — the Edge Function drops
  ///    buckets with fewer than 5 samples),
  ///  * the user is not authenticated, or
  ///  * the read fails.
  ///
  /// The UI hides the hint entirely on null — never shows an error.
  static Future<WaitTimeHint?> fetchAggregateForStation({
    required String stationId,
  }) async {
    final client = TankSyncClient.client;
    if (client == null || client.auth.currentUser == null) {
      debugPrint('WaitTimeSync.fetchAggregateForStation: not authenticated');
      return null;
    }

    try {
      final row = await client
          .from('wait_time_aggregates')
          .select('median_wait_seconds, sample_count, computed_at')
          .eq('station_id', stationId)
          .order('hour_bucket', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      final median = row['median_wait_seconds'];
      final sample = row['sample_count'];
      final computed = row['computed_at'];
      if (median is! num || sample is! num || computed is! String) {
        debugPrint(
          'WaitTimeSync.fetchAggregateForStation: malformed row $row',
        );
        return null;
      }
      return WaitTimeHint(
        medianWaitSeconds: median.toInt(),
        sampleCount: sample.toInt(),
        computedAt: DateTime.parse(computed),
      );
    } catch (e, st) {
      debugPrint('WaitTimeSync.fetchAggregateForStation FAILED: $e\n$st');
      return null;
    }
  }
}
