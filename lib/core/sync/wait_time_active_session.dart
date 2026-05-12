import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/hive_boxes.dart';

part 'wait_time_active_session.g.dart';

/// Snapshot of an in-flight community wait-time session (#1119
/// phase 2). Persisted across app restarts so a user who taps
/// "Track my wait", switches apps, then comes back later can still
/// pair the matching `'left'` ping to the original `session_id`.
@immutable
class WaitTimeActiveSession {
  /// UUID v4 generated at arrival time and re-used by the matching
  /// departure ping so the server can pair them.
  final String sessionId;

  final String stationId;
  final String countryCode;

  /// Wall-clock arrival time. Drives the elapsed-time ticker on the
  /// "Track my wait" UI and the >1 h auto-expire fallback.
  final DateTime arrivedAt;

  const WaitTimeActiveSession({
    required this.sessionId,
    required this.stationId,
    required this.countryCode,
    required this.arrivedAt,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'stationId': stationId,
        'countryCode': countryCode,
        'arrivedAt': arrivedAt.toIso8601String(),
      };

  static WaitTimeActiveSession? fromJson(Map<String, dynamic> json) {
    final sessionId = json['sessionId'];
    final stationId = json['stationId'];
    final countryCode = json['countryCode'];
    final arrivedAt = json['arrivedAt'];
    if (sessionId is! String ||
        stationId is! String ||
        countryCode is! String ||
        arrivedAt is! String) {
      return null;
    }
    final ts = DateTime.tryParse(arrivedAt);
    if (ts == null) return null;
    return WaitTimeActiveSession(
      sessionId: sessionId,
      stationId: stationId,
      countryCode: countryCode,
      arrivedAt: ts,
    );
  }
}

/// Hive-backed singleton store for the in-flight wait-time session.
///
/// Lives on the existing encrypted `settings` Hive box (single key —
/// no need for a dedicated box) so the user's last "I'm at the pump"
/// session survives a process kill. The 1-hour auto-expire matches
/// the Edge Function's `MAX_WAIT_SECONDS`: a session older than that
/// is invalid server-side anyway and we lazily clean it on read.
class WaitTimeActiveSessionStore {
  /// Settings-box key for the JSON-encoded active session blob.
  static const String _key = 'wait_time_active_session';

  /// Sessions older than this are treated as abandoned and dropped
  /// on the next [read]. Mirrors the server-side aggregator's
  /// `MAX_WAIT_SECONDS` of 3600s (1 hour).
  static const Duration maxAge = Duration(hours: 1);

  Box get _box => Hive.box(HiveBoxes.settings);

  /// Persist a new active session. Overwrites any previous payload —
  /// at most one in-flight session at a time.
  Future<void> start(WaitTimeActiveSession session) async {
    try {
      await _box.put(_key, jsonEncode(session.toJson()));
    } catch (e, st) {
      debugPrint('WaitTimeActiveSessionStore.start: $e\n$st');
    }
  }

  /// Read the current active session, or null when none is on disk,
  /// the payload can't be parsed, or the entry is stale (>1 h). Stale
  /// entries are cleaned on read so the UI never sees them.
  WaitTimeActiveSession? read({DateTime? now}) {
    final raw = _box.get(_key);
    if (raw is! String || raw.isEmpty) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final session = WaitTimeActiveSession.fromJson(json);
      if (session == null) {
        debugPrint('WaitTimeActiveSessionStore.read: malformed entry, clearing');
        _box.delete(_key);
        return null;
      }
      final reference = now ?? DateTime.now();
      if (reference.difference(session.arrivedAt) > maxAge) {
        debugPrint('WaitTimeActiveSessionStore.read: stale entry, clearing');
        _box.delete(_key);
        return null;
      }
      return session;
    } catch (e, st) {
      debugPrint('WaitTimeActiveSessionStore.read: $e\n$st');
      return null;
    }
  }

  /// Drop the active session. Called on successful [recordDeparture]
  /// or after the >1h auto-expire fallback fires.
  Future<void> clear() async {
    try {
      await _box.delete(_key);
    } catch (e, st) {
      debugPrint('WaitTimeActiveSessionStore.clear: $e\n$st');
    }
  }
}

/// Riverpod provider for the active-session store. `keepAlive: true`
/// so the wait-time UI on the station-detail screen + the toggle on
/// any other surface share the same Hive-backed instance.
@Riverpod(keepAlive: true)
WaitTimeActiveSessionStore waitTimeActiveSessionStore(Ref ref) =>
    WaitTimeActiveSessionStore();

/// Riverpod-exposed snapshot of the current active session. Returns
/// null when no session is in flight.
///
/// State changes are pushed by the toggle UI calling
/// `ref.invalidate(waitTimeActiveSessionProvider)` after `start` /
/// `clear` so consumers re-render. Mirrors the deliberate
/// invalidation pattern used by the favourites + ratings providers
/// rather than wiring a Hive listenable.
@Riverpod(keepAlive: true)
WaitTimeActiveSession? waitTimeActiveSession(Ref ref) {
  final store = ref.watch(waitTimeActiveSessionStoreProvider);
  return store.read();
}
