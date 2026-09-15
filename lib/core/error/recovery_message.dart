// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The contract every user-facing failure satisfies (#4141, Epic #4132).
///
/// The diagnostic side of this app's error handling is strong — structured
/// traces, error layers, fallback chains, breadcrumbs, an
/// `ApplicationExitInfo` harvest, a crash journal. None of that changes.
/// What changes is that the machine model and the human model stop being
/// the same model, so a user never reads `RFCOMM connection failed ·
/// retry strategy exhausted`.
///
/// Four parts, in the order a person actually asks them:
///
///  1. **What happened** — "Car connection lost".
///  2. **Why it matters** — "Fuel use is estimated from GPS until it is
///     back".
///  3. **Can I continue** — "Recording continues". This is the part most
///     often missing and the one that decides whether someone
///     uninstalls; [whatStillWorks] is required, so a message cannot be
///     written without answering it.
///  4. **What do I do** — [primaryAction] is required for the same
///     reason. A failure with no offered action does not compile.
///
/// The diagnostic detail travels in [diagnostic] and belongs one tap
/// deeper — never on the first screen. This type changes what is SHOWN,
/// never what is RECORDED.
library;

import 'package:flutter/widgets.dart';

/// How much of the app still works.
///
/// Named for the user's question, not for a severity scale: a "warning"
/// and an "error" tell someone nothing about whether their recording is
/// still running.
enum RecoveryImpact {
  /// Everything still works; this failure cost the user nothing.
  unaffected,

  /// The app continues with less — a fallback, an estimate, a cache.
  degraded,

  /// The thing the user was doing has stopped.
  stopped,
}

/// One offered way out.
@immutable
class RecoveryAction {
  const RecoveryAction({
    required this.label,
    required this.onInvoke,
    this.icon,
  })  : isDestructive = false,
        destructiveBecause = null;

  /// An action that DESTROYS user data.
  ///
  /// #4118 is why this is a separate constructor with a required
  /// justification rather than a `bool`: the copy told users their data
  /// was damaged and to clear storage, for a fault that was neither —
  /// and clearing storage was the one action that made it unrecoverable.
  /// [becauseDataIsUnrecoverable] has to be written down, in the code,
  /// by whoever offers the button. A rule nobody can state is a rule
  /// nobody checked.
  const RecoveryAction.destructive({
    required this.label,
    required this.onInvoke,
    required String becauseDataIsUnrecoverable,
    this.icon,
  })  : isDestructive = true,
        destructiveBecause = becauseDataIsUnrecoverable;

  /// The button text. Localized by the caller — this type never builds
  /// user-facing strings (HARD RULE #1).
  final String label;

  final VoidCallback onInvoke;

  /// Optional leading glyph on the button.
  final IconData? icon;

  final bool isDestructive;

  /// Why destroying data is the only recovery here. Developer-facing;
  /// never rendered.
  final String? destructiveBecause;
}

/// A failure, as a person needs to read it.
@immutable
class RecoveryMessage {
  const RecoveryMessage({
    required this.whatHappened,
    required this.whyItMatters,
    required this.impact,
    required this.whatStillWorks,
    required this.primaryAction,
    this.secondaryAction,
    this.diagnostic = const [],
  });

  /// One short line naming the event in the user's terms. Never a
  /// transport, protocol, library or status code.
  final String whatHappened;

  /// What it costs them. The consequence, not the cause.
  final String whyItMatters;

  final RecoveryImpact impact;

  /// The answer to "can I continue" — in words, because
  /// [RecoveryImpact.degraded] on its own does not tell anyone whether
  /// their trip is still recording.
  final String whatStillWorks;

  final RecoveryAction primaryAction;
  final RecoveryAction? secondaryAction;

  /// The technical detail, shown only behind an explicit tap. Empty is
  /// fine; it is the one part that may be absent.
  final List<String> diagnostic;

  /// Every action offered, primary first.
  List<RecoveryAction> get actions =>
      [primaryAction, ?secondaryAction];
}
