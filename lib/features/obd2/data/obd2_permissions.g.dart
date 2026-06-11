// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_permissions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(obd2Permissions)
final obd2PermissionsProvider = Obd2PermissionsProvider._();

final class Obd2PermissionsProvider
    extends
        $FunctionalProvider<Obd2Permissions, Obd2Permissions, Obd2Permissions>
    with $Provider<Obd2Permissions> {
  Obd2PermissionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2PermissionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2PermissionsHash();

  @$internal
  @override
  $ProviderElement<Obd2Permissions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Obd2Permissions create(Ref ref) {
    return obd2Permissions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2Permissions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2Permissions>(value),
    );
  }
}

String _$obd2PermissionsHash() => r'0d2d01b1236c68dc6a90d1f62aa188d08fd95f56';
