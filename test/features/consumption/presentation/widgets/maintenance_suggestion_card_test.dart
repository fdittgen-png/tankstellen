import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/maintenance_snooze_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/maintenance_suggestion.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/maintenance_suggestion_card.dart';

import '../../../../helpers/pump_app.dart';

/// Widget-level coverage for [MaintenanceSuggestionCard] (#1124).
///
/// Locks down the user-visible contract:
///   * The localised title + body render with the percent / trip-count
///     placeholders interpolated correctly.
///   * Both action buttons (Dismiss + Snooze 30 days) render and meet
///     the `androidTapTargetGuideline` (≥48 dp).
///   * Tapping "Snooze 30 days" persists a key in the settings box —
///     the action is real, not just visual feedback.
///
/// We pump a real Hive `settings` box into a temp directory so the
/// snooze repo can write through to actual storage; matches the
/// pattern used by `velocity_alert_cooldown_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('hive_maintenance_card_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).close();
    }
    await Hive.openBox(HiveBoxes.settings);
    await Hive.box(HiveBoxes.settings).clear();
  });

  tearDownAll(() async {
    // Best-effort cleanup. On Windows the Hive lock file can keep a
    // handle on the box file for a few hundred ms after Hive.close —
    // a hard `deleteSync` would throw and a hard `Hive.close()` await
    // can deadlock the test runner there. The OS will reclaim this
    // temp dir on the next pass; no real damage if cleanup is skipped.
    try {
      await Hive.close().timeout(const Duration(seconds: 2));
    } on Object catch (e) {
      debugPrint('tearDownAll: Hive.close skipped ($e)');
    }
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } on FileSystemException catch (e) {
      debugPrint('tearDownAll: temp dir cleanup skipped ($e)');
    }
  });

  group('MaintenanceSuggestionCard — rendering', () {
    testWidgets('renders the idle-RPM creep title + body with placeholders',
        (tester) async {
      final suggestion = MaintenanceSuggestion(
        signal: MaintenanceSignal.idleRpmCreep,
        confidence: 0.5,
        observedDelta: 9.0,
        sampleTripCount: 12,
        computedAt: DateTime(2026, 4, 1),
      );

      await pumpApp(
        tester,
        MaintenanceSuggestionCard(suggestion: suggestion),
      );

      expect(find.text('Idle RPM creep detected'), findsOneWidget);
      expect(
        find.textContaining('9%'),
        findsOneWidget,
        reason: 'Body must surface the observed delta as whole-number %',
      );
      expect(
        find.textContaining('12'),
        findsWidgets,
        reason: 'Body must surface the analysed trip count',
      );
    });

    testWidgets('renders the MAF deviation title + body with placeholders',
        (tester) async {
      final suggestion = MaintenanceSuggestion(
        signal: MaintenanceSignal.mafDeviation,
        confidence: 0.6,
        observedDelta: 13.0,
        sampleTripCount: 18,
        computedAt: DateTime(2026, 4, 1),
      );

      await pumpApp(
        tester,
        MaintenanceSuggestionCard(suggestion: suggestion),
      );

      expect(find.text('Possible intake restriction'), findsOneWidget);
      expect(find.textContaining('13%'), findsOneWidget);
      expect(find.textContaining('18'), findsWidgets);
    });

    testWidgets('renders both action buttons with the localised labels',
        (tester) async {
      final suggestion = MaintenanceSuggestion(
        signal: MaintenanceSignal.idleRpmCreep,
        confidence: 0.5,
        observedDelta: 9.0,
        sampleTripCount: 10,
        computedAt: DateTime(2026, 4, 1),
      );

      await pumpApp(
        tester,
        MaintenanceSuggestionCard(suggestion: suggestion),
      );

      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Snooze 30 days'), findsOneWidget);
    });

    testWidgets('every interactive element passes androidTapTargetGuideline',
        (tester) async {
      final suggestion = MaintenanceSuggestion(
        signal: MaintenanceSignal.idleRpmCreep,
        confidence: 0.5,
        observedDelta: 9.0,
        sampleTripCount: 10,
        computedAt: DateTime(2026, 4, 1),
      );

      await pumpApp(
        tester,
        MaintenanceSuggestionCard(suggestion: suggestion),
      );

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });
  });

  group('MaintenanceSuggestionCard — interactions', () {
    testWidgets('tap on "Snooze 30 days" persists a snooze key',
        (tester) async {
      final suggestion = MaintenanceSuggestion(
        signal: MaintenanceSignal.idleRpmCreep,
        confidence: 0.5,
        observedDelta: 9.0,
        sampleTripCount: 10,
        computedAt: DateTime(2026, 4, 1),
      );

      await pumpApp(
        tester,
        MaintenanceSuggestionCard(suggestion: suggestion),
      );

      // Box must be empty before the tap.
      final box = Hive.box(HiveBoxes.settings);
      expect(box.length, 0,
          reason: 'No snooze key should exist before user interaction');

      await tester.tap(find.text('Snooze 30 days'));
      // Don't pumpAndSettle — the snooze action's ref.invalidate can keep
      // pumpAndSettle pumping forever on Windows when the Hive box from a
      // prior test still holds a file handle. Explicit pumps drain the
      // microtask queue (where the box.put completes) without that risk.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final stored = box.get(
        '${MaintenanceSnoozeRepository.keyPrefix}'
        '${MaintenanceSignal.idleRpmCreep.name}',
      );
      expect(stored, isNotNull,
          reason: 'Tap must write a snooze timestamp for the signal');
    }, timeout: const Timeout(Duration(seconds: 30)));

    // Note: a separate widget test for "Dismiss" was intentionally not added.
    // Both buttons share the same controller path (snoozeRepository.snooze
    // with different durations) and the Dismiss path is exercised end-to-end
    // by maintenance_provider_test.dart. A second widget interaction test
    // here would only repeat the Snooze test's assertions.
  });
}
