// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../feature_management/application/feature_flags_provider.dart';
import '../../feature_management/domain/feature.dart';
import '../../feature_management/domain/feature_dependency_graph.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../../obd2/api.dart';
import 'auto_record_orchestrator_factories.dart';
import 'trip_recording_provider.dart';

part 'auto_record_orchestrator.g.dart';

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
@Riverpod(keepAlive: true)
class AutoRecordOrchestrator extends _$AutoRecordOrchestrator {
  /// Active coordinators keyed by vehicle id. Read by tests through
  /// [activeVehicleIdsForTest]; production callers do not interact
  /// directly.
  final Map<String, _OrchestratorEntry> _entries =
      <String, _OrchestratorEntry>{};

  /// Observes app resume so the foreground-active arming fallback
  /// (#2282 concern 1) can fire while the app is in front. Owned here +
  /// disposed in [onDispose]; mirrors the [NearestWidgetRefresh] pattern.
  AppLifecycleListener? _lifecycle;

  @override
  void build() {
    // #2282 concern 1 — arm a foreground-active direct connect on every
    // resume. While the app is in front the (currently-disabled)
    // foreground service can't deliver the `AdapterConnected` that
    // starts the state machine, so each resume asks every active
    // coordinator to open a direct connect to its paired adapter from
    // the live engine. Idempotent on the coordinator side (no-op when a
    // session is already held or a trip is recording), so a rapid
    // background→foreground bounce never double-arms.
    //
    // `AppLifecycleListener` needs `WidgetsBinding.instance`; in a plain
    // unit test (no binding) accessing it throws. Guard so the
    // orchestrator's vehicle-diff + arming logic stays testable without
    // a widget binding — the resume hook simply isn't wired there, and
    // the `debugArmForegroundActive` seam drives the same path.
    if (_lifecycle == null) {
      try {
        _lifecycle = AppLifecycleListener(
          onResume: () => unawaited(_armForegroundActiveAll()),
        );
      } catch (e, st) {
        debugPrint(
          'AutoRecordOrchestrator: AppLifecycleListener unavailable '
          '(no WidgetsBinding?) — foreground-active resume arming not '
          'wired: $e\n$st',
        );
      }
    }
    // Watch the central master gate (#1373 phase 3d). Any flip rebuilds
    // this provider and re-runs the diff against the current vehicle
    // list — when the gate goes off the diff sees an empty `wanted`
    // set and tears down every active coordinator; when it flips back
    // on the diff re-arms the eligible vehicles.
    //
    // #1681 — watch the `featureFlagsProvider` AsyncNotifier directly
    // (one dependency hop) rather than the derived `enabledFeatures`
    // view: a `keepAlive` orchestrator with no external listener
    // rebuilds reliably on a direct dependency change, and the diff
    // below reads the resolved set via `enabledFeaturesProvider`.
    ref.watch(featureFlagsProvider);

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
    ref.onDispose(() {
      _lifecycle?.dispose();
      _lifecycle = null;
      unawaited(_disposeAll());
    });
  }

  /// Ask every active coordinator to attempt a foreground-active direct
  /// connect (#2282 concern 1). Sequenced through each entry; failures
  /// are isolated so one coordinator's connect error can't abort the
  /// others. Best-effort and idempotent — see [armForegroundActive].
  Future<void> _armForegroundActiveAll() async {
    for (final entry in _entries.values.toList()) {
      try {
        await entry.coordinator.armForegroundActive();
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: {
          'where': 'AutoRecordOrchestrator: foreground arm failed',
          'mac': entry.armedMac,
        }));
      }
    }
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

  /// Test seam — drives the foreground-active arming path the production
  /// [AppLifecycleListener.onResume] triggers (#2282 concern 1). A unit
  /// test can't fire a real resume, so it calls this directly.
  @visibleForTesting
  Future<void> debugArmForegroundActive() => _armForegroundActiveAll();

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
      } else if (wantedProfile.autoRecordAdapterMac != entry.value.armedMac) {
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
    // Central master gate (#1373 phase 3d, cascading-disable #1447).
    // The per-vehicle [VehicleProfile.autoRecord] bool stays — each
    // vehicle keeps its own opt-in — but this central feature is
    // consulted FIRST. Routing through `isEffectivelyEnabled` means
    // disabling the parent (`Feature.obd2TripRecording`) also tears
    // down every coordinator, regardless of the stored autoRecord
    // value, so the user disabling consumption tracking gets a clean
    // shutdown of the whole hands-free chain.
    final manifest = ref.read(featureManifestProvider);
    final enabled = ref.read(enabledFeaturesProvider);
    final centralEnabled = isEffectivelyEnabled(
      Feature.autoRecord,
      manifest,
      enabled,
    );
    if (!centralEnabled) return false;
    if (!p.autoRecord) return false;
    final mac = p.autoRecordAdapterMac;
    if (mac == null || mac.isEmpty) return false;
    return true;
  }

  _OrchestratorEntry? _buildEntry(VehicleProfile profile) {
    final mac = profile.autoRecordAdapterMac;
    if (mac == null || mac.isEmpty) return null;

    final listenerFactory = ref.read(autoRecordListenerFactoryProvider);
    final sessionOpener = ref.read(autoRecordSessionOpenerFactoryProvider);
    // #2282 concern 1 — the foreground-active arm uses a DIRECT connect
    // (no scan) so it wakes ELM327 clones that stop advertising in
    // standby while the app is in front.
    final foregroundOpener =
        ref.read(autoRecordForegroundSessionOpenerFactoryProvider);

    final listener = listenerFactory();
    final coordinator = AutoTripCoordinator(
      listener: listener,
      startTrip: (Obd2Service service) async {
        // Phase 2b-3 — hand the live OBD2 session to the trip recorder
        // through the unified [TripRecording.startTrip] entry point
        // (which routes to [start] internally and threads
        // `automatic: true` per the seam landed in #1531). Going via
        // `startTrip` rather than calling `start` directly means:
        //   - vehicle-id resolution from the active profile happens
        //     centrally (no duplicated lookup in the orchestrator)
        //   - the "already recording" guard short-circuits before
        //     the recorder takes ownership of the session
        //   - the typed [StartTripOutcome] flows back to the
        //     coordinator's classifier as-is, no string synthesis.
        // The recorder takes ownership of the session; the
        // coordinator's pointer has already been nulled out before
        // this callback fires.
        return ref
            .read(tripRecordingProvider.notifier)
            .startTrip(service: service, automatic: true);
      },
      stopAndSaveAutomatic: () async {
        await ref.read(tripRecordingProvider.notifier).stopAndSaveAutomatic();
      },
      sessionOpener: sessionOpener,
      foregroundSessionOpener: foregroundOpener,
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
    // #2282 concern 2 — request POST_NOTIFICATIONS BEFORE arming so the
    // Android 13+ runtime prompt appears at a moment the user
    // understands ("I just enabled hands-free recording"). Graceful on
    // denial: a `false` (or a thrown probe) never blocks arming — the
    // foreground service simply runs without a visible notification, and
    // on iOS / Android ≤ 12 the probe reports "may post" with no prompt.
    try {
      final granted =
          await ref.read(obd2PermissionsProvider).requestNotifications();
      if (!granted) {
        debugPrint(
          'AutoRecordOrchestrator: POST_NOTIFICATIONS denied (mac='
          '${entry.armedMac}) — arming anyway, notification silenced',
        );
      }
    } catch (e, st) {
      debugPrint(
        'AutoRecordOrchestrator: notification permission probe failed '
        '(mac=${entry.armedMac}): $e\n$st',
      );
    }
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
/// orchestrator detect a `obd2AdapterMac` change cheaply — the
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
