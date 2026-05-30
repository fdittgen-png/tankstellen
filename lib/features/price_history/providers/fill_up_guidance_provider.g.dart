// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fill_up_guidance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// On-device "best time to fill up?" guidance for a station + fuel type
/// (#1543, no-ML heuristic).
///
/// Reads the locally collected price history (read-only) and folds it
/// into a [FillUpGuidance] via the pure [FillUpGuidancePredictor]. The
/// computation is entirely on-device — no network, no cloud, no model
/// artifact — so it honours the project's "no costs" constraint.
///
/// Returns `null` when:
///   * the [Feature.tflitePricePrediction] gate is effectively off
///     (this reuses the existing #1117 UI gate, which already cascades
///     through its `requires: {priceHistory}` edge), or
///   * the heuristic reports [FillUpGuidanceKind.insufficientData].
///
/// A non-null result always carries an actionable verdict the
/// [FillUpGuidanceCard] can render.

@ProviderFor(fillUpGuidance)
final fillUpGuidanceProvider = FillUpGuidanceFamily._();

/// On-device "best time to fill up?" guidance for a station + fuel type
/// (#1543, no-ML heuristic).
///
/// Reads the locally collected price history (read-only) and folds it
/// into a [FillUpGuidance] via the pure [FillUpGuidancePredictor]. The
/// computation is entirely on-device — no network, no cloud, no model
/// artifact — so it honours the project's "no costs" constraint.
///
/// Returns `null` when:
///   * the [Feature.tflitePricePrediction] gate is effectively off
///     (this reuses the existing #1117 UI gate, which already cascades
///     through its `requires: {priceHistory}` edge), or
///   * the heuristic reports [FillUpGuidanceKind.insufficientData].
///
/// A non-null result always carries an actionable verdict the
/// [FillUpGuidanceCard] can render.

final class FillUpGuidanceProvider
    extends
        $FunctionalProvider<FillUpGuidance?, FillUpGuidance?, FillUpGuidance?>
    with $Provider<FillUpGuidance?> {
  /// On-device "best time to fill up?" guidance for a station + fuel type
  /// (#1543, no-ML heuristic).
  ///
  /// Reads the locally collected price history (read-only) and folds it
  /// into a [FillUpGuidance] via the pure [FillUpGuidancePredictor]. The
  /// computation is entirely on-device — no network, no cloud, no model
  /// artifact — so it honours the project's "no costs" constraint.
  ///
  /// Returns `null` when:
  ///   * the [Feature.tflitePricePrediction] gate is effectively off
  ///     (this reuses the existing #1117 UI gate, which already cascades
  ///     through its `requires: {priceHistory}` edge), or
  ///   * the heuristic reports [FillUpGuidanceKind.insufficientData].
  ///
  /// A non-null result always carries an actionable verdict the
  /// [FillUpGuidanceCard] can render.
  FillUpGuidanceProvider._({
    required FillUpGuidanceFamily super.from,
    required (String, FuelType) super.argument,
  }) : super(
         retry: null,
         name: r'fillUpGuidanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fillUpGuidanceHash();

  @override
  String toString() {
    return r'fillUpGuidanceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<FillUpGuidance?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FillUpGuidance? create(Ref ref) {
    final argument = this.argument as (String, FuelType);
    return fillUpGuidance(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FillUpGuidance? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FillUpGuidance?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FillUpGuidanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fillUpGuidanceHash() => r'd3bd35a190dade11bbd64e59904ba654d25b2e85';

/// On-device "best time to fill up?" guidance for a station + fuel type
/// (#1543, no-ML heuristic).
///
/// Reads the locally collected price history (read-only) and folds it
/// into a [FillUpGuidance] via the pure [FillUpGuidancePredictor]. The
/// computation is entirely on-device — no network, no cloud, no model
/// artifact — so it honours the project's "no costs" constraint.
///
/// Returns `null` when:
///   * the [Feature.tflitePricePrediction] gate is effectively off
///     (this reuses the existing #1117 UI gate, which already cascades
///     through its `requires: {priceHistory}` edge), or
///   * the heuristic reports [FillUpGuidanceKind.insufficientData].
///
/// A non-null result always carries an actionable verdict the
/// [FillUpGuidanceCard] can render.

final class FillUpGuidanceFamily extends $Family
    with $FunctionalFamilyOverride<FillUpGuidance?, (String, FuelType)> {
  FillUpGuidanceFamily._()
    : super(
        retry: null,
        name: r'fillUpGuidanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// On-device "best time to fill up?" guidance for a station + fuel type
  /// (#1543, no-ML heuristic).
  ///
  /// Reads the locally collected price history (read-only) and folds it
  /// into a [FillUpGuidance] via the pure [FillUpGuidancePredictor]. The
  /// computation is entirely on-device — no network, no cloud, no model
  /// artifact — so it honours the project's "no costs" constraint.
  ///
  /// Returns `null` when:
  ///   * the [Feature.tflitePricePrediction] gate is effectively off
  ///     (this reuses the existing #1117 UI gate, which already cascades
  ///     through its `requires: {priceHistory}` edge), or
  ///   * the heuristic reports [FillUpGuidanceKind.insufficientData].
  ///
  /// A non-null result always carries an actionable verdict the
  /// [FillUpGuidanceCard] can render.

  FillUpGuidanceProvider call(String stationId, FuelType fuelType) =>
      FillUpGuidanceProvider._(argument: (stationId, fuelType), from: this);

  @override
  String toString() => r'fillUpGuidanceProvider';
}
