// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calibration_mode_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fuzzy classifier provider. Pure, stateless — kept behind a
/// Riverpod provider so tests can `override` it with a spy if they
/// want to assert classification was invoked.

@ProviderFor(fuzzyClassifier)
final fuzzyClassifierProvider = FuzzyClassifierProvider._();

/// Fuzzy classifier provider. Pure, stateless — kept behind a
/// Riverpod provider so tests can `override` it with a spy if they
/// want to assert classification was invoked.

final class FuzzyClassifierProvider
    extends
        $FunctionalProvider<FuzzyClassifier, FuzzyClassifier, FuzzyClassifier>
    with $Provider<FuzzyClassifier> {
  /// Fuzzy classifier provider. Pure, stateless — kept behind a
  /// Riverpod provider so tests can `override` it with a spy if they
  /// want to assert classification was invoked.
  FuzzyClassifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fuzzyClassifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fuzzyClassifierHash();

  @$internal
  @override
  $ProviderElement<FuzzyClassifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FuzzyClassifier create(Ref ref) {
    return fuzzyClassifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FuzzyClassifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FuzzyClassifier>(value),
    );
  }
}

String _$fuzzyClassifierHash() => r'0e52a21e1e23cb1d13f91a9a87c7ba7992cb2146';

/// Turn [sample] into a list of Welford votes according to the
/// vehicle's current calibration mode.
///
/// * `rule` mode → one vote at weight 1.0 on whatever situation wins
///   by plain threshold logic — matches the legacy #779 behaviour.
/// * `fuzzy` mode → up to seven votes, one per situation, weights
///   summing to 1.0.
///
/// Calibration reserves the right to drop situations we don't
/// persist (the #779 store filters transients anyway).

@ProviderFor(calibrationVotes)
final calibrationVotesProvider = CalibrationVotesFamily._();

/// Turn [sample] into a list of Welford votes according to the
/// vehicle's current calibration mode.
///
/// * `rule` mode → one vote at weight 1.0 on whatever situation wins
///   by plain threshold logic — matches the legacy #779 behaviour.
/// * `fuzzy` mode → up to seven votes, one per situation, weights
///   summing to 1.0.
///
/// Calibration reserves the right to drop situations we don't
/// persist (the #779 store filters transients anyway).

final class CalibrationVotesProvider
    extends
        $FunctionalProvider<
          List<SituationVote>,
          List<SituationVote>,
          List<SituationVote>
        >
    with $Provider<List<SituationVote>> {
  /// Turn [sample] into a list of Welford votes according to the
  /// vehicle's current calibration mode.
  ///
  /// * `rule` mode → one vote at weight 1.0 on whatever situation wins
  ///   by plain threshold logic — matches the legacy #779 behaviour.
  /// * `fuzzy` mode → up to seven votes, one per situation, weights
  ///   summing to 1.0.
  ///
  /// Calibration reserves the right to drop situations we don't
  /// persist (the #779 store filters transients anyway).
  CalibrationVotesProvider._({
    required CalibrationVotesFamily super.from,
    required ({String vehicleId, CalibrationSample sample}) super.argument,
  }) : super(
         retry: null,
         name: r'calibrationVotesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calibrationVotesHash();

  @override
  String toString() {
    return r'calibrationVotesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<SituationVote>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SituationVote> create(Ref ref) {
    final argument =
        this.argument as ({String vehicleId, CalibrationSample sample});
    return calibrationVotes(
      ref,
      vehicleId: argument.vehicleId,
      sample: argument.sample,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SituationVote> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SituationVote>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalibrationVotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calibrationVotesHash() => r'2721bd36a6872ebd72c703fa0fc184a1e8377a7b';

/// Turn [sample] into a list of Welford votes according to the
/// vehicle's current calibration mode.
///
/// * `rule` mode → one vote at weight 1.0 on whatever situation wins
///   by plain threshold logic — matches the legacy #779 behaviour.
/// * `fuzzy` mode → up to seven votes, one per situation, weights
///   summing to 1.0.
///
/// Calibration reserves the right to drop situations we don't
/// persist (the #779 store filters transients anyway).

final class CalibrationVotesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          List<SituationVote>,
          ({String vehicleId, CalibrationSample sample})
        > {
  CalibrationVotesFamily._()
    : super(
        retry: null,
        name: r'calibrationVotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Turn [sample] into a list of Welford votes according to the
  /// vehicle's current calibration mode.
  ///
  /// * `rule` mode → one vote at weight 1.0 on whatever situation wins
  ///   by plain threshold logic — matches the legacy #779 behaviour.
  /// * `fuzzy` mode → up to seven votes, one per situation, weights
  ///   summing to 1.0.
  ///
  /// Calibration reserves the right to drop situations we don't
  /// persist (the #779 store filters transients anyway).

  CalibrationVotesProvider call({
    required String vehicleId,
    required CalibrationSample sample,
  }) => CalibrationVotesProvider._(
    argument: (vehicleId: vehicleId, sample: sample),
    from: this,
  );

  @override
  String toString() => r'calibrationVotesProvider';
}

/// Replay state for "what happens when the user flips the
/// calibration mode" — the UI kicks this, the test asserts on it.
///
/// We can't re-ingest a historical OBD2 trip from raw samples
/// (Tankstellen only persists Welford summaries, not per-tick
/// sample arrays) so "re-run on the last trip" means: trigger a
/// replay event. Consumers (e.g. a future trip-history replay
/// job) subscribe to the invalidation signal.

@ProviderFor(CalibrationReplayQueue)
final calibrationReplayQueueProvider = CalibrationReplayQueueProvider._();

/// Replay state for "what happens when the user flips the
/// calibration mode" — the UI kicks this, the test asserts on it.
///
/// We can't re-ingest a historical OBD2 trip from raw samples
/// (Tankstellen only persists Welford summaries, not per-tick
/// sample arrays) so "re-run on the last trip" means: trigger a
/// replay event. Consumers (e.g. a future trip-history replay
/// job) subscribe to the invalidation signal.
final class CalibrationReplayQueueProvider
    extends $NotifierProvider<CalibrationReplayQueue, List<String>> {
  /// Replay state for "what happens when the user flips the
  /// calibration mode" — the UI kicks this, the test asserts on it.
  ///
  /// We can't re-ingest a historical OBD2 trip from raw samples
  /// (Tankstellen only persists Welford summaries, not per-tick
  /// sample arrays) so "re-run on the last trip" means: trigger a
  /// replay event. Consumers (e.g. a future trip-history replay
  /// job) subscribe to the invalidation signal.
  CalibrationReplayQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calibrationReplayQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calibrationReplayQueueHash();

  @$internal
  @override
  CalibrationReplayQueue create() => CalibrationReplayQueue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$calibrationReplayQueueHash() =>
    r'ef22a0dc0c42b17a8073dd2948a637bea5fc82b8';

/// Replay state for "what happens when the user flips the
/// calibration mode" — the UI kicks this, the test asserts on it.
///
/// We can't re-ingest a historical OBD2 trip from raw samples
/// (Tankstellen only persists Welford summaries, not per-tick
/// sample arrays) so "re-run on the last trip" means: trigger a
/// replay event. Consumers (e.g. a future trip-history replay
/// job) subscribe to the invalidation signal.

abstract class _$CalibrationReplayQueue extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
