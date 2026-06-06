// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_prediction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Computes "best time to fill" predictions from locally stored price history.
///
/// Returns `null` when fewer than 10 data points are available — not enough
/// data to produce meaningful predictions.
///
/// As of #1117 phase 1, the provider also enriches the result with a
/// [PricePrediction.holidayPremium] derived from the new
/// [PriceFeatureExtractor] / [FeatureVector] contract. The future TFLite
/// phase 2 will replace this heuristic with model inference using the
/// same [FeatureVector] inputs.

@ProviderFor(pricePrediction)
final pricePredictionProvider = PricePredictionFamily._();

/// Computes "best time to fill" predictions from locally stored price history.
///
/// Returns `null` when fewer than 10 data points are available — not enough
/// data to produce meaningful predictions.
///
/// As of #1117 phase 1, the provider also enriches the result with a
/// [PricePrediction.holidayPremium] derived from the new
/// [PriceFeatureExtractor] / [FeatureVector] contract. The future TFLite
/// phase 2 will replace this heuristic with model inference using the
/// same [FeatureVector] inputs.

final class PricePredictionProvider
    extends
        $FunctionalProvider<
          PricePrediction?,
          PricePrediction?,
          PricePrediction?
        >
    with $Provider<PricePrediction?> {
  /// Computes "best time to fill" predictions from locally stored price history.
  ///
  /// Returns `null` when fewer than 10 data points are available — not enough
  /// data to produce meaningful predictions.
  ///
  /// As of #1117 phase 1, the provider also enriches the result with a
  /// [PricePrediction.holidayPremium] derived from the new
  /// [PriceFeatureExtractor] / [FeatureVector] contract. The future TFLite
  /// phase 2 will replace this heuristic with model inference using the
  /// same [FeatureVector] inputs.
  PricePredictionProvider._({
    required PricePredictionFamily super.from,
    required (String, FuelType) super.argument,
  }) : super(
         retry: null,
         name: r'pricePredictionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pricePredictionHash();

  @override
  String toString() {
    return r'pricePredictionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<PricePrediction?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PricePrediction? create(Ref ref) {
    final argument = this.argument as (String, FuelType);
    return pricePrediction(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PricePrediction? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PricePrediction?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PricePredictionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pricePredictionHash() => r'b5758319ef6aaff05b0cc2de8f3e11bd5b87ae0c';

/// Computes "best time to fill" predictions from locally stored price history.
///
/// Returns `null` when fewer than 10 data points are available — not enough
/// data to produce meaningful predictions.
///
/// As of #1117 phase 1, the provider also enriches the result with a
/// [PricePrediction.holidayPremium] derived from the new
/// [PriceFeatureExtractor] / [FeatureVector] contract. The future TFLite
/// phase 2 will replace this heuristic with model inference using the
/// same [FeatureVector] inputs.

final class PricePredictionFamily extends $Family
    with $FunctionalFamilyOverride<PricePrediction?, (String, FuelType)> {
  PricePredictionFamily._()
    : super(
        retry: null,
        name: r'pricePredictionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Computes "best time to fill" predictions from locally stored price history.
  ///
  /// Returns `null` when fewer than 10 data points are available — not enough
  /// data to produce meaningful predictions.
  ///
  /// As of #1117 phase 1, the provider also enriches the result with a
  /// [PricePrediction.holidayPremium] derived from the new
  /// [PriceFeatureExtractor] / [FeatureVector] contract. The future TFLite
  /// phase 2 will replace this heuristic with model inference using the
  /// same [FeatureVector] inputs.

  PricePredictionProvider call(String stationId, FuelType fuelType) =>
      PricePredictionProvider._(argument: (stationId, fuelType), from: this);

  @override
  String toString() => r'pricePredictionProvider';
}
