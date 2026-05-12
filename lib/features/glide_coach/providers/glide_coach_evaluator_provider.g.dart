// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glide_coach_evaluator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the glide-coach evaluator (#1125 phase 3b).
///
/// Returns `null` when the compile-time master flag
/// [`kGlideCoachEnabled`] is `false` — that's production today, and
/// every consumer (currently only `tripRecordingProvider`) early-outs
/// on the null. Callers MUST treat null as "feature disabled, do
/// nothing" rather than constructing their own evaluator; the layered
/// kill-switch is the whole point.
///
/// When the master flag is true, the provider wires:
///   1. An [OsmTrafficSignalClient] (default Dio).
///   2. A [TrafficSignalRepository] backed by the
///      `traffic_signals_cache` Hive box (opened at startup by
///      [HiveBoxes.init]).
///   3. An [ImminentSignalDetector] over the repo.
///   4. A [GlideCoachEvaluator] over the detector, with the cool-down
///      and throttle threshold sourced from the user's
///      [GlideCoachSettings] (read once at construction; the evaluator
///      itself is stateless w.r.t. settings flips, so a settings change
///      that should re-tune thresholds invalidates this provider via
///      `ref.watch`).
///
/// Returns `null` (rather than throwing) when the Hive box isn't open —
/// matching the loyalty repository pattern for widget-test-friendly
/// no-ops on missing infrastructure.

@ProviderFor(glideCoachEvaluator)
final glideCoachEvaluatorProvider = GlideCoachEvaluatorProvider._();

/// Provider for the glide-coach evaluator (#1125 phase 3b).
///
/// Returns `null` when the compile-time master flag
/// [`kGlideCoachEnabled`] is `false` — that's production today, and
/// every consumer (currently only `tripRecordingProvider`) early-outs
/// on the null. Callers MUST treat null as "feature disabled, do
/// nothing" rather than constructing their own evaluator; the layered
/// kill-switch is the whole point.
///
/// When the master flag is true, the provider wires:
///   1. An [OsmTrafficSignalClient] (default Dio).
///   2. A [TrafficSignalRepository] backed by the
///      `traffic_signals_cache` Hive box (opened at startup by
///      [HiveBoxes.init]).
///   3. An [ImminentSignalDetector] over the repo.
///   4. A [GlideCoachEvaluator] over the detector, with the cool-down
///      and throttle threshold sourced from the user's
///      [GlideCoachSettings] (read once at construction; the evaluator
///      itself is stateless w.r.t. settings flips, so a settings change
///      that should re-tune thresholds invalidates this provider via
///      `ref.watch`).
///
/// Returns `null` (rather than throwing) when the Hive box isn't open —
/// matching the loyalty repository pattern for widget-test-friendly
/// no-ops on missing infrastructure.

final class GlideCoachEvaluatorProvider
    extends
        $FunctionalProvider<
          GlideCoachEvaluator?,
          GlideCoachEvaluator?,
          GlideCoachEvaluator?
        >
    with $Provider<GlideCoachEvaluator?> {
  /// Provider for the glide-coach evaluator (#1125 phase 3b).
  ///
  /// Returns `null` when the compile-time master flag
  /// [`kGlideCoachEnabled`] is `false` — that's production today, and
  /// every consumer (currently only `tripRecordingProvider`) early-outs
  /// on the null. Callers MUST treat null as "feature disabled, do
  /// nothing" rather than constructing their own evaluator; the layered
  /// kill-switch is the whole point.
  ///
  /// When the master flag is true, the provider wires:
  ///   1. An [OsmTrafficSignalClient] (default Dio).
  ///   2. A [TrafficSignalRepository] backed by the
  ///      `traffic_signals_cache` Hive box (opened at startup by
  ///      [HiveBoxes.init]).
  ///   3. An [ImminentSignalDetector] over the repo.
  ///   4. A [GlideCoachEvaluator] over the detector, with the cool-down
  ///      and throttle threshold sourced from the user's
  ///      [GlideCoachSettings] (read once at construction; the evaluator
  ///      itself is stateless w.r.t. settings flips, so a settings change
  ///      that should re-tune thresholds invalidates this provider via
  ///      `ref.watch`).
  ///
  /// Returns `null` (rather than throwing) when the Hive box isn't open —
  /// matching the loyalty repository pattern for widget-test-friendly
  /// no-ops on missing infrastructure.
  GlideCoachEvaluatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'glideCoachEvaluatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$glideCoachEvaluatorHash();

  @$internal
  @override
  $ProviderElement<GlideCoachEvaluator?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlideCoachEvaluator? create(Ref ref) {
    return glideCoachEvaluator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlideCoachEvaluator? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlideCoachEvaluator?>(value),
    );
  }
}

String _$glideCoachEvaluatorHash() =>
    r'e77d3eafbc0e1793f0e46d91190f16a08f24f140';
