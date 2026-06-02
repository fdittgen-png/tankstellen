// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_swipe_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the swipe-to-page distance index for the trip-recording radar
/// card (#2661).
///
/// `keepAlive` so the index survives the card rebuilding on every
/// approach-state / candidate-list tick (otherwise an autoDispose notifier
/// would reset the moment the list re-runs). The index is reset to the
/// nearest station (0) when the trip stops so the next trip starts fresh —
/// there is no persistence across trajets.

@ProviderFor(RadarSwipe)
final radarSwipeProvider = RadarSwipeProvider._();

/// Holds the swipe-to-page distance index for the trip-recording radar
/// card (#2661).
///
/// `keepAlive` so the index survives the card rebuilding on every
/// approach-state / candidate-list tick (otherwise an autoDispose notifier
/// would reset the moment the list re-runs). The index is reset to the
/// nearest station (0) when the trip stops so the next trip starts fresh —
/// there is no persistence across trajets.
final class RadarSwipeProvider
    extends $NotifierProvider<RadarSwipe, RadarSwipeState> {
  /// Holds the swipe-to-page distance index for the trip-recording radar
  /// card (#2661).
  ///
  /// `keepAlive` so the index survives the card rebuilding on every
  /// approach-state / candidate-list tick (otherwise an autoDispose notifier
  /// would reset the moment the list re-runs). The index is reset to the
  /// nearest station (0) when the trip stops so the next trip starts fresh —
  /// there is no persistence across trajets.
  RadarSwipeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarSwipeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarSwipeHash();

  @$internal
  @override
  RadarSwipe create() => RadarSwipe();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RadarSwipeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RadarSwipeState>(value),
    );
  }
}

String _$radarSwipeHash() => r'cb4faaeccd379993e71fc60c52d5bb5371a65254';

/// Holds the swipe-to-page distance index for the trip-recording radar
/// card (#2661).
///
/// `keepAlive` so the index survives the card rebuilding on every
/// approach-state / candidate-list tick (otherwise an autoDispose notifier
/// would reset the moment the list re-runs). The index is reset to the
/// nearest station (0) when the trip stops so the next trip starts fresh —
/// there is no persistence across trajets.

abstract class _$RadarSwipe extends $Notifier<RadarSwipeState> {
  RadarSwipeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RadarSwipeState, RadarSwipeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RadarSwipeState, RadarSwipeState>,
              RadarSwipeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
