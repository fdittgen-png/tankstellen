// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effective_approach_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The [ApproachState] the UI should render — simulator override
/// wins over the real detector (#2163).
///
/// Returns:
/// - the simulator's value when non-null (debug "Test approach
///   overlay" button is active), or
/// - the latest value from [approachStateProvider], or
/// - `null` when the real stream has not produced a value yet
///   (e.g. no trip recording — the real stream emits [ApproachIdle]
///   in that case, which the PiP treats as "show the default layout").

@ProviderFor(effectiveApproachState)
final effectiveApproachStateProvider = EffectiveApproachStateProvider._();

/// The [ApproachState] the UI should render — simulator override
/// wins over the real detector (#2163).
///
/// Returns:
/// - the simulator's value when non-null (debug "Test approach
///   overlay" button is active), or
/// - the latest value from [approachStateProvider], or
/// - `null` when the real stream has not produced a value yet
///   (e.g. no trip recording — the real stream emits [ApproachIdle]
///   in that case, which the PiP treats as "show the default layout").

final class EffectiveApproachStateProvider
    extends $FunctionalProvider<ApproachState?, ApproachState?, ApproachState?>
    with $Provider<ApproachState?> {
  /// The [ApproachState] the UI should render — simulator override
  /// wins over the real detector (#2163).
  ///
  /// Returns:
  /// - the simulator's value when non-null (debug "Test approach
  ///   overlay" button is active), or
  /// - the latest value from [approachStateProvider], or
  /// - `null` when the real stream has not produced a value yet
  ///   (e.g. no trip recording — the real stream emits [ApproachIdle]
  ///   in that case, which the PiP treats as "show the default layout").
  EffectiveApproachStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveApproachStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveApproachStateHash();

  @$internal
  @override
  $ProviderElement<ApproachState?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApproachState? create(Ref ref) {
    return effectiveApproachState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApproachState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApproachState?>(value),
    );
  }
}

String _$effectiveApproachStateHash() =>
    r'760686bcc787f3ed8950a09e23842bb393b2d8d1';
