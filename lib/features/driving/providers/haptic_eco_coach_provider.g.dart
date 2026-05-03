// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'haptic_eco_coach_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted opt-in switch for the real-time eco-coaching haptic
/// (#1122). As of #1373 phase 3a this is a thin shim over
/// [featureFlagsProvider] — the canonical state lives in the central
/// feature-flag set keyed by [Feature.hapticEcoCoach]. The legacy
/// [StorageKeys.hapticEcoCoachEnabled] key is read once by the
/// `legacyToggleMigrationProvider` on first launch after upgrade and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// Lives for the app's lifetime — flipping the toggle invalidates
/// [hapticEcoCoachLifecycleProvider] so the subscription is torn down
/// or spun up immediately.

@ProviderFor(HapticEcoCoachEnabled)
final hapticEcoCoachEnabledProvider = HapticEcoCoachEnabledProvider._();

/// Persisted opt-in switch for the real-time eco-coaching haptic
/// (#1122). As of #1373 phase 3a this is a thin shim over
/// [featureFlagsProvider] — the canonical state lives in the central
/// feature-flag set keyed by [Feature.hapticEcoCoach]. The legacy
/// [StorageKeys.hapticEcoCoachEnabled] key is read once by the
/// `legacyToggleMigrationProvider` on first launch after upgrade and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// Lives for the app's lifetime — flipping the toggle invalidates
/// [hapticEcoCoachLifecycleProvider] so the subscription is torn down
/// or spun up immediately.
final class HapticEcoCoachEnabledProvider
    extends $NotifierProvider<HapticEcoCoachEnabled, bool> {
  /// Persisted opt-in switch for the real-time eco-coaching haptic
  /// (#1122). As of #1373 phase 3a this is a thin shim over
  /// [featureFlagsProvider] — the canonical state lives in the central
  /// feature-flag set keyed by [Feature.hapticEcoCoach]. The legacy
  /// [StorageKeys.hapticEcoCoachEnabled] key is read once by the
  /// `legacyToggleMigrationProvider` on first launch after upgrade and
  /// promoted into the central set; subsequent reads/writes go through
  /// here.
  ///
  /// Lives for the app's lifetime — flipping the toggle invalidates
  /// [hapticEcoCoachLifecycleProvider] so the subscription is torn down
  /// or spun up immediately.
  HapticEcoCoachEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hapticEcoCoachEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hapticEcoCoachEnabledHash();

  @$internal
  @override
  HapticEcoCoachEnabled create() => HapticEcoCoachEnabled();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hapticEcoCoachEnabledHash() =>
    r'3096c59d7861ed73c242e1925c49efe3e7f03ad8';

/// Persisted opt-in switch for the real-time eco-coaching haptic
/// (#1122). As of #1373 phase 3a this is a thin shim over
/// [featureFlagsProvider] — the canonical state lives in the central
/// feature-flag set keyed by [Feature.hapticEcoCoach]. The legacy
/// [StorageKeys.hapticEcoCoachEnabled] key is read once by the
/// `legacyToggleMigrationProvider` on first launch after upgrade and
/// promoted into the central set; subsequent reads/writes go through
/// here.
///
/// Lives for the app's lifetime — flipping the toggle invalidates
/// [hapticEcoCoachLifecycleProvider] so the subscription is torn down
/// or spun up immediately.

abstract class _$HapticEcoCoachEnabled extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Active subscription that bridges the trip-recording state stream
/// to a [HapticEcoCoach]. Held by Riverpod for the duration of an
/// active trip with the eco-coach setting enabled; cancelled when
/// either condition flips.
///
/// Implementation detail: the trip-recording provider exposes its
/// live readings only through its [TripRecordingState.live] field
/// (no public `Stream<TripLiveReading>` getter). We bridge that
/// state-change shape into a stream by feeding readings into a local
/// [StreamController], then hand the controller's stream to
/// [HapticEcoCoach]. This keeps the coach service stream-agnostic
/// (it can still be exercised in tests with a synthetic stream)
/// while avoiding any modification to the trip-recording controller's
/// public API.
///
/// `keepAlive: true` because we need it to survive widget rebuilds
/// while the user navigates around the app mid-trip — the trip
/// itself is `keepAlive`, so the haptic coach must be too.

@ProviderFor(HapticEcoCoachLifecycle)
final hapticEcoCoachLifecycleProvider = HapticEcoCoachLifecycleProvider._();

/// Active subscription that bridges the trip-recording state stream
/// to a [HapticEcoCoach]. Held by Riverpod for the duration of an
/// active trip with the eco-coach setting enabled; cancelled when
/// either condition flips.
///
/// Implementation detail: the trip-recording provider exposes its
/// live readings only through its [TripRecordingState.live] field
/// (no public `Stream<TripLiveReading>` getter). We bridge that
/// state-change shape into a stream by feeding readings into a local
/// [StreamController], then hand the controller's stream to
/// [HapticEcoCoach]. This keeps the coach service stream-agnostic
/// (it can still be exercised in tests with a synthetic stream)
/// while avoiding any modification to the trip-recording controller's
/// public API.
///
/// `keepAlive: true` because we need it to survive widget rebuilds
/// while the user navigates around the app mid-trip — the trip
/// itself is `keepAlive`, so the haptic coach must be too.
final class HapticEcoCoachLifecycleProvider
    extends $NotifierProvider<HapticEcoCoachLifecycle, void> {
  /// Active subscription that bridges the trip-recording state stream
  /// to a [HapticEcoCoach]. Held by Riverpod for the duration of an
  /// active trip with the eco-coach setting enabled; cancelled when
  /// either condition flips.
  ///
  /// Implementation detail: the trip-recording provider exposes its
  /// live readings only through its [TripRecordingState.live] field
  /// (no public `Stream<TripLiveReading>` getter). We bridge that
  /// state-change shape into a stream by feeding readings into a local
  /// [StreamController], then hand the controller's stream to
  /// [HapticEcoCoach]. This keeps the coach service stream-agnostic
  /// (it can still be exercised in tests with a synthetic stream)
  /// while avoiding any modification to the trip-recording controller's
  /// public API.
  ///
  /// `keepAlive: true` because we need it to survive widget rebuilds
  /// while the user navigates around the app mid-trip — the trip
  /// itself is `keepAlive`, so the haptic coach must be too.
  HapticEcoCoachLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hapticEcoCoachLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hapticEcoCoachLifecycleHash();

  @$internal
  @override
  HapticEcoCoachLifecycle create() => HapticEcoCoachLifecycle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$hapticEcoCoachLifecycleHash() =>
    r'71655a3b166a44fe287914f68cab58f66aad70fd';

/// Active subscription that bridges the trip-recording state stream
/// to a [HapticEcoCoach]. Held by Riverpod for the duration of an
/// active trip with the eco-coach setting enabled; cancelled when
/// either condition flips.
///
/// Implementation detail: the trip-recording provider exposes its
/// live readings only through its [TripRecordingState.live] field
/// (no public `Stream<TripLiveReading>` getter). We bridge that
/// state-change shape into a stream by feeding readings into a local
/// [StreamController], then hand the controller's stream to
/// [HapticEcoCoach]. This keeps the coach service stream-agnostic
/// (it can still be exercised in tests with a synthetic stream)
/// while avoiding any modification to the trip-recording controller's
/// public API.
///
/// `keepAlive: true` because we need it to survive widget rebuilds
/// while the user navigates around the app mid-trip — the trip
/// itself is `keepAlive`, so the haptic coach must be too.

abstract class _$HapticEcoCoachLifecycle extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
