// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_coverage_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Classify the user's location coverage (#3361).
///
/// Splits the prior single "outside coverage" bool so a supported-but-
/// unconfigured user is told to set up their country, while only a truly
/// unsupported country gets the "not available" message.

@ProviderFor(locationCoverage)
final locationCoverageProvider = LocationCoverageProvider._();

/// Classify the user's location coverage (#3361).
///
/// Splits the prior single "outside coverage" bool so a supported-but-
/// unconfigured user is told to set up their country, while only a truly
/// unsupported country gets the "not available" message.

final class LocationCoverageProvider
    extends
        $FunctionalProvider<
          LocationCoverageStatus,
          LocationCoverageStatus,
          LocationCoverageStatus
        >
    with $Provider<LocationCoverageStatus> {
  /// Classify the user's location coverage (#3361).
  ///
  /// Splits the prior single "outside coverage" bool so a supported-but-
  /// unconfigured user is told to set up their country, while only a truly
  /// unsupported country gets the "not available" message.
  LocationCoverageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationCoverageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationCoverageHash();

  @$internal
  @override
  $ProviderElement<LocationCoverageStatus> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationCoverageStatus create(Ref ref) {
    return locationCoverage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationCoverageStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationCoverageStatus>(value),
    );
  }
}

String _$locationCoverageHash() => r'd52f22c071750d9f4df39cfbd57727a5aae4c05f';
