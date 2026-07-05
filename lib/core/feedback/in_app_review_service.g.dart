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

@ProviderFor(InAppReviewService)
final inAppReviewServiceProvider = InAppReviewServiceProvider._();

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
final class InAppReviewServiceProvider
    extends $NotifierProvider<InAppReviewService, void> {
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
    r'dfe557c1b311ee4f0ad41fd1ba1ee742f6a1048e';

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
