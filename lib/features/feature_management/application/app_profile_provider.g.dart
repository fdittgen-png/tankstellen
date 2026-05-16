// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hive-backed repository for the active [AppProfile] (#1517).
///
/// Returns `null` when the [AppProfileRepository.boxName] box has not
/// been opened. Tests that don't initialise Hive get a no-op so the
/// provider stays usable without persistence.

@ProviderFor(appProfileRepository)
final appProfileRepositoryProvider = AppProfileRepositoryProvider._();

/// Hive-backed repository for the active [AppProfile] (#1517).
///
/// Returns `null` when the [AppProfileRepository.boxName] box has not
/// been opened. Tests that don't initialise Hive get a no-op so the
/// provider stays usable without persistence.

final class AppProfileRepositoryProvider
    extends
        $FunctionalProvider<
          AppProfileRepository?,
          AppProfileRepository?,
          AppProfileRepository?
        >
    with $Provider<AppProfileRepository?> {
  /// Hive-backed repository for the active [AppProfile] (#1517).
  ///
  /// Returns `null` when the [AppProfileRepository.boxName] box has not
  /// been opened. Tests that don't initialise Hive get a no-op so the
  /// provider stays usable without persistence.
  AppProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appProfileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppProfileRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppProfileRepository? create(Ref ref) {
    return appProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppProfileRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppProfileRepository?>(value),
    );
  }
}

String _$appProfileRepositoryHash() =>
    r'23d9aab2c07b3fb3a00c8699ce607981d01bb7e0';

/// Active "use mode" profile (#1517).
///
/// State is `null` when the user has never chosen on this install — the
/// onboarding wizard's profile-choice page is the gate. Otherwise the
/// state is the persisted [AppProfile].
///
/// On first build, the notifier reconciles three startup states:
/// 1. Profile box empty AND feature_flags box empty → fresh install,
///    state stays `null` until the wizard sets it.
/// 2. Profile box empty AND feature_flags box populated → pre-#1517
///    install. Persist [AppProfile.custom] so the user keeps their
///    existing flag set untouched and the Settings selector renders.
/// 3. Profile box populated → return the persisted profile.
///
/// `select(profile)` applies the corresponding bundle from
/// [appProfileBundles] to the central feature-flag store atomically.
/// Picking [AppProfile.custom] explicitly is a no-op on flags — the
/// user's current set is whatever they last persisted.

@ProviderFor(ActiveAppProfile)
final activeAppProfileProvider = ActiveAppProfileProvider._();

/// Active "use mode" profile (#1517).
///
/// State is `null` when the user has never chosen on this install — the
/// onboarding wizard's profile-choice page is the gate. Otherwise the
/// state is the persisted [AppProfile].
///
/// On first build, the notifier reconciles three startup states:
/// 1. Profile box empty AND feature_flags box empty → fresh install,
///    state stays `null` until the wizard sets it.
/// 2. Profile box empty AND feature_flags box populated → pre-#1517
///    install. Persist [AppProfile.custom] so the user keeps their
///    existing flag set untouched and the Settings selector renders.
/// 3. Profile box populated → return the persisted profile.
///
/// `select(profile)` applies the corresponding bundle from
/// [appProfileBundles] to the central feature-flag store atomically.
/// Picking [AppProfile.custom] explicitly is a no-op on flags — the
/// user's current set is whatever they last persisted.
final class ActiveAppProfileProvider
    extends $NotifierProvider<ActiveAppProfile, AppProfile?> {
  /// Active "use mode" profile (#1517).
  ///
  /// State is `null` when the user has never chosen on this install — the
  /// onboarding wizard's profile-choice page is the gate. Otherwise the
  /// state is the persisted [AppProfile].
  ///
  /// On first build, the notifier reconciles three startup states:
  /// 1. Profile box empty AND feature_flags box empty → fresh install,
  ///    state stays `null` until the wizard sets it.
  /// 2. Profile box empty AND feature_flags box populated → pre-#1517
  ///    install. Persist [AppProfile.custom] so the user keeps their
  ///    existing flag set untouched and the Settings selector renders.
  /// 3. Profile box populated → return the persisted profile.
  ///
  /// `select(profile)` applies the corresponding bundle from
  /// [appProfileBundles] to the central feature-flag store atomically.
  /// Picking [AppProfile.custom] explicitly is a no-op on flags — the
  /// user's current set is whatever they last persisted.
  ActiveAppProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeAppProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeAppProfileHash();

  @$internal
  @override
  ActiveAppProfile create() => ActiveAppProfile();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppProfile? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppProfile?>(value),
    );
  }
}

String _$activeAppProfileHash() => r'12488e4871dca36942cbe08f555511c2606c05be';

/// Active "use mode" profile (#1517).
///
/// State is `null` when the user has never chosen on this install — the
/// onboarding wizard's profile-choice page is the gate. Otherwise the
/// state is the persisted [AppProfile].
///
/// On first build, the notifier reconciles three startup states:
/// 1. Profile box empty AND feature_flags box empty → fresh install,
///    state stays `null` until the wizard sets it.
/// 2. Profile box empty AND feature_flags box populated → pre-#1517
///    install. Persist [AppProfile.custom] so the user keeps their
///    existing flag set untouched and the Settings selector renders.
/// 3. Profile box populated → return the persisted profile.
///
/// `select(profile)` applies the corresponding bundle from
/// [appProfileBundles] to the central feature-flag store atomically.
/// Picking [AppProfile.custom] explicitly is a no-op on flags — the
/// user's current set is whatever they last persisted.

abstract class _$ActiveAppProfile extends $Notifier<AppProfile?> {
  AppProfile? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppProfile?, AppProfile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppProfile?, AppProfile?>,
              AppProfile?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
