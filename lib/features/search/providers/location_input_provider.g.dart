// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_input_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocationInputController)
final locationInputControllerProvider = LocationInputControllerProvider._();

final class LocationInputControllerProvider
    extends $NotifierProvider<LocationInputController, LocationInputState> {
  LocationInputControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationInputControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationInputControllerHash();

  @$internal
  @override
  LocationInputController create() => LocationInputController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationInputState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationInputState>(value),
    );
  }
}

String _$locationInputControllerHash() =>
    r'377a0458d3364157b4ee0a59af3c7b5e87241fbb';

abstract class _$LocationInputController extends $Notifier<LocationInputState> {
  LocationInputState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LocationInputState, LocationInputState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocationInputState, LocationInputState>,
              LocationInputState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
