// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Libre / F-Droid no-op stand-in for the `in_app_review` plugin (#3479).
///
/// API-compatible with the upstream `InAppReview` surface the app uses, but
/// backed by nothing — there is no store-review flow on the GMS-free build, so
/// [isAvailable] is always false and the actions are no-ops. Because this
/// package declares no native plugin, no Play Core class reaches the fdroid dex.
class InAppReview {
  InAppReview._();

  /// Singleton, mirroring the upstream `InAppReview.instance`.
  static final InAppReview instance = InAppReview._();

  /// The store-review flow is never available on the libre build.
  Future<bool> isAvailable() async => false;

  /// No-op: there is no native review dialog on the libre build.
  Future<void> requestReview() async {}

  /// No-op: no store to open on the libre build.
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {}
}
