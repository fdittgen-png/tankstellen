import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../consumption/data/obd2/elm327_protocol.dart';
import '../../consumption/data/obd2/obd2_service.dart';

part 'obd2_vin_reader.g.dart';

/// Factory signature for [Obd2VinReader]. Lives on the riverpod
/// container so widget tests can swap in a fake reader without going
/// through the full `Obd2Service` plumbing.
typedef Obd2VinReaderFactory = Obd2VinReader Function(Obd2Service service);

/// Default factory — returns a real [Obd2VinReader] backed by the live
/// [Obd2Service] handed in by the caller. Production wiring; tests
/// override [obd2VinReaderFactoryProvider] to inject a stub that
/// captures the call without touching Bluetooth.
@Riverpod(keepAlive: true)
Obd2VinReaderFactory obd2VinReaderFactory(Ref ref) =>
    (Obd2Service service) => Obd2VinReader(service);

/// Thin reader wrapper around an already-connected [Obd2Service] that
/// performs a single Mode 09 PID 02 (`0902`) request and parses the
/// response into a 17-character VIN (#1162).
///
/// Why a separate class instead of calling the existing
/// `OnboardingObd2Connector.readVin` from the vehicle edit screen?
///   * The onboarding connector is owned by the setup feature; pulling
///     the vehicle edit screen across that dependency boundary would
///     entangle two unrelated flows (first-run wizard vs. profile
///     editing).
///   * A dedicated reader gives the vehicle feature its own seam for
///     the auto-read button (#1162). Tests for that button mock this
///     class instead of pulling in the onboarding step's wiring.
///
/// The reader does not own the adapter connection. The caller obtains
/// a connected [Obd2Service] (typically via the existing adapter
/// picker) and hands it in. On any failure path — timeout, NO DATA
/// reply, malformed payload, exception — [readVin] returns `null` and
/// emits a `debugPrint` with the failure context. No silent catches.
class Obd2VinReader {
  /// Creates a reader bound to [service]. The default 3 s [timeout]
  /// matches the upper bound a frozen ELM327 should have already
  /// reported NO DATA within; longer would block the UI thread on a
  /// dead adapter.
  Obd2VinReader(
    this._service, {
    Duration timeout = const Duration(seconds: 3),
  }) : _timeout = timeout;

  final Obd2Service _service;
  final Duration _timeout;

  /// Send `0902` to the adapter, parse the multi-frame response, and
  /// return the VIN. Returns `null` for all failure paths:
  ///
  ///   * the call did not complete within [_timeout];
  ///   * the adapter replied `NO DATA` / unsupported (parser returns
  ///     null);
  ///   * the response was malformed (parser returns null);
  ///   * the call threw (e.g. adapter dropped mid-request).
  ///
  /// Every failure logs the context via [debugPrint] so a user-reported
  /// "the button does nothing" issue can be diagnosed from a log
  /// capture without re-instrumenting the call site.
  Future<String?> readVin() async {
    try {
      final raw = await _service
          .sendCommand(Elm327Protocol.vinCommand)
          .timeout(_timeout, onTimeout: () => '');
      if (raw.isEmpty) {
        debugPrint('Obd2VinReader.readVin: timed out after $_timeout');
        return null;
      }
      final vin = Elm327Protocol.parseVin(raw);
      if (vin == null) {
        debugPrint(
            'Obd2VinReader.readVin: parser returned null '
            '(NO DATA / unsupported / malformed) for raw: $raw');
        return null;
      }
      return vin;
    } catch (e, st) {
      debugPrint('Obd2VinReader.readVin failed: $e\n$st');
      return null;
    }
  }
}
