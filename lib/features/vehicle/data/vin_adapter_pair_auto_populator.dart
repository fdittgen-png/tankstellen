import 'dart:async';

import '../../../core/logging/error_logger.dart';
import '../../consumption/data/obd2/broken_map_belief.dart';
import '../../consumption/data/obd2/broken_map_detector.dart';
import '../../consumption/data/obd2/obd2_connection_service.dart';
import '../../consumption/data/obd2/obd2_service.dart';
import '../domain/entities/vehicle_profile.dart';
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

  VinAdapterPairAutoPopulator({
    required this.connection,
    required this.decoder,
    this.populator = const VinAutoPopulator(),
    this.brokenMapDetector,
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

      // Optional broken-MAP idle probe (#1423 phase 2). Runs against
      // the live service before disconnect; never derails the pair
      // flow on failure. Diesel branch is selected from whichever
      // fuel-type signal we already resolved — PID 0x51 wins, the
      // populator's merged result wins next, then nothing (default
      // petrol). Phase 4 will swap the empty `prior` for a recall
      // from the persistent blocklist.
      BrokenMapBelief? brokenMapBelief;
      final detector = brokenMapDetector;
      if (detector != null) {
        try {
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
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: const {
          'op': 'vinAdapterPairAutoPopulator.run',
        },
      );
      return VinAdapterPairAutoPopulationOutcome.aborted();
    } finally {
      try {
        await service?.disconnect();
      } catch (_) {
        // Disconnect failures aren't actionable here. The next pair
        // attempt re-runs the connect path which handles a stuck
        // transport.
      }
    }
  }
}
