// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_record_orchestrator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Production wiring for the hands-free auto-record flow (#1004 phase 2b-2).
///
/// Sits between [vehicleProfileListProvider] and the per-vehicle
/// [AutoTripCoordinator]: watches the vehicle list for changes and
/// keeps a long-lived coordinator alive for every profile that has
/// `autoRecord: true` AND a non-null `pairedAdapterMac`. The
/// coordinator(s) in turn observe the native Android foreground service
/// (phase 2b-1) and bridge into [TripRecording] when movement is
/// detected.
///
/// ## Lifecycle invariants
///
/// 1. A vehicle that flips `autoRecord: false` (or removes its paired
///    MAC) gets its coordinator stopped and disposed.
/// 2. A vehicle that changes its `pairedAdapterMac` gets the old
///    coordinator stopped and a new one started for the new MAC — the
///    foreground service watches a single MAC at a time on the Kotlin
///    side, so re-arming is the only way to switch.
/// 3. Two vehicles can be tracked independently. Each gets its own
///    coordinator, its own foreground-service arm, and its own
///    disconnect-save timer.
/// 4. On orchestrator dispose (e.g. test teardown), every active
///    coordinator is stopped.
///
/// ## Listener selection
///
/// The orchestrator selects the [BackgroundAdapterListener] implementation
/// per platform:
///
/// * Android → [AndroidBackgroundAdapterListener] (production bridge).
/// * Anything else → [UnimplementedBackgroundAdapterListener] (throws
///   on first event read; the orchestrator only constructs it when
///   [defaultTargetPlatform] is non-Android, keeping iOS / desktop
///   builds compiling without a runtime arming).
///
/// Tests override [_listenerFactory] via
/// [autoRecordListenerFactoryProvider] to inject a
/// [FakeBackgroundAdapterListener]; the same hook lets a future
/// platform implementation slot in without touching this file.
///
/// ## Speed-stream source
///
/// Phase 2b-2 ships GPS-only: each coordinator wraps
/// [Geolocator.getPositionStream] and converts m/s → km/h. This is
/// intentional — opening an OBD2 session inline (PID 0x0D) on every
/// `AdapterConnected` event would conflict with the manual flow's
/// existing `Obd2ConnectionService.takeover` semantics. Phase 2b-3 will
/// switch to OBD2 PID 0x0D once the on-connect session-handoff design
/// is settled. The GPS source is good enough to detect "the car
/// started moving"; we are not measuring instantaneous speed for
/// telemetry here.

@ProviderFor(AutoRecordOrchestrator)
final autoRecordOrchestratorProvider = AutoRecordOrchestratorProvider._();

/// Production wiring for the hands-free auto-record flow (#1004 phase 2b-2).
///
/// Sits between [vehicleProfileListProvider] and the per-vehicle
/// [AutoTripCoordinator]: watches the vehicle list for changes and
/// keeps a long-lived coordinator alive for every profile that has
/// `autoRecord: true` AND a non-null `pairedAdapterMac`. The
/// coordinator(s) in turn observe the native Android foreground service
/// (phase 2b-1) and bridge into [TripRecording] when movement is
/// detected.
///
/// ## Lifecycle invariants
///
/// 1. A vehicle that flips `autoRecord: false` (or removes its paired
///    MAC) gets its coordinator stopped and disposed.
/// 2. A vehicle that changes its `pairedAdapterMac` gets the old
///    coordinator stopped and a new one started for the new MAC — the
///    foreground service watches a single MAC at a time on the Kotlin
///    side, so re-arming is the only way to switch.
/// 3. Two vehicles can be tracked independently. Each gets its own
///    coordinator, its own foreground-service arm, and its own
///    disconnect-save timer.
/// 4. On orchestrator dispose (e.g. test teardown), every active
///    coordinator is stopped.
///
/// ## Listener selection
///
/// The orchestrator selects the [BackgroundAdapterListener] implementation
/// per platform:
///
/// * Android → [AndroidBackgroundAdapterListener] (production bridge).
/// * Anything else → [UnimplementedBackgroundAdapterListener] (throws
///   on first event read; the orchestrator only constructs it when
///   [defaultTargetPlatform] is non-Android, keeping iOS / desktop
///   builds compiling without a runtime arming).
///
/// Tests override [_listenerFactory] via
/// [autoRecordListenerFactoryProvider] to inject a
/// [FakeBackgroundAdapterListener]; the same hook lets a future
/// platform implementation slot in without touching this file.
///
/// ## Speed-stream source
///
/// Phase 2b-2 ships GPS-only: each coordinator wraps
/// [Geolocator.getPositionStream] and converts m/s → km/h. This is
/// intentional — opening an OBD2 session inline (PID 0x0D) on every
/// `AdapterConnected` event would conflict with the manual flow's
/// existing `Obd2ConnectionService.takeover` semantics. Phase 2b-3 will
/// switch to OBD2 PID 0x0D once the on-connect session-handoff design
/// is settled. The GPS source is good enough to detect "the car
/// started moving"; we are not measuring instantaneous speed for
/// telemetry here.
final class AutoRecordOrchestratorProvider
    extends $NotifierProvider<AutoRecordOrchestrator, void> {
  /// Production wiring for the hands-free auto-record flow (#1004 phase 2b-2).
  ///
  /// Sits between [vehicleProfileListProvider] and the per-vehicle
  /// [AutoTripCoordinator]: watches the vehicle list for changes and
  /// keeps a long-lived coordinator alive for every profile that has
  /// `autoRecord: true` AND a non-null `pairedAdapterMac`. The
  /// coordinator(s) in turn observe the native Android foreground service
  /// (phase 2b-1) and bridge into [TripRecording] when movement is
  /// detected.
  ///
  /// ## Lifecycle invariants
  ///
  /// 1. A vehicle that flips `autoRecord: false` (or removes its paired
  ///    MAC) gets its coordinator stopped and disposed.
  /// 2. A vehicle that changes its `pairedAdapterMac` gets the old
  ///    coordinator stopped and a new one started for the new MAC — the
  ///    foreground service watches a single MAC at a time on the Kotlin
  ///    side, so re-arming is the only way to switch.
  /// 3. Two vehicles can be tracked independently. Each gets its own
  ///    coordinator, its own foreground-service arm, and its own
  ///    disconnect-save timer.
  /// 4. On orchestrator dispose (e.g. test teardown), every active
  ///    coordinator is stopped.
  ///
  /// ## Listener selection
  ///
  /// The orchestrator selects the [BackgroundAdapterListener] implementation
  /// per platform:
  ///
  /// * Android → [AndroidBackgroundAdapterListener] (production bridge).
  /// * Anything else → [UnimplementedBackgroundAdapterListener] (throws
  ///   on first event read; the orchestrator only constructs it when
  ///   [defaultTargetPlatform] is non-Android, keeping iOS / desktop
  ///   builds compiling without a runtime arming).
  ///
  /// Tests override [_listenerFactory] via
  /// [autoRecordListenerFactoryProvider] to inject a
  /// [FakeBackgroundAdapterListener]; the same hook lets a future
  /// platform implementation slot in without touching this file.
  ///
  /// ## Speed-stream source
  ///
  /// Phase 2b-2 ships GPS-only: each coordinator wraps
  /// [Geolocator.getPositionStream] and converts m/s → km/h. This is
  /// intentional — opening an OBD2 session inline (PID 0x0D) on every
  /// `AdapterConnected` event would conflict with the manual flow's
  /// existing `Obd2ConnectionService.takeover` semantics. Phase 2b-3 will
  /// switch to OBD2 PID 0x0D once the on-connect session-handoff design
  /// is settled. The GPS source is good enough to detect "the car
  /// started moving"; we are not measuring instantaneous speed for
  /// telemetry here.
  AutoRecordOrchestratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordOrchestratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordOrchestratorHash();

  @$internal
  @override
  AutoRecordOrchestrator create() => AutoRecordOrchestrator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$autoRecordOrchestratorHash() =>
    r'9d2c1df4b54a3c7f408be77fe74891266f82f18e';

/// Production wiring for the hands-free auto-record flow (#1004 phase 2b-2).
///
/// Sits between [vehicleProfileListProvider] and the per-vehicle
/// [AutoTripCoordinator]: watches the vehicle list for changes and
/// keeps a long-lived coordinator alive for every profile that has
/// `autoRecord: true` AND a non-null `pairedAdapterMac`. The
/// coordinator(s) in turn observe the native Android foreground service
/// (phase 2b-1) and bridge into [TripRecording] when movement is
/// detected.
///
/// ## Lifecycle invariants
///
/// 1. A vehicle that flips `autoRecord: false` (or removes its paired
///    MAC) gets its coordinator stopped and disposed.
/// 2. A vehicle that changes its `pairedAdapterMac` gets the old
///    coordinator stopped and a new one started for the new MAC — the
///    foreground service watches a single MAC at a time on the Kotlin
///    side, so re-arming is the only way to switch.
/// 3. Two vehicles can be tracked independently. Each gets its own
///    coordinator, its own foreground-service arm, and its own
///    disconnect-save timer.
/// 4. On orchestrator dispose (e.g. test teardown), every active
///    coordinator is stopped.
///
/// ## Listener selection
///
/// The orchestrator selects the [BackgroundAdapterListener] implementation
/// per platform:
///
/// * Android → [AndroidBackgroundAdapterListener] (production bridge).
/// * Anything else → [UnimplementedBackgroundAdapterListener] (throws
///   on first event read; the orchestrator only constructs it when
///   [defaultTargetPlatform] is non-Android, keeping iOS / desktop
///   builds compiling without a runtime arming).
///
/// Tests override [_listenerFactory] via
/// [autoRecordListenerFactoryProvider] to inject a
/// [FakeBackgroundAdapterListener]; the same hook lets a future
/// platform implementation slot in without touching this file.
///
/// ## Speed-stream source
///
/// Phase 2b-2 ships GPS-only: each coordinator wraps
/// [Geolocator.getPositionStream] and converts m/s → km/h. This is
/// intentional — opening an OBD2 session inline (PID 0x0D) on every
/// `AdapterConnected` event would conflict with the manual flow's
/// existing `Obd2ConnectionService.takeover` semantics. Phase 2b-3 will
/// switch to OBD2 PID 0x0D once the on-connect session-handoff design
/// is settled. The GPS source is good enough to detect "the car
/// started moving"; we are not measuring instantaneous speed for
/// telemetry here.

abstract class _$AutoRecordOrchestrator extends $Notifier<void> {
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

/// Default factory: Android in production, an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.

@ProviderFor(autoRecordListenerFactory)
final autoRecordListenerFactoryProvider = AutoRecordListenerFactoryProvider._();

/// Default factory: Android in production, an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.

final class AutoRecordListenerFactoryProvider
    extends
        $FunctionalProvider<
          BackgroundAdapterListenerFactory,
          BackgroundAdapterListenerFactory,
          BackgroundAdapterListenerFactory
        >
    with $Provider<BackgroundAdapterListenerFactory> {
  /// Default factory: Android in production, an unimplemented stub
  /// elsewhere. Tests override this provider to inject a
  /// [FakeBackgroundAdapterListener] without touching platform-detection
  /// code.
  AutoRecordListenerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordListenerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordListenerFactoryHash();

  @$internal
  @override
  $ProviderElement<BackgroundAdapterListenerFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundAdapterListenerFactory create(Ref ref) {
    return autoRecordListenerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundAdapterListenerFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundAdapterListenerFactory>(
        value,
      ),
    );
  }
}

String _$autoRecordListenerFactoryHash() =>
    r'3ac9db8a2ce1a0919d0fb75fc9b9906b736d40af';

@ProviderFor(autoRecordSpeedStreamFactory)
final autoRecordSpeedStreamFactoryProvider =
    AutoRecordSpeedStreamFactoryProvider._();

final class AutoRecordSpeedStreamFactoryProvider
    extends
        $FunctionalProvider<
          SpeedStreamFactory,
          SpeedStreamFactory,
          SpeedStreamFactory
        >
    with $Provider<SpeedStreamFactory> {
  AutoRecordSpeedStreamFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordSpeedStreamFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordSpeedStreamFactoryHash();

  @$internal
  @override
  $ProviderElement<SpeedStreamFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SpeedStreamFactory create(Ref ref) {
    return autoRecordSpeedStreamFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeedStreamFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeedStreamFactory>(value),
    );
  }
}

String _$autoRecordSpeedStreamFactoryHash() =>
    r'b829693bb5405b843f8cff4d2fc2b81ee065d24e';
