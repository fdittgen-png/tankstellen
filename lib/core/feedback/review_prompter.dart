// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:in_app_review/in_app_review.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../platform/app_flavor.dart';

part 'review_prompter.g.dart';

/// A capability seam for asking the OS to show its native store-review dialog.
///
/// This is the [AppFlavor]-selected abstraction behind the store-review
/// feature (#3473). The Play/iOS build uses [StoreReviewPrompter] (the real
/// `in_app_review` plugin → Play In-App Review API / `SKStoreReviewController`);
/// the F-Droid / libre build uses [NoopReviewPrompter] and never reaches the
/// plugin's Play-Core-backed channel. Making the libre behaviour an EXPLICIT
/// no-op implementation — rather than a `try/catch` swallowing a
/// `NoClassDefFoundError` at runtime — is what lets the fdroid variant drop the
/// proprietary `in_app_review` Android module entirely without any libre code
/// path ever calling it.
abstract interface class ReviewPrompter {
  /// Whether the OS review flow is available right now.
  Future<bool> isAvailable();

  /// Ask the OS to present its native review dialog. The dialog is rendered
  /// entirely by the platform (no app-owned strings), and the OS additionally
  /// rate-limits it.
  Future<void> requestReview();
}

/// Real implementation backed by the `in_app_review` plugin. Used on Play + iOS.
class StoreReviewPrompter implements ReviewPrompter {
  StoreReviewPrompter([InAppReview? reviewer])
      : _reviewer = reviewer ?? InAppReview.instance;

  final InAppReview _reviewer;

  @override
  Future<bool> isAvailable() => _reviewer.isAvailable();

  @override
  Future<void> requestReview() => _reviewer.requestReview();
}

/// Libre / F-Droid implementation: the store-review flow is unavailable, so it
/// reports unavailable and does nothing. Never touches Play Core.
class NoopReviewPrompter implements ReviewPrompter {
  const NoopReviewPrompter();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> requestReview() async {}
}

/// Flavor-selected [ReviewPrompter]: the libre build gets the no-op, every
/// other build gets the real store prompter. Overridable in tests.
@Riverpod(keepAlive: true)
ReviewPrompter reviewPrompter(Ref ref) =>
    AppFlavor.isLibre ? const NoopReviewPrompter() : StoreReviewPrompter();
