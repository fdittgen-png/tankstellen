// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gdpr_consent_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GdprConsentFormController)
final gdprConsentFormControllerProvider = GdprConsentFormControllerProvider._();

final class GdprConsentFormControllerProvider
    extends $NotifierProvider<GdprConsentFormController, GdprConsentFormState> {
  GdprConsentFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gdprConsentFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gdprConsentFormControllerHash();

  @$internal
  @override
  GdprConsentFormController create() => GdprConsentFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GdprConsentFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GdprConsentFormState>(value),
    );
  }
}

String _$gdprConsentFormControllerHash() =>
    r'5cc0aa57a8a58eb3e6072fd74544a091d6961dfa';

abstract class _$GdprConsentFormController
    extends $Notifier<GdprConsentFormState> {
  GdprConsentFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<GdprConsentFormState, GdprConsentFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GdprConsentFormState, GdprConsentFormState>,
              GdprConsentFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
