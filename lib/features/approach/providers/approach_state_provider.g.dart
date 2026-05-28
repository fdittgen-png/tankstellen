// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approach_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Real-data approach detector (#2163) — wires [ApproachDetector] to
/// the live trip-recording flow.
///
/// Active only while a trip is recording: cold-start cost (a GPS
/// subscription + periodic search-chain calls) is bounded to the
/// window where the user is actually driving. The detector is
/// recreated whenever the user edits their profile's approach config
/// or fuel type (per ADR 0011 — the detector itself does not watch
/// the profile).
///
/// The UI consumes [effectiveApproachStateProvider] rather than this
/// stream directly, so the in-app simulator (debug button on the
/// trip-recording screen) can override the real signal for testing.

@ProviderFor(approachState)
final approachStateProvider = ApproachStateProvider._();

/// Real-data approach detector (#2163) — wires [ApproachDetector] to
/// the live trip-recording flow.
///
/// Active only while a trip is recording: cold-start cost (a GPS
/// subscription + periodic search-chain calls) is bounded to the
/// window where the user is actually driving. The detector is
/// recreated whenever the user edits their profile's approach config
/// or fuel type (per ADR 0011 — the detector itself does not watch
/// the profile).
///
/// The UI consumes [effectiveApproachStateProvider] rather than this
/// stream directly, so the in-app simulator (debug button on the
/// trip-recording screen) can override the real signal for testing.

final class ApproachStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<ApproachState>,
          ApproachState,
          Stream<ApproachState>
        >
    with $FutureModifier<ApproachState>, $StreamProvider<ApproachState> {
  /// Real-data approach detector (#2163) — wires [ApproachDetector] to
  /// the live trip-recording flow.
  ///
  /// Active only while a trip is recording: cold-start cost (a GPS
  /// subscription + periodic search-chain calls) is bounded to the
  /// window where the user is actually driving. The detector is
  /// recreated whenever the user edits their profile's approach config
  /// or fuel type (per ADR 0011 — the detector itself does not watch
  /// the profile).
  ///
  /// The UI consumes [effectiveApproachStateProvider] rather than this
  /// stream directly, so the in-app simulator (debug button on the
  /// trip-recording screen) can override the real signal for testing.
  ApproachStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'approachStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$approachStateHash();

  @$internal
  @override
  $StreamProviderElement<ApproachState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ApproachState> create(Ref ref) {
    return approachState(ref);
  }
}

String _$approachStateHash() => r'6c117788e13447f359a6f518d7e33374b9a25c59';
