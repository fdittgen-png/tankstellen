import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/obd2/android_background_adapter_listener.dart';
import '../data/obd2/auto_trip_coordinator.dart';
import '../data/obd2/background_adapter_listener.dart';
import 'trip_recording_provider.dart';

part 'auto_record_orchestrator.g.dart';

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
@Riverpod(keepAlive: true)
class AutoRecordOrchestrator extends _$AutoRecordOrchestrator {
  /// Active coordinators keyed by vehicle id. Read by tests through
  /// [activeVehicleIdsForTest]; production callers do not interact
  /// directly.
  final Map<String, _OrchestratorEntry> _entries =
      <String, _OrchestratorEntry>{};

  @override
  void build() {
    // ref.listen fires on every change to the vehicle list, including
    // the synthetic initial fire when this provider is first read. We
    // route both the initial fire and subsequent updates through the
    // same diff so the production wiring (added in app_initializer)
    // can `ref.read(autoRecordOrchestratorProvider)` once and then
    // forget about it.
    ref.listen<List<VehicleProfile>>(
      vehicleProfileListProvider,
      (prev, next) => _onVehicleListChanged(next),
      fireImmediately: true,
    );
    ref.onDispose(_disposeAll);
  }

  /// Test seam — returns the set of vehicle ids that currently have
  /// an active coordinator. Lets unit tests assert add/remove behaviour
  /// without poking private state directly.
  @visibleForTesting
  Set<String> get activeVehicleIdsForTest => _entries.keys.toSet();

  /// Test seam — returns the MAC the coordinator for [vehicleId] is
  /// armed against, or `null` when no coordinator is active for that
  /// vehicle. Used by the "MAC change re-arms" test.
  @visibleForTesting
  String? armedMacForTest(String vehicleId) =>
      _entries[vehicleId]?.coordinator.config.mac;

  void _onVehicleListChanged(List<VehicleProfile> profiles) {
    final Map<String, VehicleProfile> wanted = <String, VehicleProfile>{};
    for (final p in profiles) {
      if (_isAutoRecordReady(p)) {
        wanted[p.id] = p;
      }
    }

    // Remove entries for vehicles that disappeared, flipped autoRecord
    // off, or lost their paired MAC. Done first so a MAC-change
    // (treated below as remove + add) cannot accidentally orphan two
    // coordinators on the same vehicle id.
    final List<String> toRemove = <String>[];
    for (final entry in _entries.entries) {
      final wantedProfile = wanted[entry.key];
      if (wantedProfile == null) {
        toRemove.add(entry.key);
      } else if (wantedProfile.pairedAdapterMac != entry.value.armedMac) {
        // MAC changed — drop and let the add loop spin up a fresh
        // coordinator below.
        toRemove.add(entry.key);
      }
    }
    for (final id in toRemove) {
      final removed = _entries.remove(id);
      if (removed != null) {
        unawaited(_stopAndDispose(removed));
      }
    }

    // Add coordinators for vehicles that newly satisfy the gate (or
    // whose MAC just changed and were dropped above).
    for (final p in wanted.values) {
      if (_entries.containsKey(p.id)) continue;
      final entry = _buildEntry(p);
      if (entry == null) continue;
      _entries[p.id] = entry;
      unawaited(_startEntry(entry));
    }
  }

  bool _isAutoRecordReady(VehicleProfile p) {
    if (!p.autoRecord) return false;
    final mac = p.pairedAdapterMac;
    if (mac == null || mac.isEmpty) return false;
    return true;
  }

  _OrchestratorEntry? _buildEntry(VehicleProfile profile) {
    final mac = profile.pairedAdapterMac;
    if (mac == null || mac.isEmpty) return null;

    final listenerFactory = ref.read(autoRecordListenerFactoryProvider);
    final speedStreamFactory = ref.read(autoRecordSpeedStreamFactoryProvider);

    final listener = listenerFactory();
    final coordinator = AutoTripCoordinator(
      listener: listener,
      startTrip: () async {
        // The coordinator is decoupled from `StartTripOutcome` (it
        // lives in the providers layer). Forwarding the typed enum
        // back lets the coordinator distinguish "actually started"
        // from "alreadyActive" / "needsPicker" via its existing
        // string-form classifier.
        return ref
            .read(tripRecordingProvider.notifier)
            .startTrip(vehicleId: profile.id, adapterMac: mac);
      },
      stopAndSaveAutomatic: () async {
        await ref.read(tripRecordingProvider.notifier).stopAndSaveAutomatic();
      },
      speedStream: speedStreamFactory(),
      config: _configFor(profile, mac),
    );
    return _OrchestratorEntry(
      coordinator: coordinator,
      armedMac: mac,
    );
  }

  AutoRecordConfig _configFor(VehicleProfile profile, String mac) {
    return AutoRecordConfig(
      mac: mac,
      movementStartThresholdKmh: profile.movementStartThresholdKmh,
      disconnectSaveDelay: Duration(seconds: profile.disconnectSaveDelaySec),
    );
  }

  Future<void> _startEntry(_OrchestratorEntry entry) async {
    try {
      await entry.coordinator.start();
    } catch (e, st) {
      // The coordinator already routes its own start failure through
      // errorLogger + AutoRecordTraceLog; the orchestrator's own
      // try/catch is a belt-and-braces guard so a bug in the listener
      // factory doesn't crash the Riverpod build phase.
      debugPrint(
        'AutoRecordOrchestrator: coordinator start failed '
        '(mac=${entry.armedMac}): $e\n$st',
      );
    }
  }

  Future<void> _stopAndDispose(_OrchestratorEntry entry) async {
    try {
      await entry.coordinator.stop();
    } catch (e, st) {
      debugPrint(
        'AutoRecordOrchestrator: coordinator stop failed '
        '(mac=${entry.armedMac}): $e\n$st',
      );
    }
  }

  Future<void> _disposeAll() async {
    final futures = _entries.values.map(_stopAndDispose).toList();
    _entries.clear();
    await Future.wait<void>(futures);
  }
}

/// Bundle of a coordinator and the MAC it was armed against. Lets the
/// orchestrator detect a `pairedAdapterMac` change cheaply — the
/// `coordinator.config.mac` getter would also work, but caching here
/// keeps the diff loop O(1) per vehicle without reaching through
/// foreign objects.
class _OrchestratorEntry {
  final AutoTripCoordinator coordinator;
  final String armedMac;

  _OrchestratorEntry({
    required this.coordinator,
    required this.armedMac,
  });
}

/// Factory that returns a fresh [BackgroundAdapterListener] per
/// coordinator. Each coordinator owns its own listener so a MAC change
/// (drop + recreate) cannot leak the previous listener's
/// `MethodChannel.start` into the new arm.
typedef BackgroundAdapterListenerFactory = BackgroundAdapterListener
    Function();

/// Default factory: Android in production, an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.
@Riverpod(keepAlive: true)
BackgroundAdapterListenerFactory autoRecordListenerFactory(Ref ref) {
  return () {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidBackgroundAdapterListener();
    }
    return const UnimplementedBackgroundAdapterListener();
  };
}

/// Factory that returns a fresh GPS speed stream (km/h) per coordinator.
///
/// Phase 2b-2 starter — wraps [Geolocator.getPositionStream] and maps
/// `position.speed` (m/s) to km/h. Tests override this provider with a
/// controlled stream so the coordinator's threshold logic is exercised
/// without touching the platform's location stack.
typedef SpeedStreamFactory = Stream<double> Function();

@Riverpod(keepAlive: true)
SpeedStreamFactory autoRecordSpeedStreamFactory(Ref ref) {
  return () {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).map((position) => position.speed * 3.6);
  };
}
