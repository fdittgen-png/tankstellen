// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_position_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserPosition)
final userPositionProvider = UserPositionProvider._();

final class UserPositionProvider
    extends $NotifierProvider<UserPosition, UserPositionData?> {
  UserPositionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userPositionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userPositionHash();

  @$internal
  @override
  UserPosition create() => UserPosition();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserPositionData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserPositionData?>(value),
    );
  }
}

String _$userPositionHash() => r'05edbca12d5ad7b8fbda4d65c48f71f0dde7cc0d';

abstract class _$UserPosition extends $Notifier<UserPositionData?> {
  UserPositionData? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UserPositionData?, UserPositionData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserPositionData?, UserPositionData?>,
              UserPositionData?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
