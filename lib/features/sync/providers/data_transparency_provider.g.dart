// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'data_transparency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DataTransparencyController)
final dataTransparencyControllerProvider =
    DataTransparencyControllerProvider._();

final class DataTransparencyControllerProvider
    extends
        $NotifierProvider<DataTransparencyController, DataTransparencyState> {
  DataTransparencyControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dataTransparencyControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dataTransparencyControllerHash();

  @$internal
  @override
  DataTransparencyController create() => DataTransparencyController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DataTransparencyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DataTransparencyState>(value),
    );
  }
}

String _$dataTransparencyControllerHash() =>
    r'4a7a0b7e3c00cbf416ad1438accc448f1e9ae247';

abstract class _$DataTransparencyController
    extends $Notifier<DataTransparencyState> {
  DataTransparencyState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DataTransparencyState, DataTransparencyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DataTransparencyState, DataTransparencyState>,
              DataTransparencyState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
