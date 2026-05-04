// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_capability_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current adapter's runtime [Obd2AdapterCapability], or null when no
/// adapter is connected (#1401 phase 6).
///
/// Returns a non-null value only when [Obd2ConnectionStatus] is in
/// the [Obd2ConnectionState.connected] state AND the producer that
/// flipped it stamped a capability. Every other state — idle,
/// attempting, unreachable, permissionDenied, or connected without a
/// capability stamp — yields null so the UI can collapse the
/// capability section.

@ProviderFor(currentObd2Capability)
final currentObd2CapabilityProvider = CurrentObd2CapabilityProvider._();

/// Current adapter's runtime [Obd2AdapterCapability], or null when no
/// adapter is connected (#1401 phase 6).
///
/// Returns a non-null value only when [Obd2ConnectionStatus] is in
/// the [Obd2ConnectionState.connected] state AND the producer that
/// flipped it stamped a capability. Every other state — idle,
/// attempting, unreachable, permissionDenied, or connected without a
/// capability stamp — yields null so the UI can collapse the
/// capability section.

final class CurrentObd2CapabilityProvider
    extends
        $FunctionalProvider<
          Obd2AdapterCapability?,
          Obd2AdapterCapability?,
          Obd2AdapterCapability?
        >
    with $Provider<Obd2AdapterCapability?> {
  /// Current adapter's runtime [Obd2AdapterCapability], or null when no
  /// adapter is connected (#1401 phase 6).
  ///
  /// Returns a non-null value only when [Obd2ConnectionStatus] is in
  /// the [Obd2ConnectionState.connected] state AND the producer that
  /// flipped it stamped a capability. Every other state — idle,
  /// attempting, unreachable, permissionDenied, or connected without a
  /// capability stamp — yields null so the UI can collapse the
  /// capability section.
  CurrentObd2CapabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentObd2CapabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentObd2CapabilityHash();

  @$internal
  @override
  $ProviderElement<Obd2AdapterCapability?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2AdapterCapability? create(Ref ref) {
    return currentObd2Capability(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2AdapterCapability? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2AdapterCapability?>(value),
    );
  }
}

String _$currentObd2CapabilityHash() =>
    r'4087d1c250dfe2a6303c4e44a3d812f95a315c0f';
