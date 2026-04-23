// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_obd2_connector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keep-alive so the default instance survives across onboarding step
/// rebuilds — the connector itself is stateless, but tests override
/// this provider with a stateful fake that must outlive the step's
/// `setState` calls.

@ProviderFor(onboardingObd2Connector)
final onboardingObd2ConnectorProvider = OnboardingObd2ConnectorProvider._();

/// Keep-alive so the default instance survives across onboarding step
/// rebuilds — the connector itself is stateless, but tests override
/// this provider with a stateful fake that must outlive the step's
/// `setState` calls.

final class OnboardingObd2ConnectorProvider
    extends
        $FunctionalProvider<
          OnboardingObd2Connector,
          OnboardingObd2Connector,
          OnboardingObd2Connector
        >
    with $Provider<OnboardingObd2Connector> {
  /// Keep-alive so the default instance survives across onboarding step
  /// rebuilds — the connector itself is stateless, but tests override
  /// this provider with a stateful fake that must outlive the step's
  /// `setState` calls.
  OnboardingObd2ConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingObd2ConnectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingObd2ConnectorHash();

  @$internal
  @override
  $ProviderElement<OnboardingObd2Connector> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnboardingObd2Connector create(Ref ref) {
    return onboardingObd2Connector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingObd2Connector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingObd2Connector>(value),
    );
  }
}

String _$onboardingObd2ConnectorHash() =>
    r'50db788ea2be65213db1224a96c21b64a4ed8d8c';
