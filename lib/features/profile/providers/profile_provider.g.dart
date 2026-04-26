// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveProfile)
final activeProfileProvider = ActiveProfileProvider._();

final class ActiveProfileProvider
    extends $NotifierProvider<ActiveProfile, UserProfile?> {
  ActiveProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeProfileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeProfileHash();

  @$internal
  @override
  ActiveProfile create() => ActiveProfile();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfile? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfile?>(value),
    );
  }
}

String _$activeProfileHash() => r'e3ec7b96473f7ce05792388f01558c4b6d5a2e68';

abstract class _$ActiveProfile extends $Notifier<UserProfile?> {
  UserProfile? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UserProfile?, UserProfile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserProfile?, UserProfile?>,
              UserProfile?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(allProfiles)
final allProfilesProvider = AllProfilesProvider._();

final class AllProfilesProvider
    extends
        $FunctionalProvider<
          List<UserProfile>,
          List<UserProfile>,
          List<UserProfile>
        >
    with $Provider<List<UserProfile>> {
  AllProfilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allProfilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allProfilesHash();

  @$internal
  @override
  $ProviderElement<List<UserProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<UserProfile> create(Ref ref) {
    return allProfiles(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<UserProfile> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<UserProfile>>(value),
    );
  }
}

String _$allProfilesHash() => r'594398ed1812eee15c63b89558ca457edc8f5a17';
