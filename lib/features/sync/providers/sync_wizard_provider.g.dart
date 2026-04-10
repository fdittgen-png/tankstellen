// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_wizard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SyncWizardController)
final syncWizardControllerProvider = SyncWizardControllerProvider._();

final class SyncWizardControllerProvider
    extends $NotifierProvider<SyncWizardController, SyncWizardState> {
  SyncWizardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncWizardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncWizardControllerHash();

  @$internal
  @override
  SyncWizardController create() => SyncWizardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncWizardState>(value),
    );
  }
}

String _$syncWizardControllerHash() =>
    r'4b040164737b9a297867b70ce0e6d7efedc1e69d';

abstract class _$SyncWizardController extends $Notifier<SyncWizardState> {
  SyncWizardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SyncWizardState, SyncWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SyncWizardState, SyncWizardState>,
              SyncWizardState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
