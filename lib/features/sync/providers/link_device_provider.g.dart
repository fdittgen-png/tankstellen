// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_device_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LinkDeviceController)
final linkDeviceControllerProvider = LinkDeviceControllerProvider._();

final class LinkDeviceControllerProvider
    extends $NotifierProvider<LinkDeviceController, LinkDeviceState> {
  LinkDeviceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkDeviceControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkDeviceControllerHash();

  @$internal
  @override
  LinkDeviceController create() => LinkDeviceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkDeviceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkDeviceState>(value),
    );
  }
}

String _$linkDeviceControllerHash() =>
    r'ba1275e6f78b156094aa2039806277d33d831635';

abstract class _$LinkDeviceController extends $Notifier<LinkDeviceState> {
  LinkDeviceState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LinkDeviceState, LinkDeviceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LinkDeviceState, LinkDeviceState>,
              LinkDeviceState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
