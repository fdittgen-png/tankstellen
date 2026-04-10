// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_setup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SyncSetupController)
final syncSetupControllerProvider = SyncSetupControllerProvider._();

final class SyncSetupControllerProvider
    extends $NotifierProvider<SyncSetupController, SyncSetupState> {
  SyncSetupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncSetupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncSetupControllerHash();

  @$internal
  @override
  SyncSetupController create() => SyncSetupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncSetupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncSetupState>(value),
    );
  }
}

String _$syncSetupControllerHash() =>
    r'abedbdcdb726fa9b7577c621f83ca81de0c43243';

abstract class _$SyncSetupController extends $Notifier<SyncSetupState> {
  SyncSetupState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SyncSetupState, SyncSetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncSetupState, SyncSetupState>,
              SyncSetupState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
