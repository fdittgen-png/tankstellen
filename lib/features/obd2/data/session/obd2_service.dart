// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../vehicle/domain/entities/reference_vehicle.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../protocol/adapter_capability.dart';
import '../auto_record_trace_log.dart';
import '../transport/bluetooth_obd2_transport.dart';
import '../protocol/elm327_adapter.dart';
import '../protocol/elm327_precision_pids.dart';
import '../protocol/elm327_protocol.dart';
import '../../domain/obd2_engine_evidence.dart';
import '../../domain/vehicle_power_state.dart';
import '../../domain/fuel_rate_estimator.dart' as estimator;
import '../negotiated_protocol_cache.dart';
import '../transport/obd2_atpc_teardown.dart';
import '../obd2_breadcrumb_collector.dart';
import '../protocol/obd2_can_frame_stream.dart';
import '../obd2_comm_diagnostics.dart';
import '../obd2_connect_trace.dart';
import '../obd2_connect_trace_log.dart';
import '../../domain/obd2_connection_errors.dart';
import '../obd2_read_telemetry.dart';
import 'obd2_service_session.dart';
import '../obd2_debug_session.dart';
import 'obd2_fuel_rate_reader.dart';
import 'obd2_odometer_reader.dart';
import '../transport/obd2_transport.dart';
import '../protocol/oem_pid_table.dart';
import '../supported_pids_cache.dart';
import '../protocol/supported_pids_probe.dart' show kObd2ProtocolSearchTimeout;
import 'supported_pids_resolver.dart';
import '../../../../core/logging/error_logger.dart';
import '../../../../core/telemetry/health_counters.dart';

// #3035 — re-export the tri-state `0100` probe outcome so the connection
// layer (which imports this service) gates `ignitionOff` on [busProbe]
// without reaching into the resolver directly.
export '../protocol/supported_pids_probe.dart' show Obd2BusProbeResult;

// Re-export the pure-math estimator + stoichiometric constants so
// callers that only need the math (e.g. [TripRecordingController]'s
// cached live sampler) can import one file instead of chasing statics
// on [Obd2Service]. New callers should import `fuel_rate_estimator.dart`
// directly; the static forwarders on [Obd2Service] stay for backwards
// compatibility with pre-#563 call sites.
export '../../domain/fuel_rate_estimator.dart'
    show
        kPetrolAfr,
        kDieselAfr,
        kPetrolDensityGPerL,
        kDieselDensityGPerL,
        kDefaultEngineDisplacementCc,
        kDefaultVolumetricEfficiency,
        resolveAfrDensity, // #2432 — fuel-type AFR/density lookup
        effectiveAfrForPhi, // #2456/#3426 — equivalence-ratio-φ effective AFR
        applyFuelTrimCorrection,
        estimateFuelRateLPerHourFromMap;

part 'obd2_service_link.dart';
part 'obd2_service_init.dart';
part 'obd2_service_connect.dart';
part 'obd2_service_reads.dart';

/// What the bounded wake window observed on the FIRST init command of a
/// fresh connect (#2268 concern 2). Drives the per-MAC observed-outcome
/// wake cache (#2268 concern 3): the connection service records
/// `wakeNeeded` only on a [wokeAfterNudge] outcome, and records
/// `never-needed` only on an [answeredImmediately] outcome.
enum WakeObservation {
  /// The wake window did not run — either no [WakePolicy] was active for
  /// this connect or it was suppressed by the cache. The connect path
  /// has no evidence either way, so the cache must NOT be updated.
  notRun,

  /// The wake window ran and the FIRST command answered on the first
  /// attempt — this adapter did not need waking on this connect. Strong
  /// evidence the MAC never needs the window.
  answeredImmediately,

  /// The wake window ran, the FIRST command timed out / threw, and a
  /// re-send after the longer settle then succeeded — observed proof the
  /// adapter was asleep and the window recovered it.
  wokeAfterNudge,

  /// The wake window ran and every attempt (original + all nudges)
  /// failed. No positive evidence — connect will fail downstream; the
  /// cache must NOT be updated on a failed connect.
  failed,
}

/// High-level OBD-II service for reading vehicle data.
///
/// Wraps [Obd2Transport] and [Elm327Protocol] to provide a clean API
/// for reading odometer, speed, and other vehicle parameters.
///
/// Also implements [Obd2RawCommandPort] (#1401 phase 3 / #1423 phase 2)
/// — the narrow facade OEM tables and the broken-MAP detector accept.
/// The [sendRaw] method delegates to [sendCommand]; production callers
/// pass the live service unchanged, tests pass a 5-line fake.
///
/// #3760 — decomposed under the #1680 file-length cap into `part`
/// mixins (move-only): the link/send surface (`obd2_service_link.dart`),
/// the connect-time init support (`obd2_service_init.dart`), the
/// connect / disconnect lifecycle (`obd2_service_connect.dart`) and the
/// typed PID reads (`obd2_service_reads.dart`). This file keeps the
/// constructor-owned state and the static constants / forwarders.
class Obd2Service
    with
        _Obd2ServiceLink,
        _Obd2ServiceInit,
        _Obd2ServiceConnect,
        _Obd2ServiceReads
    implements Obd2RawCommandPort, Obd2FuelRateReads {
  @override
  final Obd2Transport _transport;

  /// Owns the #811 supported-PID concern — the persistent cache, the
  /// per-connection PID set, and the vehicle-key resolution that
  /// picks the cache slot. Extracted from this class in #1679; built
  /// in the constructor body so it can capture the [_send] tear-off.
  @override
  late final SupportedPidsResolver _pids;

  /// Optional fuel-rate diagnostic breadcrumb collector (#1395). When
  /// present, every PID 5E read + MAF read inside
  /// [readFuelRateLPerHour] is captured into a ring buffer the
  /// in-app diagnostic overlay can render. Null in production paths
  /// that don't need the trace (e.g. one-shot VIN reads); the trip
  /// recording controller wires it up at the start of each trip via
  /// the [breadcrumbCollector] setter. Typed as the
  /// [Obd2BreadcrumbRecorder] interface so production passes the
  /// Riverpod notifier (state-republishing) and unit tests pass the
  /// raw [Obd2BreadcrumbCollector].
  @override
  Obd2BreadcrumbRecorder? breadcrumbCollector;

  /// Persistent negotiated-protocol cache (#2261 concern 3). When
  /// present and [_protocolCacheKey] resolves, a warm connect replays
  /// `ATSP{n}` for the cached protocol instead of paying the multi-second
  /// `ATSP0` auto-search. Null in tests / configs that don't exercise it
  /// — connect then always runs the cold ATSP0 search, exactly as before.
  @override
  final NegotiatedProtocolCache? _protocolCache;

  /// Lookup key for [_protocolCache] — `adapterMac(:vin)`. Supplied by
  /// the owner so the data layer never resolves vehicle identity itself.
  @override
  final String? _protocolCacheKey;

  Obd2Service(
    this._transport, {
    SupportedPidsCache? pidsCache,
    String? vehicleFallbackKey,
    this._protocolCache,
    this._protocolCacheKey,
    this.breadcrumbCollector,
  }) {
    // #1916 — the supported-PIDs prime + discovery run during connect,
    // when the BLE link is least settled. Wrap their `_send` callback
    // with the same one-shot retry the init handshake now uses, so a
    // single lost write at trip-start doesn't reach the user as a
    // connect failure. After prime returns, the resolver only serves
    // the cached set (no further `_send`), so no live-polling call
    // sites pick up the wrapper.
    _pids = SupportedPidsResolver(
      send: (cmd) => _withConnectRetry(cmd, _send),
      // #3037 — the first `0100` probe uses the GENEROUS protocol-search read
      // window (~15 s) so the ELM327 auto-search resolves within ONE read,
      // instead of re-sending mid-search (which restarts the search).
      // Deliberately NOT wrapped in [_withConnectRetry]: that wrapper re-sends
      // on ANY throw INCLUDING a read TimeoutException, which for `0100` would
      // restart the protocol search — the exact #3037 bug. The probe itself
      // owns the bounded re-send, and ONLY on a genuine transport throw (a
      // failed write, where the command never reached the adapter so the
      // search never started), never on a timeout.
      searchSend: _sendWithProtocolSearchWindow,
      isConnected: () => _transport.isConnected,
      cache: pidsCache,
      vehicleFallbackKey: vehicleFallbackKey,
    );
  }

  /// #1916 — settle delay between the first connect-time send and its
  /// single retry. Matches the polling-loop value
  /// [TripRecordingController._transportRetryDelay] so the same
  /// transient-blip window is absorbed in both phases. Exposed as
  /// `@visibleForTesting` so the connect-retry unit test runs in
  /// milliseconds instead of waiting a real 150 ms per case.
  @visibleForTesting
  static Duration connectRetryDelay = const Duration(milliseconds: 150);

  /// Hard ceiling on the per-nudge wake settle (#2268 concern 2) so a
  /// mis-seeded [WakePolicy.wakeSettle] can never stall trip-start
  /// indefinitely. The window the connect path actually applies is
  /// `min(wakeSettle, wakeSettleCap)`.
  static const Duration wakeSettleCap = Duration(seconds: 3);

  /// Hard ceiling on [WakePolicy.maxNudges] (#2268 concern 2). One nudge
  /// is the realistic value (a single re-send after the adapter has had
  /// time to wake); the cap guards against a runaway seeded value
  /// turning the wake batch into an unbounded retry loop.
  static const int maxNudgeCap = 2;

  /// Test hook to scale the real wake-settle down to milliseconds so the
  /// concern-2 unit tests don't wait real seconds. Production keeps it at
  /// `1.0`. Multiplies the (already-capped) settle just before sleeping.
  @visibleForTesting
  static double wakeSettleScale = 1.0;

  /// Stoichiometric AFR for petrol / gasoline (#800). Approximately
  /// 14.7 kg of air per kg of fuel at perfect combustion.
  ///
  /// Backwards-compat forwarder for [kPetrolAfr] from
  /// `fuel_rate_estimator.dart` — kept so pre-#563 call sites
  /// (`Obd2Service.petrolAfr`) compile unchanged.
  static const double petrolAfr = estimator.kPetrolAfr;

  /// Stoichiometric AFR for diesel (#800). Slightly leaner burn than
  /// petrol — ~14.5 kg of air per kg of diesel.
  ///
  /// Backwards-compat forwarder for [kDieselAfr].
  static const double dieselAfr = estimator.kDieselAfr;

  /// Petrol density in g/L at ~15 °C (#800). Published range
  /// 720–775 g/L; 740 is the legacy Tankstellen constant.
  ///
  /// Backwards-compat forwarder for [kPetrolDensityGPerL].
  static const double petrolDensityGPerL = estimator.kPetrolDensityGPerL;

  /// Diesel density in g/L at ~15 °C (#800). Denser than petrol at
  /// ~820–845 g/L; 832 is the EN 590 reference point.
  ///
  /// Backwards-compat forwarder for [kDieselDensityGPerL].
  static const double dieselDensityGPerL = estimator.kDieselDensityGPerL;

  /// Pure-math fuel-trim correction factor (#813).
  ///
  /// Backwards-compat forwarder for
  /// [estimator.applyFuelTrimCorrection] from `fuel_rate_estimator.dart`.
  /// New call sites should import the top-level function directly.
  static double applyFuelTrimCorrection(
    double raw, {
    required double stft,
    required double ltft,
    double? stftBank2,
    double? ltftBank2,
  }) =>
      estimator.applyFuelTrimCorrection(
        raw,
        stft: stft,
        ltft: ltft,
        stftBank2: stftBank2,
        ltftBank2: ltftBank2,
      );

  /// Pure-math speed-density fuel-rate estimator (#800).
  ///
  /// Backwards-compat forwarder for
  /// [estimator.estimateFuelRateLPerHourFromMap] from
  /// `fuel_rate_estimator.dart`. New call sites should import the
  /// top-level function directly.
  static double? estimateFuelRateLPerHourFromMap({
    required double mapKpa,
    required double iatCelsius,
    required double rpm,
    required int engineDisplacementCc,
    required double volumetricEfficiency,
    double afr = estimator.kPetrolAfr,
    double fuelDensityGPerL = estimator.kPetrolDensityGPerL,
    List<EtaVCurvePoint> etaVCurve = const [],
    double? baroKpa,
    double? phi,
  }) =>
      estimator.estimateFuelRateLPerHourFromMap(
        mapKpa: mapKpa,
        iatCelsius: iatCelsius,
        rpm: rpm,
        engineDisplacementCc: engineDisplacementCc,
        volumetricEfficiency: volumetricEfficiency,
        afr: afr,
        fuelDensityGPerL: fuelDensityGPerL,
        etaVCurve: etaVCurve,
        baroKpa: baroKpa,
        phi: phi,
      );
}
