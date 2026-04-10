// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_wizard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingWizardController)
final onboardingWizardControllerProvider =
    OnboardingWizardControllerProvider._();

final class OnboardingWizardControllerProvider
    extends
        $NotifierProvider<OnboardingWizardController, OnboardingWizardState> {
  OnboardingWizardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingWizardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingWizardControllerHash();

  @$internal
  @override
  OnboardingWizardController create() => OnboardingWizardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingWizardState>(value),
    );
  }
}

String _$onboardingWizardControllerHash() =>
    r'9bad97ee4caa63b16dac391c66b7f20a69b642ce';

abstract class _$OnboardingWizardController
    extends $Notifier<OnboardingWizardState> {
  OnboardingWizardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OnboardingWizardState, OnboardingWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingWizardState, OnboardingWizardState>,
              OnboardingWizardState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
