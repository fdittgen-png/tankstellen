// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_border_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Computes cross-border price comparisons when the user is near a border.
///
/// Watches:
/// - [userPositionProvider] for the user's location
/// - [activeCountryProvider] for the current country
/// - [searchStateProvider] for current search results (to compute avg price)
/// - [selectedFuelTypeProvider] for the active fuel type
///
/// Returns a list of [CrossBorderComparison] for each neighboring country
/// within 30 km, or an empty list if the user is not near any border.

@ProviderFor(crossBorderComparisons)
final crossBorderComparisonsProvider = CrossBorderComparisonsProvider._();

/// Computes cross-border price comparisons when the user is near a border.
///
/// Watches:
/// - [userPositionProvider] for the user's location
/// - [activeCountryProvider] for the current country
/// - [searchStateProvider] for current search results (to compute avg price)
/// - [selectedFuelTypeProvider] for the active fuel type
///
/// Returns a list of [CrossBorderComparison] for each neighboring country
/// within 30 km, or an empty list if the user is not near any border.

final class CrossBorderComparisonsProvider
    extends
        $FunctionalProvider<
          List<CrossBorderComparison>,
          List<CrossBorderComparison>,
          List<CrossBorderComparison>
        >
    with $Provider<List<CrossBorderComparison>> {
  /// Computes cross-border price comparisons when the user is near a border.
  ///
  /// Watches:
  /// - [userPositionProvider] for the user's location
  /// - [activeCountryProvider] for the current country
  /// - [searchStateProvider] for current search results (to compute avg price)
  /// - [selectedFuelTypeProvider] for the active fuel type
  ///
  /// Returns a list of [CrossBorderComparison] for each neighboring country
  /// within 30 km, or an empty list if the user is not near any border.
  CrossBorderComparisonsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'crossBorderComparisonsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$crossBorderComparisonsHash();

  @$internal
  @override
  $ProviderElement<List<CrossBorderComparison>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<CrossBorderComparison> create(Ref ref) {
    return crossBorderComparisons(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CrossBorderComparison> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CrossBorderComparison>>(value),
    );
  }
}

String _$crossBorderComparisonsHash() =>
    r'2b5ae2c92a8a7e804832789baa87b683a5800d22';
