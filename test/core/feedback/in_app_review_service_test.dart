// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/feedback/in_app_review_service.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

import '../../helpers/silence_error_logger.dart';

/// In-memory [SettingsStorage] stub — only the generic getSetting /
/// putSetting surface [InAppReviewService] touches is implemented; every
/// other member throws via noSuchMethod so an accidental dependency is loud.
class _FakeSettings implements SettingsStorage {
  final Map<String, dynamic> store = {};

  @override
  dynamic getSetting(String key) => store[key];

  @override
  Future<void> putSetting(String key, dynamic value) async {
    store[key] = value;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records how the reviewer seam was driven so each test can assert exactly
/// how many times the OS dialog was requested.
class _Reviewer {
  int isAvailableCalls = 0;
  int requestReviewCalls = 0;
  bool available = true;

  /// When set, both seam fns throw it — drives the never-throws fault test.
  Object? throwError;

  Future<bool> isAvailable() async {
    isAvailableCalls++;
    final err = throwError;
    if (err != null) throw err;
    return available;
  }

  Future<void> requestReview() async {
    requestReviewCalls++;
    final err = throwError;
    if (err != null) throw err;
  }
}

({ProviderContainer container, InAppReviewService service}) _wire(
  _FakeSettings settings,
  _Reviewer reviewer, {
  DateTime Function()? now,
}) {
  final c = ProviderContainer(overrides: [
    settingsStorageProvider.overrideWithValue(settings),
  ]);
  addTearDown(c.dispose);
  final service = c.read(inAppReviewServiceProvider.notifier)
    ..isAvailable = reviewer.isAvailable
    ..requestReview = reviewer.requestReview;
  if (now != null) service.now = now;
  return (container: c, service: service);
}

void main() {
  silenceErrorLoggerSpool();

  group('InAppReviewService.recordPositiveSignal', () {
    test('(a) below threshold → requestReview NOT called, only the counter '
        'increments', () async {
      final settings = _FakeSettings();
      final reviewer = _Reviewer();
      final wired = _wire(settings, reviewer);

      // Four signals — one short of the threshold of 5.
      for (var i = 0; i < kInAppReviewSignalThreshold - 1; i++) {
        await wired.service.recordPositiveSignal();
      }

      expect(reviewer.isAvailableCalls, 0,
          reason: 'never even probes the OS below threshold');
      expect(reviewer.requestReviewCalls, 0);
      expect(
        settings.store[StorageKeys.inAppReviewPositiveSignalCount],
        kInAppReviewSignalThreshold - 1,
      );
      expect(settings.store[StorageKeys.inAppReviewLastPromptIso], isNull);
    });

    test('(b) at threshold + available → requestReview called once, counter '
        'reset to 0, last-prompt stamped', () async {
      final settings = _FakeSettings();
      final reviewer = _Reviewer();
      final fixedNow = DateTime(2026, 6, 8, 12);
      final wired = _wire(settings, reviewer, now: () => fixedNow);

      for (var i = 0; i < kInAppReviewSignalThreshold; i++) {
        await wired.service.recordPositiveSignal();
      }

      expect(reviewer.isAvailableCalls, 1);
      expect(reviewer.requestReviewCalls, 1,
          reason: 'the OS dialog is requested exactly once at the threshold');
      expect(settings.store[StorageKeys.inAppReviewPositiveSignalCount], 0,
          reason: 'counter resets after a prompt attempt');
      expect(
        settings.store[StorageKeys.inAppReviewLastPromptIso],
        fixedNow.toIso8601String(),
      );
    });

    test('available=false → counter still resets + stamp written, but '
        'requestReview is NOT called', () async {
      final settings = _FakeSettings();
      final reviewer = _Reviewer()..available = false;
      final fixedNow = DateTime(2026, 6, 8, 12);
      final wired = _wire(settings, reviewer, now: () => fixedNow);

      for (var i = 0; i < kInAppReviewSignalThreshold; i++) {
        await wired.service.recordPositiveSignal();
      }

      expect(reviewer.isAvailableCalls, 1);
      expect(reviewer.requestReviewCalls, 0,
          reason: 'isAvailable() gated the request');
      expect(settings.store[StorageKeys.inAppReviewPositiveSignalCount], 0);
      expect(
        settings.store[StorageKeys.inAppReviewLastPromptIso],
        fixedNow.toIso8601String(),
      );
    });

    test('(c) within the 30-day window → NOT called even past the count '
        'threshold', () async {
      final settings = _FakeSettings();
      final reviewer = _Reviewer();
      var clock = DateTime(2026, 6, 8, 12);
      final wired = _wire(settings, reviewer, now: () => clock);

      // First burst hits the threshold and prompts once.
      for (var i = 0; i < kInAppReviewSignalThreshold; i++) {
        await wired.service.recordPositiveSignal();
      }
      expect(reviewer.requestReviewCalls, 1);

      // Advance only 29 days — still inside the cooldown — and accumulate
      // another full threshold's worth of signals.
      clock = clock.add(const Duration(days: 29));
      for (var i = 0; i < kInAppReviewSignalThreshold; i++) {
        await wired.service.recordPositiveSignal();
      }

      expect(reviewer.requestReviewCalls, 1,
          reason: 'the 30-day cooldown blocks a second prompt');
      // The counter keeps climbing because no prompt consumed it.
      expect(
        settings.store[StorageKeys.inAppReviewPositiveSignalCount],
        kInAppReviewSignalThreshold,
      );

      // One day later (day 30) the cooldown has elapsed → it prompts again.
      clock = clock.add(const Duration(days: 1));
      await wired.service.recordPositiveSignal();
      expect(reviewer.requestReviewCalls, 2);
    });

    test('(d) FAULT: the seam throws (e.g. NoClassDefFoundError on a libre '
        'build) → recordPositiveSignal completes without throwing', () async {
      final settings = _FakeSettings();
      // Mimic Play Core being stripped from the fdroid flavor: the very
      // first plugin touch blows up with a NoClassDefFoundError.
      final reviewer = _Reviewer()
        ..throwError = NoSuchMethodError.withInvocation(
          null,
          Invocation.method(#isAvailable, const []),
        );
      final wired = _wire(settings, reviewer);

      // Reach the threshold so the guarded isAvailable()/requestReview()
      // path is actually exercised — then assert it never escapes.
      for (var i = 0; i < kInAppReviewSignalThreshold - 1; i++) {
        await wired.service.recordPositiveSignal();
      }
      await expectLater(wired.service.recordPositiveSignal(), completes);

      // The cooldown stamp was written BEFORE the throwing platform call,
      // so a flaky/absent channel still consumes the throttle (no retry
      // spam) and the counter was reset.
      expect(reviewer.isAvailableCalls, 1,
          reason: 'the guarded path was reached and threw');
      expect(settings.store[StorageKeys.inAppReviewPositiveSignalCount], 0);
      expect(settings.store[StorageKeys.inAppReviewLastPromptIso], isNotNull);
    });
  });
}
