// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../core/logging/error_logger.dart';
import '../../consumption/data/obd2/broken_map_belief.dart';
import '../../consumption/data/obd2/broken_map_detector.dart';
import '../../consumption/data/obd2/obd2_connection_service.dart';
import '../../consumption/data/obd2/obd2_read_telemetry.dart';
import '../../consumption/data/obd2/obd2_service.dart';
import '../../consumption/data/obd2/obd_adapter_blocklist.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../domain/entities/vin_data.dart';
import 'vin_auto_populator.dart';
import 'vin_decoder.dart';

/// Outcome of [VinAdapterPairAutoPopulator.run] (#1399).
class VinAdapterPairAutoPopulationOutcome {
  /// Final profile to persist. Null when the populator could not
  /// connect / could not read the VIN — in that case the caller
  /// leaves the profile untouched.
  final VehicleProfile? profile;

  /// Optional snackbar payload. Non-null only when a populated user
  /// field disagrees with the freshest decoded value, so the UI can
  /// surface "Detected: {summary}. Apply?".
  final String? conflictSummary;

  /// True when at least one user-facing field was auto-filled.
  final bool appliedAny;

  /// True when the run hit the live ECU (we were able to read the VIN).
  /// Distinguishes "couldn't connect" from "connected but no VIN" —
  /// only the latter indicates a pre-2005 vehicle.
  final bool readVin;

  /// True when the vPIC online endpoint was actually queried (consent
  /// was granted AND the call succeeded). Surfaces an opt-in nudge in
  /// the UI when the user hasn't consented and only offline data was
  /// available.
  final bool didDecodeOnline;

  /// Latest fuzzy belief about whether the paired adapter's MAP sensor
  /// reads correctly (#1423 phase 2). Null when no [BrokenMapDetector]
  /// was wired into the populator (i.e. existing call sites that
  /// haven't opted into the detector yet) or when the probe couldn't
  /// run (no service, exception swallowed). Phase 4 will swap the
  /// `prior` for a recall from the persistent blocklist; phase 5
  /// surfaces the value in the diagnostic overlay.
  final BrokenMapBelief? brokenMapBelief;

  const VinAdapterPairAutoPopulationOutcome({
    required this.profile,
    required this.conflictSummary,
    required this.appliedAny,
    required this.readVin,
    required this.didDecodeOnline,
    this.brokenMapBelief,
  });

  /// Sentinel for "we couldn't pair / read anything". The caller
  /// leaves the existing profile in place.
  factory VinAdapterPairAutoPopulationOutcome.aborted() =>
      const VinAdapterPairAutoPopulationOutcome(
        profile: null,
        conflictSummary: null,
        appliedAny: false,
        readVin: false,
        didDecodeOnline: false,
        brokenMapBelief: null,
      );
}

/// Orchestrates the post-pair VIN-driven auto-population flow (#1399).
///
/// 1. Connects to the freshly-paired adapter via [Obd2ConnectionService].
/// 2. Reads the VIN through Mode 09 PID 02 ([Obd2Service.readVin]).
/// 3. Discovers supported PIDs and (if PID 0x51 is in the set) reads
///    the live ECU fuel type ([Obd2Service.readFuelType]).
/// 4. Decodes the VIN through [VinDecoder] — gated on the
///    `vinOnlineDecode` GDPR consent via the wired [VinDecoder]
///    instance's `allowOnlineLookup` field.
/// 5. Merges the decoded fields into the existing [VehicleProfile]
///    via [VinAutoPopulator] — never silently overwrites a field the
///    user has already entered.
/// 6. Disconnects from the adapter.
///
/// Errors at every step are swallowed and surfaced through
/// [errorLogger.log]; the method always returns a typed outcome the
/// UI can act on. Never throws.
class VinAdapterPairAutoPopulator {
  final Obd2ConnectionService connection;
  final VinDecoder decoder;
  final VinAutoPopulator populator;

  /// Optional broken-MAP detector (#1423 phase 2). When provided, the
  /// populator runs one idle probe round against the adapter after the
  /// VIN read succeeds and attaches the resulting belief to the
  /// outcome. Null in legacy call sites that haven't opted in — the
  /// flow then behaves exactly as before.
  final BrokenMapDetector? brokenMapDetector;

  /// Optional persistent broken-MAP blocklist (#1423 phase 4). When
  /// provided AND the connected adapter reports a stable ELM ID via
  /// `ATI` (captured into [Obd2Service.adapterFirmware]), the
  /// populator recalls a prior belief BEFORE running the probe — a
  /// known-broken adapter (recalled confidence > 0.7) short-circuits
  /// the probe and surfaces immediately. After the probe runs, beliefs
  /// crossing the same threshold are persisted back to the blocklist
  /// so future sessions inherit the warning. Null in tests / legacy
  /// call sites that haven't opted in.
  final ObdAdapterBlocklist? blocklist;

  /// Threshold above which a recalled / freshly-probed belief is
  /// considered actionable enough to:
  ///   1. short-circuit the next pair-time probe (recall path), and
  ///   2. land in the persistent blocklist for future sessions
  ///      (probe-result path).
  /// Mirrors [brokenMapBlocklistThreshold] in `consumption_providers`
  /// — kept here as a private constant rather than imported to avoid
  /// pulling in the providers layer from a data-layer class.
  static const double _blocklistThreshold = 0.7;

  VinAdapterPairAutoPopulator({
    required this.connection,
    required this.decoder,
    this.populator = const VinAutoPopulator(),
    this.brokenMapDetector,
    this.blocklist,
  });

  /// Run the post-pair flow against [pairedAdapterMac], merging into
  /// [profile]. The returned outcome carries either a non-null updated
  /// profile (caller persists it) or an `aborted` sentinel.
  Future<VinAdapterPairAutoPopulationOutcome> run({
    required String pairedAdapterMac,
    required VehicleProfile profile,
  }) async {
    Obd2Service? service;
    try {
      service = await connection.connectByMac(pairedAdapterMac);
      if (service == null) {
        return VinAdapterPairAutoPopulationOutcome.aborted();
      }

      final vin = await service.readVin();
      if (vin == null) {
        // Connected but the ECU didn't return a VIN — nothing to
        // populate. The caller still gets a meaningful no-op.
        return VinAdapterPairAutoPopulationOutcome.aborted();
      }

      // Discover supported PIDs so we only ask for 0x51 when the ECU
      // claims to implement it. Falls back to a blind read on cache
      // miss — `readFuelType` will return null on NO DATA either way.
      String? pidFuelType;
      try {
        final supported = await service.discoverSupportedPids();
        if (supported.isEmpty || supported.contains(0x51)) {
          pidFuelType = await service.readFuelType();
        }
      } catch (e, st) {
        await errorLogger.log(
          ErrorLayer.background,
          e,
          st,
          context: const {
            'op': 'vinAdapterPairAutoPopulator.readFuelType',
          },
        );
      }

      VinData? decoded;
      try {
        decoded = await decoder.decode(vin);
      } catch (e, st) {
        await errorLogger.log(
          ErrorLayer.background,
          e,
          st,
          context: const {
            'op': 'vinAdapterPairAutoPopulator.decodeVin',
          },
        );
      }

      final result = populator.populate(
        profile: profile,
        vin: vin,
        decoded: decoded,
        pidFuelType: pidFuelType,
      );

      // Optional broken-MAP idle probe (#1423 phase 2 + 4). Runs
      // against the live service before disconnect; never derails the
      // pair flow on failure. Diesel branch is selected from whichever
      // fuel-type signal we already resolved — PID 0x51 wins, the
      // populator's merged result wins next, then nothing (default
      // petrol).
      //
      // Phase 4: when a [blocklist] is wired AND the adapter reported
      // a stable firmware id, recall the prior belief BEFORE probing.
      // A known-broken adapter (recalled confidence > 0.7) skips the
      // probe entirely — we already know it's suspect, surface the
      // warning immediately and let the user act. After the probe
      // completes (or short-circuits), beliefs crossing the threshold
      // are persisted back so future pair attempts inherit the
      // warning.
      BrokenMapBelief? brokenMapBelief;
      final detector = brokenMapDetector;
      final adapterId = service.adapterFirmware;
      if (detector != null) {
        try {
          // Recall path — short-circuit when the adapter is on the
          // blocklist with actionable confidence.
          final blocklistRef = blocklist;
          if (blocklistRef != null &&
              adapterId != null &&
              adapterId.isNotEmpty) {
            final priorConfidence = await blocklistRef.recall(adapterId);
            if (priorConfidence != null &&
                priorConfidence > _blocklistThreshold) {
              // #1424 — the blocklist stores a single scalar
              // (the prior posterior mean). Reconstruct a Beta
              // posterior from it: pick a nominal pseudo-count of
              // 10 so the recalled belief has a reasonable
              // concentration without claiming more evidence than
              // we actually have. observationCount: 0 still
              // distinguishes "hydrated from a prior session"
              // from a freshly-probed belief whose updater would
              // have bumped the count.
              const pseudoCount = 10.0;
              brokenMapBelief = BrokenMapBelief(
                alpha: priorConfidence * pseudoCount,
                beta: (1.0 - priorConfidence) * pseudoCount,
                observationCount: 0,
                lastUpdate: DateTime.now(),
                lastTrigger: BrokenMapReason.priorObservation,
              );
            }
          }

          // Probe path — only when the recall didn't short-circuit.
          if (brokenMapBelief == null) {
            final fuelKey = (pidFuelType ??
                    result.profile.preferredFuelType ??
                    result.profile.detectedFuelType ??
                    '')
                .toLowerCase();
            final isDiesel = fuelKey.contains('diesel');
            brokenMapBelief = await detector.probe(
              service,
              isDiesel: isDiesel,
              prior: const BrokenMapBelief(),
              now: DateTime.now(),
            );

            // Persist back to the blocklist when the freshly-probed
            // confidence crosses the actionable threshold. Same
            // adapter id used by the recall path above so future
            // sessions short-circuit instead of re-probing.
            if (blocklistRef != null &&
                adapterId != null &&
                adapterId.isNotEmpty &&
                brokenMapBelief.pointEstimate > _blocklistThreshold) {
              await blocklistRef.recordBelief(
                adapterId,
                brokenMapBelief.pointEstimate,
              );
            }
          }
        } catch (e, st) {
          await errorLogger.log(
            ErrorLayer.background,
            e,
            st,
            context: const {
              'op': 'vinAdapterPairAutoPopulator.brokenMapProbe',
            },
          );
        }
      }

      return VinAdapterPairAutoPopulationOutcome(
        profile: result.profile,
        conflictSummary: result.conflictSummary,
        appliedAny: result.appliedAny,
        readVin: true,
        didDecodeOnline: result.didDecodeOnline,
        brokenMapBelief: brokenMapBelief,
      );
    } catch (e, st) {
      // #2953 — pairing an adapter with the engine OFF is an EXPECTED user
      // condition: `connectByMac` propagates the typed [Obd2AdapterUnresponsive]
      // here, which the field log #30 ERROR-spooled. Route the outer catch
      // through the shared connect-transient de-noiser so an expected
      // engine-off condition breadcrumbs while a GENUINE fault (permission /
      // clone init) still ERROR-logs on the background layer.
      recordObd2ConnectTransient(e, st,
          where: 'vinAdapterPairAutoPopulator.run',
          layer: ErrorLayer.background);
      return VinAdapterPairAutoPopulationOutcome.aborted();
    } finally {
      try {
        await service?.disconnect();
      } catch (e, st) {
        // Disconnect failures aren't actionable here — the next pair
        // attempt re-runs the connect path, which handles a stuck
        // transport — but log so a recurring field failure isn't
        // invisible (#1682). Routed through errorLogger to match the
        // rest of this file rather than a raw debugPrint.
        await errorLogger.log(
          ErrorLayer.background,
          e,
          st,
          context: const {
            'op': 'vinAdapterPairAutoPopulator.disconnect',
          },
        );
      }
    }
  }
}
