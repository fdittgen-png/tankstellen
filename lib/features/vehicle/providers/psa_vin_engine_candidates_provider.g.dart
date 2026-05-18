// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'psa_vin_engine_candidates_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Offline engine-candidate set for a PSA VIN (#1864).
///
/// Decodes [vin] via [decodedVinProvider] (offline WMI + position-10
/// year, no proprietary VDS table) and resolves the reference-catalog
/// candidates whose make + generation match — see
/// [resolvePsaEngineCandidates].
///
/// Returns an empty list for a non-PSA VIN, an undecodable VIN, or
/// when nothing in the catalog matches. Keyed by VIN so two callers
/// asking for the same VIN share one resolution.

@ProviderFor(psaVinEngineCandidates)
final psaVinEngineCandidatesProvider = PsaVinEngineCandidatesFamily._();

/// Offline engine-candidate set for a PSA VIN (#1864).
///
/// Decodes [vin] via [decodedVinProvider] (offline WMI + position-10
/// year, no proprietary VDS table) and resolves the reference-catalog
/// candidates whose make + generation match — see
/// [resolvePsaEngineCandidates].
///
/// Returns an empty list for a non-PSA VIN, an undecodable VIN, or
/// when nothing in the catalog matches. Keyed by VIN so two callers
/// asking for the same VIN share one resolution.

final class PsaVinEngineCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReferenceVehicle>>,
          List<ReferenceVehicle>,
          FutureOr<List<ReferenceVehicle>>
        >
    with
        $FutureModifier<List<ReferenceVehicle>>,
        $FutureProvider<List<ReferenceVehicle>> {
  /// Offline engine-candidate set for a PSA VIN (#1864).
  ///
  /// Decodes [vin] via [decodedVinProvider] (offline WMI + position-10
  /// year, no proprietary VDS table) and resolves the reference-catalog
  /// candidates whose make + generation match — see
  /// [resolvePsaEngineCandidates].
  ///
  /// Returns an empty list for a non-PSA VIN, an undecodable VIN, or
  /// when nothing in the catalog matches. Keyed by VIN so two callers
  /// asking for the same VIN share one resolution.
  PsaVinEngineCandidatesProvider._({
    required PsaVinEngineCandidatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'psaVinEngineCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$psaVinEngineCandidatesHash();

  @override
  String toString() {
    return r'psaVinEngineCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ReferenceVehicle>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReferenceVehicle>> create(Ref ref) {
    final argument = this.argument as String;
    return psaVinEngineCandidates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PsaVinEngineCandidatesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$psaVinEngineCandidatesHash() =>
    r'3fdb281d847d10a6a7fa6b70678c5565fe440c69';

/// Offline engine-candidate set for a PSA VIN (#1864).
///
/// Decodes [vin] via [decodedVinProvider] (offline WMI + position-10
/// year, no proprietary VDS table) and resolves the reference-catalog
/// candidates whose make + generation match — see
/// [resolvePsaEngineCandidates].
///
/// Returns an empty list for a non-PSA VIN, an undecodable VIN, or
/// when nothing in the catalog matches. Keyed by VIN so two callers
/// asking for the same VIN share one resolution.

final class PsaVinEngineCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ReferenceVehicle>>, String> {
  PsaVinEngineCandidatesFamily._()
    : super(
        retry: null,
        name: r'psaVinEngineCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Offline engine-candidate set for a PSA VIN (#1864).
  ///
  /// Decodes [vin] via [decodedVinProvider] (offline WMI + position-10
  /// year, no proprietary VDS table) and resolves the reference-catalog
  /// candidates whose make + generation match — see
  /// [resolvePsaEngineCandidates].
  ///
  /// Returns an empty list for a non-PSA VIN, an undecodable VIN, or
  /// when nothing in the catalog matches. Keyed by VIN so two callers
  /// asking for the same VIN share one resolution.

  PsaVinEngineCandidatesProvider call(String vin) =>
      PsaVinEngineCandidatesProvider._(argument: vin, from: this);

  @override
  String toString() => r'psaVinEngineCandidatesProvider';
}
