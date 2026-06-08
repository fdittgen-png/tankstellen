// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'in_app_review_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Asks the OS to show its native store-review dialog at genuine positive
/// moments, throttled by a count threshold and a 30-day cooldown (#3069).
///
/// The dialog is rendered entirely by the platform (Play In-App Review API
/// on Android, `SKStoreReviewController` on iOS) — there are NO app-owned
/// strings, hence zero ARB impact.
///
/// LIBRE-BUILD SAFETY (never throws): the Android side of `in_app_review`
/// depends on Play Core (`com.google.android.play:review`), which is a
/// proprietary group STRIPPED from the F-Droid (`fdroid`) flavor (see
/// `android/app/build.gradle.kts` `gmsExcludeGroups` and
/// `scripts/audit_no_gms.sh`). On that build the review classes are absent,
/// so touching the plugin would throw `NoClassDefFoundError` /
/// `MissingPluginException`. Every interaction with the reviewer — including
/// the `isAvailable()` probe — is therefore wrapped in a catch-all that
/// swallows the error and no-ops, keeping the libre build crash-free. This
/// guarantee is validated by the fault-injection test in
/// `test/core/feedback/in_app_review_service_test.dart`.
///
/// `keepAlive: true` because the counter must survive across route churn —
/// each successful search anywhere in the app feeds the same tally.

@ProviderFor(InAppReviewService)
final inAppReviewServiceProvider = InAppReviewServiceProvider._();

/// Asks the OS to show its native store-review dialog at genuine positive
/// moments, throttled by a count threshold and a 30-day cooldown (#3069).
///
/// The dialog is rendered entirely by the platform (Play In-App Review API
/// on Android, `SKStoreReviewController` on iOS) — there are NO app-owned
/// strings, hence zero ARB impact.
///
/// LIBRE-BUILD SAFETY (never throws): the Android side of `in_app_review`
/// depends on Play Core (`com.google.android.play:review`), which is a
/// proprietary group STRIPPED from the F-Droid (`fdroid`) flavor (see
/// `android/app/build.gradle.kts` `gmsExcludeGroups` and
/// `scripts/audit_no_gms.sh`). On that build the review classes are absent,
/// so touching the plugin would throw `NoClassDefFoundError` /
/// `MissingPluginException`. Every interaction with the reviewer — including
/// the `isAvailable()` probe — is therefore wrapped in a catch-all that
/// swallows the error and no-ops, keeping the libre build crash-free. This
/// guarantee is validated by the fault-injection test in
/// `test/core/feedback/in_app_review_service_test.dart`.
///
/// `keepAlive: true` because the counter must survive across route churn —
/// each successful search anywhere in the app feeds the same tally.
final class InAppReviewServiceProvider
    extends $NotifierProvider<InAppReviewService, void> {
  /// Asks the OS to show its native store-review dialog at genuine positive
  /// moments, throttled by a count threshold and a 30-day cooldown (#3069).
  ///
  /// The dialog is rendered entirely by the platform (Play In-App Review API
  /// on Android, `SKStoreReviewController` on iOS) — there are NO app-owned
  /// strings, hence zero ARB impact.
  ///
  /// LIBRE-BUILD SAFETY (never throws): the Android side of `in_app_review`
  /// depends on Play Core (`com.google.android.play:review`), which is a
  /// proprietary group STRIPPED from the F-Droid (`fdroid`) flavor (see
  /// `android/app/build.gradle.kts` `gmsExcludeGroups` and
  /// `scripts/audit_no_gms.sh`). On that build the review classes are absent,
  /// so touching the plugin would throw `NoClassDefFoundError` /
  /// `MissingPluginException`. Every interaction with the reviewer — including
  /// the `isAvailable()` probe — is therefore wrapped in a catch-all that
  /// swallows the error and no-ops, keeping the libre build crash-free. This
  /// guarantee is validated by the fault-injection test in
  /// `test/core/feedback/in_app_review_service_test.dart`.
  ///
  /// `keepAlive: true` because the counter must survive across route churn —
  /// each successful search anywhere in the app feeds the same tally.
  InAppReviewServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inAppReviewServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inAppReviewServiceHash();

  @$internal
  @override
  InAppReviewService create() => InAppReviewService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$inAppReviewServiceHash() =>
    r'550e05de2dcaa51191b8b64f80590d469a91c3e3';

/// Asks the OS to show its native store-review dialog at genuine positive
/// moments, throttled by a count threshold and a 30-day cooldown (#3069).
///
/// The dialog is rendered entirely by the platform (Play In-App Review API
/// on Android, `SKStoreReviewController` on iOS) — there are NO app-owned
/// strings, hence zero ARB impact.
///
/// LIBRE-BUILD SAFETY (never throws): the Android side of `in_app_review`
/// depends on Play Core (`com.google.android.play:review`), which is a
/// proprietary group STRIPPED from the F-Droid (`fdroid`) flavor (see
/// `android/app/build.gradle.kts` `gmsExcludeGroups` and
/// `scripts/audit_no_gms.sh`). On that build the review classes are absent,
/// so touching the plugin would throw `NoClassDefFoundError` /
/// `MissingPluginException`. Every interaction with the reviewer — including
/// the `isAvailable()` probe — is therefore wrapped in a catch-all that
/// swallows the error and no-ops, keeping the libre build crash-free. This
/// guarantee is validated by the fault-injection test in
/// `test/core/feedback/in_app_review_service_test.dart`.
///
/// `keepAlive: true` because the counter must survive across route churn —
/// each successful search anywhere in the app feeds the same tally.

abstract class _$InAppReviewService extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
