// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_record_orchestrator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Production wiring for the hands-free auto-record flow (#1004 phase 2b-3).
///
/// Sits between [vehicleProfileListProvider] and the per-vehicle
/// [AutoTripCoordinator]: watches the vehicle list for changes and
/// keeps a long-lived coordinator alive for every profile that has
/// `autoRecord: true` AND a non-null `obd2AdapterMac`. The
/// coordinator(s) in turn observe the native Android foreground service
/// (phase 2b-1), open an OBD2 session on `AdapterConnected` (phase
/// 2b-3), poll PID 0x0D for speed, and hand the live session to
/// [TripRecording.start] when movement is detected — closing the loop
/// the phase 2b-2 GPS source had left as a `needsPicker` outcome.
///
/// ## Lifecycle invariants
///
/// 1. A vehicle that flips `autoRecord: false` (or removes its paired
///    MAC) gets its coordinator stopped and disposed.
/// 2. A vehicle that changes its `obd2AdapterMac` gets the old
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
/// ## Speed-stream source (#1004 phase 2b-3)
///
/// Each coordinator opens an [Obd2Service] on `AdapterConnected` via
/// [autoRecordSessionOpenerFactoryProvider], wraps it in an
/// `Obd2SpeedStream` that polls PID 0x0D at 1 Hz, and hands ownership
/// of the live session to [TripRecording.start] on threshold-cross.
/// Tests override the factory provider to inject a fake opener that
/// returns a stub service whose `readSpeedKmh()` is wired to a
/// pre-defined queue.

@ProviderFor(AutoRecordOrchestrator)
final autoRecordOrchestratorProvider = AutoRecordOrchestratorProvider._();

/// Production wiring for the hands-free auto-record flow (#1004 phase 2b-3).
///
/// Sits between [vehicleProfileListProvider] and the per-vehicle
/// [AutoTripCoordinator]: watches the vehicle list for changes and
/// keeps a long-lived coordinator alive for every profile that has
/// `autoRecord: true` AND a non-null `obd2AdapterMac`. The
/// coordinator(s) in turn observe the native Android foreground service
/// (phase 2b-1), open an OBD2 session on `AdapterConnected` (phase
/// 2b-3), poll PID 0x0D for speed, and hand the live session to
/// [TripRecording.start] when movement is detected — closing the loop
/// the phase 2b-2 GPS source had left as a `needsPicker` outcome.
///
/// ## Lifecycle invariants
///
/// 1. A vehicle that flips `autoRecord: false` (or removes its paired
///    MAC) gets its coordinator stopped and disposed.
/// 2. A vehicle that changes its `obd2AdapterMac` gets the old
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
/// ## Speed-stream source (#1004 phase 2b-3)
///
/// Each coordinator opens an [Obd2Service] on `AdapterConnected` via
/// [autoRecordSessionOpenerFactoryProvider], wraps it in an
/// `Obd2SpeedStream` that polls PID 0x0D at 1 Hz, and hands ownership
/// of the live session to [TripRecording.start] on threshold-cross.
/// Tests override the factory provider to inject a fake opener that
/// returns a stub service whose `readSpeedKmh()` is wired to a
/// pre-defined queue.
final class AutoRecordOrchestratorProvider
    extends $NotifierProvider<AutoRecordOrchestrator, void> {
  /// Production wiring for the hands-free auto-record flow (#1004 phase 2b-3).
  ///
  /// Sits between [vehicleProfileListProvider] and the per-vehicle
  /// [AutoTripCoordinator]: watches the vehicle list for changes and
  /// keeps a long-lived coordinator alive for every profile that has
  /// `autoRecord: true` AND a non-null `obd2AdapterMac`. The
  /// coordinator(s) in turn observe the native Android foreground service
  /// (phase 2b-1), open an OBD2 session on `AdapterConnected` (phase
  /// 2b-3), poll PID 0x0D for speed, and hand the live session to
  /// [TripRecording.start] when movement is detected — closing the loop
  /// the phase 2b-2 GPS source had left as a `needsPicker` outcome.
  ///
  /// ## Lifecycle invariants
  ///
  /// 1. A vehicle that flips `autoRecord: false` (or removes its paired
  ///    MAC) gets its coordinator stopped and disposed.
  /// 2. A vehicle that changes its `obd2AdapterMac` gets the old
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
  /// ## Speed-stream source (#1004 phase 2b-3)
  ///
  /// Each coordinator opens an [Obd2Service] on `AdapterConnected` via
  /// [autoRecordSessionOpenerFactoryProvider], wraps it in an
  /// `Obd2SpeedStream` that polls PID 0x0D at 1 Hz, and hands ownership
  /// of the live session to [TripRecording.start] on threshold-cross.
  /// Tests override the factory provider to inject a fake opener that
  /// returns a stub service whose `readSpeedKmh()` is wired to a
  /// pre-defined queue.
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
    r'1581f8e5abc60c42ec44e848fbeca832cc9ca626';

/// Production wiring for the hands-free auto-record flow (#1004 phase 2b-3).
///
/// Sits between [vehicleProfileListProvider] and the per-vehicle
/// [AutoTripCoordinator]: watches the vehicle list for changes and
/// keeps a long-lived coordinator alive for every profile that has
/// `autoRecord: true` AND a non-null `obd2AdapterMac`. The
/// coordinator(s) in turn observe the native Android foreground service
/// (phase 2b-1), open an OBD2 session on `AdapterConnected` (phase
/// 2b-3), poll PID 0x0D for speed, and hand the live session to
/// [TripRecording.start] when movement is detected — closing the loop
/// the phase 2b-2 GPS source had left as a `needsPicker` outcome.
///
/// ## Lifecycle invariants
///
/// 1. A vehicle that flips `autoRecord: false` (or removes its paired
///    MAC) gets its coordinator stopped and disposed.
/// 2. A vehicle that changes its `obd2AdapterMac` gets the old
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
/// ## Speed-stream source (#1004 phase 2b-3)
///
/// Each coordinator opens an [Obd2Service] on `AdapterConnected` via
/// [autoRecordSessionOpenerFactoryProvider], wraps it in an
/// `Obd2SpeedStream` that polls PID 0x0D at 1 Hz, and hands ownership
/// of the live session to [TripRecording.start] on threshold-cross.
/// Tests override the factory provider to inject a fake opener that
/// returns a stub service whose `readSpeedKmh()` is wired to a
/// pre-defined queue.

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
