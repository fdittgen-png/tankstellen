// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_edit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Family provider keyed on the profile id, so a sheet edit never leaks
/// across profiles and each sheet gets its own scoped state that is
/// automatically disposed when the sheet closes.

@ProviderFor(ProfileEditController)
final profileEditControllerProvider = ProfileEditControllerFamily._();

/// Family provider keyed on the profile id, so a sheet edit never leaks
/// across profiles and each sheet gets its own scoped state that is
/// automatically disposed when the sheet closes.
final class ProfileEditControllerProvider
    extends $NotifierProvider<ProfileEditController, ProfileEditState> {
  /// Family provider keyed on the profile id, so a sheet edit never leaks
  /// across profiles and each sheet gets its own scoped state that is
  /// automatically disposed when the sheet closes.
  ProfileEditControllerProvider._({
    required ProfileEditControllerFamily super.from,
    required UserProfile super.argument,
  }) : super(
         retry: null,
         name: r'profileEditControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileEditControllerHash();

  @override
  String toString() {
    return r'profileEditControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProfileEditController create() => ProfileEditController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileEditState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileEditState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileEditControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileEditControllerHash() =>
    r'4d4cd5cae003ebdf5b7088f808e070d10ad060d6';

/// Family provider keyed on the profile id, so a sheet edit never leaks
/// across profiles and each sheet gets its own scoped state that is
/// automatically disposed when the sheet closes.

final class ProfileEditControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProfileEditController,
          ProfileEditState,
          ProfileEditState,
          ProfileEditState,
          UserProfile
        > {
  ProfileEditControllerFamily._()
    : super(
        retry: null,
        name: r'profileEditControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider keyed on the profile id, so a sheet edit never leaks
  /// across profiles and each sheet gets its own scoped state that is
  /// automatically disposed when the sheet closes.

  ProfileEditControllerProvider call(UserProfile initial) =>
      ProfileEditControllerProvider._(argument: initial, from: this);

  @override
  String toString() => r'profileEditControllerProvider';
}

/// Family provider keyed on the profile id, so a sheet edit never leaks
/// across profiles and each sheet gets its own scoped state that is
/// automatically disposed when the sheet closes.

abstract class _$ProfileEditController extends $Notifier<ProfileEditState> {
  late final _$args = ref.$arg as UserProfile;
  UserProfile get initial => _$args;

  ProfileEditState build(UserProfile initial);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfileEditState, ProfileEditState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileEditState, ProfileEditState>,
              ProfileEditState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
