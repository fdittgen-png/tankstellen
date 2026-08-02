// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_scan_readiness.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(obd2ScanReadinessProbe)
final obd2ScanReadinessProbeProvider = Obd2ScanReadinessProbeProvider._();

final class Obd2ScanReadinessProbeProvider
    extends
        $FunctionalProvider<
          Obd2ScanReadinessProbe,
          Obd2ScanReadinessProbe,
          Obd2ScanReadinessProbe
        >
    with $Provider<Obd2ScanReadinessProbe> {
  Obd2ScanReadinessProbeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2ScanReadinessProbeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2ScanReadinessProbeHash();

  @$internal
  @override
  $ProviderElement<Obd2ScanReadinessProbe> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2ScanReadinessProbe create(Ref ref) {
    return obd2ScanReadinessProbe(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2ScanReadinessProbe value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2ScanReadinessProbe>(value),
    );
  }
}

String _$obd2ScanReadinessProbeHash() =>
    r'f69dc81e8662eec243e23cb450aa382b80498238';

/// Auto-disposing read of the current readiness. Deliberately NOT
/// cached across rebuilds — see [Obd2ScanReadinessProbe.resolve].

@ProviderFor(obd2ScanReadiness)
final obd2ScanReadinessProvider = Obd2ScanReadinessProvider._();

/// Auto-disposing read of the current readiness. Deliberately NOT
/// cached across rebuilds — see [Obd2ScanReadinessProbe.resolve].

final class Obd2ScanReadinessProvider
    extends
        $FunctionalProvider<
          AsyncValue<Obd2ScanReadiness>,
          Obd2ScanReadiness,
          FutureOr<Obd2ScanReadiness>
        >
    with
        $FutureModifier<Obd2ScanReadiness>,
        $FutureProvider<Obd2ScanReadiness> {
  /// Auto-disposing read of the current readiness. Deliberately NOT
  /// cached across rebuilds — see [Obd2ScanReadinessProbe.resolve].
  Obd2ScanReadinessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2ScanReadinessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2ScanReadinessHash();

  @$internal
  @override
  $FutureProviderElement<Obd2ScanReadiness> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Obd2ScanReadiness> create(Ref ref) {
    return obd2ScanReadiness(ref);
  }
}

String _$obd2ScanReadinessHash() => r'cc794968ebc4e4d230131b9f200d0339f3501897';
