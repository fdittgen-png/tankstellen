// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ntfy_setup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NtfySetupController)
final ntfySetupControllerProvider = NtfySetupControllerProvider._();

final class NtfySetupControllerProvider
    extends $NotifierProvider<NtfySetupController, NtfySetupState> {
  NtfySetupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ntfySetupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ntfySetupControllerHash();

  @$internal
  @override
  NtfySetupController create() => NtfySetupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NtfySetupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NtfySetupState>(value),
    );
  }
}

String _$ntfySetupControllerHash() =>
    r'a0c123f876898293f522695074da65c414899839';

abstract class _$NtfySetupController extends $Notifier<NtfySetupState> {
  NtfySetupState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NtfySetupState, NtfySetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NtfySetupState, NtfySetupState>,
              NtfySetupState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
