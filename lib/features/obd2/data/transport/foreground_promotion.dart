// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// #4355 — the acknowledgement contract for the native Android presence
/// foreground service.
///
/// Its whole reason to exist is that a `ComponentName` is not a promotion:
/// `startForegroundService` returning non-null proves only that the OS
/// *created* the service, and the app used to answer "armed" on that alone.
/// The types here name what the OS actually did, so a refusal is a value the
/// caller can act on rather than a silence.
///
/// Lives beside [AndroidBackgroundAdapterListener] rather than inside it so
/// later work (#4352's recording-protection lease) can depend on the contract
/// without depending on the presence watcher.
const Duration kForegroundPromotionAckTimeout = Duration(seconds: 8);

/// Native event type name for a promotion acknowledgement. Mirrors
/// `BackgroundAdapterChannel.EVENT_PROMOTED`; keep in sync.
const String kFgsPromotedEvent = 'fgsPromoted';

/// Native event type name for a promotion refusal. Mirrors
/// `BackgroundAdapterChannel.EVENT_START_FAILED`; keep in sync.
const String kFgsStartFailedEvent = 'fgsStartFailed';

/// What the OS actually did with a request to promote the native presence
/// watcher to the foreground.
///
/// Only [promoted] means the service is running in the foreground. Everything
/// else is a degrade: the caller keeps recording without a presence watcher
/// and must not claim protected background operation. A *presence* watcher's
/// promotion is in any case not evidence that a *recording* is protected —
/// #4352 owns that verdict.
enum ForegroundPromotionOutcome {
  /// The service was promoted and owns a live GATT watcher.
  promoted,

  /// The `<service>` is absent from this build's manifest (#3173 / #3246).
  unavailable,

  /// A `FOREGROUND_SERVICE*` permission is not held.
  permissionDenied,

  /// Android 12+ refused a background start
  /// (`ForegroundServiceStartNotAllowedException`).
  notAllowedInBackground,

  /// Promotion held, but the platform refused the BLE connection.
  gattUnavailable,

  /// The OS refused for some other reason.
  refused,

  /// No acknowledgement arrived within the bound.
  timedOut,

  /// A newer arm, or an explicit stop, replaced this request before it was
  /// acknowledged.
  superseded,
}

/// A promotion acknowledgement (or refusal) observed on the native event
/// stream, exposed so later work can watch the same contract instead of
/// inventing a second one.
@immutable
class ForegroundPromotionEvent {
  const ForegroundPromotionEvent({
    required this.outcome,
    required this.at,
    this.generation,
  });

  /// What the OS did.
  final ForegroundPromotionOutcome outcome;

  /// Native timestamp of the acknowledgement.
  final DateTime at;

  /// The monotonic arm generation, present on an acknowledgement only. A
  /// callback or lease tagged with a superseded generation is stale.
  final int? generation;
}

/// Maps a native channel error code onto the typed outcome. Unknown codes
/// stay [ForegroundPromotionOutcome.refused] — never `promoted`.
ForegroundPromotionOutcome foregroundPromotionOutcomeForCode(
  String code,
  String? message,
) {
  switch (code) {
    case 'unavailable':
      return ForegroundPromotionOutcome.unavailable;
    case 'permission':
      return ForegroundPromotionOutcome.permissionDenied;
    case 'promotionTimeout':
      return ForegroundPromotionOutcome.timedOut;
    case 'superseded':
      return ForegroundPromotionOutcome.superseded;
    case 'promotionRefused':
      // The message carries the native PromotionFailureReason wire name.
      return foregroundPromotionOutcomeForReason(message);
    default:
      return ForegroundPromotionOutcome.refused;
  }
}

/// Maps a native `PromotionFailureReason.wireName` onto the typed outcome.
ForegroundPromotionOutcome foregroundPromotionOutcomeForReason(String? reason) {
  switch (reason) {
    case 'notAllowedInBackground':
      return ForegroundPromotionOutcome.notAllowedInBackground;
    case 'permissionDenied':
      return ForegroundPromotionOutcome.permissionDenied;
    case 'gattUnavailable':
      return ForegroundPromotionOutcome.gattUnavailable;
    default:
      return ForegroundPromotionOutcome.refused;
  }
}
