// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static-scan contract test (#3446): every pull path that persists
/// server rows into local storage must announce it on the `SyncEvents`
/// bus — a silent Hive-only write is exactly the stale-UI class Epic
/// #3444 diagnosed (pulled data appearing one restart late).
///
/// Two guards:
///
/// 1. **Known persist sites** — each file that persists pulled rows must
///    reference a `SyncEvents` emit. Adding a new pull-persist site?
///    Emit AFTER the write and add the file here.
/// 2. **`SyncRunTrace.table` pairing** — a file reporting per-table sync
///    counts is (or drives) a merge whose results get persisted
///    somewhere. Every such file must either emit itself or be
///    explicitly allow-listed with the file that emits for it.
void main() {
  const emitMarker = 'SyncEvents.instance.emit';

  // The emit is often line-wrapped (`SyncEvents.instance\n  .emit(...)`);
  // match on whitespace-stripped source so formatting can't hide it.
  bool containsEmit(String source) =>
      source.replaceAll(RegExp(r'\s'), '').contains(emitMarker);

  test('every known pull-persist site emits on the SyncEvents bus (#3446)',
      () {
    // file → the persist it covers.
    const persistSites = <String, String>{
      // syncAndPersistIds (favorites + ignored) and syncAndPersistRatings.
      'lib/core/sync/sync_provider.dart':
          'connect-time favorites/ignored/ratings persists',
      // #3447 — the pull-matrix thunks: pullTrips repo.save loop, the
      // baselines box.put loop, and the fill_ups call-site emit (its
      // persist site lives in the length-frozen consumption_providers.dart,
      // #3138). Launch, app-resume and "sync now" all replay this list.
      'lib/app/startup/launch_sync_pulls.dart':
          'launch/resume/sync-now trips + baselines + fill_ups pulls',
      // _applyMergedAlerts.
      'lib/features/alerts/providers/alert_provider.dart':
          'alerts download persist',
      // mergeFrom — the vehicles persist chokepoint (pull + device link).
      'lib/features/vehicle/providers/vehicle_providers.dart':
          'vehicles merge persist',
      // _loadAndMerge server-only addItinerary loop.
      'lib/features/itinerary/providers/itinerary_provider.dart':
          'itineraries pull persist',
      // "sync now" (#3447) persists nothing directly anymore — it replays
      // the registered pull matrix (launch_sync_pulls.dart above), whose
      // thunks own the emits.
    };

    final missing = <String>[];
    persistSites.forEach((path, what) {
      final file = File(path);
      expect(file.existsSync(), isTrue,
          reason: '$path moved? Update this contract test ($what).');
      if (!containsEmit(file.readAsStringSync())) {
        missing.add('$path — $what');
      }
    });

    expect(
      missing,
      isEmpty,
      reason: 'Pull paths persisted rows without a SyncEvents emit — the '
          'UI will show the pulled data one restart late (#3446). Emit '
          'AFTER the write:\n${missing.join('\n')}',
    );
  });

  test('every SyncRunTrace.table caller pairs with a SyncEvents emit (#3446)',
      () {
    // Files whose SyncRunTrace.table report is legitimately emit-free,
    // because the PERSIST (and its emit) happens in the mapped caller.
    const allowlist = <String, String>{
      // The generic merge engine returns the union to its caller; the
      // caller persists and emits (see the persist-site list above).
      'lib/core/sync/entity_sync.dart':
          'callers persist+emit (sync_provider, alert/vehicle/fill-up '
              'notifiers via launch_sync_phase / data_transparency)',
      // Defines the trace, calls nothing.
      'lib/core/sync/sync_run_trace.dart': 'the trace itself',
    };

    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      final path = entity.path.replaceAll(r'\', '/');
      final source = entity.readAsStringSync();
      if (!source.contains('SyncRunTrace.table(')) continue;
      if (allowlist.containsKey(path)) continue;
      if (containsEmit(source)) continue;
      offenders.add(path);
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These files report per-table sync counts but never emit on '
          'the SyncEvents bus — if they persist pulled rows the UI goes '
          'stale (#3446). Emit after the persist, or allow-list with the '
          'emitting caller:\n${offenders.join('\n')}',
    );
  });
}
