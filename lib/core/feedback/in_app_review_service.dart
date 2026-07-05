// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../logging/error_logger.dart';
import '../storage/storage_keys.dart';
import '../storage/storage_providers.dart';
import 'review_prompter.dart';

part 'in_app_review_service.g.dart';

/// Number of accumulated "positive signals" that unlocks a review prompt.
///
/// A positive signal is a successful station search that returned results
/// (see `SearchState`). Five such moments before we ask keeps the prompt
/// well clear of a brand-new install's first tentative search.
const int kInAppReviewSignalThreshold = 5;

/// Minimum gap between two prompt *attempts*. The OS additionally
/// rate-limits the native dialog (Android caps it to a few times a year,
/// iOS to three times in 365 days), but we never even reach the platform
/// channel inside this cooldown — so a user who already dismissed the
/// dialog isn't re-bothered every few searches.
const Duration kInAppReviewMinInterval = Duration(days: 30);

/// Asks the OS to show its native store-review dialog at genuine positive
/// moments, throttled by a count threshold and a 30-day cooldown (#3069).
///
/// The dialog is rendered entirely by the platform (Play In-App Review API
/// on Android, `SKStoreReviewController` on iOS) — there are NO app-owned
/// strings, hence zero ARB impact.
///
/// LIBRE-BUILD SAFETY (never throws): the store-review interaction goes
/// through the flavor-selected [reviewPrompterProvider] ([ReviewPrompter]) —
/// the libre / F-Droid build gets [NoopReviewPrompter], which reports
/// unavailable and never touches the Play-Core-backed `in_app_review` plugin
/// (`com.google.android.play:review`, absent from the `fdroid` flavor).
/// Belt-and-braces, every interaction is ALSO wrapped in a catch-all that
/// swallows any `NoClassDefFoundError` / `MissingPluginException` and no-ops,
/// keeping every build crash-free. Both guarantees are validated by
/// `test/core/feedback/in_app_review_service_test.dart`.
///
/// `keepAlive: true` because the counter must survive across route churn —
/// each successful search anywhere in the app feeds the same tally.
@Riverpod(keepAlive: true)
class InAppReviewService extends _$InAppReviewService {
  /// Clock seam — overridable so the 30-day cooldown is testable without
  /// real wall-clock waits. Defaults to [DateTime.now].
  ///
  /// The store-review interaction itself is the flavor-selected
  /// [reviewPrompterProvider] ([ReviewPrompter]) — [StoreReviewPrompter] on
  /// Play/iOS, [NoopReviewPrompter] on the libre build — so tests override
  /// that provider rather than a plugin seam here.
  DateTime Function() now = DateTime.now;

  @override
  void build() {}

  /// Records one positive moment and, if the throttle gates allow, asks the
  /// OS to show its review dialog.
  ///
  /// A prompt is attempted only when the accumulated count reaches
  /// [kInAppReviewSignalThreshold] AND at least [kInAppReviewMinInterval]
  /// has elapsed since the last attempt (or none has ever happened). On an
  /// attempt the counter is reset to 0 and the current time is stamped so
  /// the next prompt is at least 30 days out.
  ///
  /// NEVER THROWS: any storage or platform-channel fault is caught, logged,
  /// and swallowed (the libre build, where Play Core is absent, simply
  /// no-ops). Fire-and-forget callers can `unawaited(...)` it safely.
  Future<void> recordPositiveSignal() async {
    try {
      final storage = ref.read(settingsStorageProvider);
      final count = _readCount(storage) + 1;

      if (!_shouldPrompt(storage, count)) {
        await storage.putSetting(
          StorageKeys.inAppReviewPositiveSignalCount,
          count,
        );
        return;
      }

      // Reset + stamp BEFORE the platform call so a throw inside
      // requestReview() still consumes the cooldown — we never spam the
      // user with retries on a flaky channel.
      await storage.putSetting(StorageKeys.inAppReviewPositiveSignalCount, 0);
      await storage.putSetting(
        StorageKeys.inAppReviewLastPromptIso,
        now().toIso8601String(),
      );

      final prompter = ref.read(reviewPrompterProvider);
      if (await prompter.isAvailable()) {
        await prompter.requestReview();
      }
    } catch (e, st) {
      // Swallow everything — including NoClassDefFoundError /
      // MissingPluginException on the libre build, where Play Core is
      // stripped. A review prompt is never important enough to crash on.
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'InAppReviewService.recordPositiveSignal',
      }));
    }
  }

  /// Current positive-signal tally; 0 when absent or unparsable.
  int _readCount(dynamic storage) {
    final raw = storage.getSetting(StorageKeys.inAppReviewPositiveSignalCount);
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  /// True when [count] has reached the threshold AND the cooldown has
  /// elapsed (or we have never prompted).
  bool _shouldPrompt(dynamic storage, int count) {
    if (count < kInAppReviewSignalThreshold) return false;
    final raw = storage.getSetting(StorageKeys.inAppReviewLastPromptIso);
    if (raw is! String || raw.isEmpty) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return now().difference(last) >= kInAppReviewMinInterval;
  }
}
