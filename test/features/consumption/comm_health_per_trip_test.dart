// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/obd2/data/obd2_comm_diagnostics.dart';
import 'package:tankstellen/features/obd2/data/obd2_session_diagnostic.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/obd2/presentation/widgets/obd2_diagnostics_trip_card.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/silence_error_logger.dart';

/// Synchronous fake of the [FeatureFlags] async notifier so the widget pump
/// never blocks on the real Hive-backed flag load — the established pattern
/// for feature-gated widget tests (mirrors `_TestFeatureFlags` in the shell
/// tests). Returns a fixed enabled set immediately.
class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags(this._initial);
  final Set<Feature> _initial;

  @override
  Set<Feature> build() => {..._initial};
}

/// #2912 (Epic #2904) — the OBD2 comm-health card was **always empty**
/// because [Obd2DiagnosticsTripCard] read the process-wide in-memory
/// `Obd2CommDiagnostics.instance` singleton (wiped on restart, never tied to
/// a trip) instead of the viewed trip's own diagnostic, which the trip record
/// did not persist.
///
/// This drives the REAL capture → persist → reload → render path (per the
/// repo's anti-false-green / #2776 round-trip rule — NOT the adapter in
/// isolation): a finished trip captures the live session into the trip record
/// via the real [TripHistoryRepository] (Hive JSON), the singleton is then
/// CLEARED to simulate an app restart, the trip is reloaded from disk, and the
/// card is pumped with the reloaded diagnostic.
///
/// On master this would be RED: the card reads the cleared singleton → empty.
/// After the fix the card renders the trip's persisted values → not empty.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> box;

  setUp(() async {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
    tmpDir = Directory.systemTemp.createTempSync('comm_health_per_trip_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<String>(
      'test_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    Obd2CommDiagnostics.instance.enabled = false;
    Obd2CommDiagnostics.instance.reset();
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  TripSummary mkSummary(DateTime start) => TripSummary(
        distanceKm: 12,
        maxRpm: 2800,
        highRpmSeconds: 10,
        idleSeconds: 30,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 20)),
      );

  /// Record a session that NEVER established a working link — the
  /// rfcomm-open-fail / GATT-133 case that produces no successful "session"
  /// yet is exactly when the diagnostics are most needed (#2912 point 3).
  /// Two failed connect attempts + a reconnect attempt with a reason code.
  void recordFailedConnectSession() {
    final diag = Obd2CommDiagnostics.instance;
    diag.enabled = true;
    diag.beginSession(linkKind: 'ble', redactedMac: '···············6:DA');
    diag.noteConnectionEvent(attempt: true, failureReason: 'gatt133');
    diag.noteConnectionEvent(attempt: true, failureReason: 'gatt133');
    diag.noteReconnectAttempt(
      attemptNumber: 1,
      succeeded: false,
      reasonCode: 'rfcommOpenFail',
      backoffMs: 2000,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    Obd2SessionDiagnostic? tripDiagnostic,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the BACKING async notifier with a synchronous fake so
          // the feature gate resolves on the first frame and the pump never
          // hangs on the real Hive-backed flag load.
          featureFlagsProvider
              .overrideWith(() => _TestFeatureFlags({Feature.debugMode})),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ListView(
              children: [
                Obd2DiagnosticsTripCard(tripDiagnostic: tripDiagnostic),
              ],
            ),
          ),
        ),
      ),
    );
    // Pump bounded frames rather than pumpAndSettle: the wider provider
    // graph (async notifiers) may never quiesce, and the card is collapsed
    // (no entry animation to wait on), so two frames are enough for the
    // gate + card to paint their first frame.
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'PROOF (#2912): a finished trip persists its OBD2 diagnostic and the '
    'card renders it AFTER the in-memory singleton is cleared (restart) — '
    'not empty',
    (tester) async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 6, 5, 9, 30);

      // 1. A trip is recorded with a (failed-connect) OBD2 session live.
      recordFailedConnectSession();

      // 2. At trip FINISH, capture the per-trip diagnostic + persist it.
      final captured = Obd2CommDiagnostics.instance.captureForTrip();
      expect(
        captured,
        isNotNull,
        reason: 'a failed-connect session must still be captured (#2912 p3)',
      );

      // Real Hive disk I/O must run OUTSIDE the testWidgets fake-async zone,
      // so the save → reload happens in `tester.runAsync`. The reloaded
      // diagnostic is what the card is then pumped with.
      TripHistoryEntry? reloaded;
      await tester.runAsync(() async {
        await repo.save(TripHistoryEntry(
          id: start.toIso8601String(),
          vehicleId: 'car-a',
          summary: mkSummary(start),
          obd2Diagnostic: captured,
        ));

        // 3. SIMULATE AN APP RESTART: the process-wide singleton is wiped.
        Obd2CommDiagnostics.instance.enabled = false;
        Obd2CommDiagnostics.instance.reset();

        // 4. Reload the trip from disk — the diagnostic must survive the
        //    JSON round-trip (NOT @JsonKey-dropped, #2776 lesson).
        reloaded = repo.loadById(start.toIso8601String());
      });

      expect(
        Obd2CommDiagnostics.instance.captureForTrip(),
        isNull,
        reason: 'post-restart the live singleton carries nothing',
      );
      expect(reloaded, isNotNull);
      expect(reloaded!.obd2Diagnostic, isNotNull);
      expect(reloaded!.obd2Diagnostic!.connection.attempts, 2);
      expect(
          reloaded!.obd2Diagnostic!.connection.failuresByReason['gatt133'], 2);
      expect(reloaded!.obd2Diagnostic!.reconnectAttempts, hasLength(1));
      expect(
        reloaded!.obd2Diagnostic!.reconnectAttempts.first.reasonCode,
        'rfcommOpenFail',
      );

      // 5. The card, fed the trip's persisted diagnostic, renders the
      //    populated tile — NOT the empty state — even though the singleton
      //    was cleared. THIS is the bug fix.
      await pumpCard(tester, reloaded!.obd2Diagnostic);
      expect(
        find.byKey(const Key('obd2_diagnostics_tile')),
        findsOneWidget,
        reason: 'persisted per-trip diagnostic must render, not the singleton',
      );
      expect(find.byKey(const Key('obd2_diagnostics_empty')), findsNothing);
    },
  );

  testWidgets(
    'regression: a trip with NO persisted diagnostic and a CLEARED singleton '
    'renders empty (the broken pre-fix state for every past trip)',
    (tester) async {
      // No persisted diagnostic + cleared singleton == the field bug. The
      // card must fall back to the (empty) live collector and show empty —
      // proving the fix does not falsely populate trips that have no health.
      await pumpCard(tester, null);
      expect(find.byKey(const Key('obd2_diagnostics_empty')), findsOneWidget);
      expect(find.byKey(const Key('obd2_diagnostics_tile')), findsNothing);
    },
  );

  test(
    'captureForTrip returns null for a pure GPS-only trip that never armed '
    'OBD2 — zero extra bytes persisted',
    () {
      // Collector disarmed (production / GPS-only): nothing to persist.
      expect(Obd2CommDiagnostics.instance.captureForTrip(), isNull);
    },
  );

  test(
    'TripHistoryEntry round-trips a fully-populated OBD2 diagnostic through '
    'the real repo (save → reload), nested fields intact',
    () async {
      final repo = TripHistoryRepository(box: box);
      final start = DateTime(2026, 6, 5, 11);
      const diag = Obd2SessionDiagnostic(
        linkKind: 'classic',
        redactedMac: '···············6:DA',
        elmVersion: 'ELM327 v2.1',
        connection: Obd2ConnectionStats(attempts: 4, successes: 3, drops: 1),
        reconnectAttempts: [
          Obd2ReconnectAttempt(
            timestampMs: 1717577400000,
            attemptNumber: 1,
            succeeded: true,
            backoffMs: 1000,
            latencyMs: 850,
          ),
        ],
        disconnectExceptions: 2,
        fallbackActivatedAtMs: 1717577410000,
      );

      await repo.save(TripHistoryEntry(
        id: start.toIso8601String(),
        vehicleId: 'car-b',
        summary: mkSummary(start),
        obd2Diagnostic: diag,
      ));

      final reloaded = repo.loadById(start.toIso8601String());
      expect(reloaded?.obd2Diagnostic, equals(diag));
    },
  );
}
