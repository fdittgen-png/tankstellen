import 'dart:async';

import '../../../core/logging/error_logger.dart';
import '../../consumption/data/obd2/elm327_protocol.dart';
import '../../consumption/data/obd2/obd2_service.dart';

/// Outcome of an [Obd2VinReader.read] call (#1162).
///
/// Either [vin] is non-null and [failure] is null (success), or
/// [vin] is null and [failure] carries the reason.
class ObdVinResult {
  /// The decoded 17-character VIN, or null when the read failed.
  final String? vin;

  /// Populated when [vin] is null; describes why the read failed so
  /// the UI can show a meaningful message (e.g. "pre-2005 vehicle").
  final ObdVinFailureReason? failure;

  const ObdVinResult.success(String this.vin) : failure = null;

  const ObdVinResult.failure(ObdVinFailureReason this.failure) : vin = null;

  /// `true` when the VIN was decoded successfully.
  bool get isSuccess => vin != null;
}

/// Why an [Obd2VinReader.read] call failed (#1162).
enum ObdVinFailureReason {
  /// ELM responded with `NO DATA` / `?` / empty — the ECU does not
  /// implement Mode 09 PID 02. Most pre-2005 vehicles fall here.
  unsupported,

  /// Bytes came back but [Elm327Protocol.parseVin] could not decode a
  /// 17-character VIN. Usually a corrupted frame or a non-standard
  /// reply format.
  malformed,

  /// The command did not return within the configured timeout.
  timeout,

  /// Any other transport-level error (Bluetooth dropped mid-read,
  /// adapter bug, etc.). Logged via [errorLogger] for diagnosis.
  io,
}

/// Reads the VIN from a paired OBD2 adapter via Mode 09 PID 02 (#1162).
///
/// Used by the vehicle-edit screen to auto-fill the VIN field once the
/// user has paired an adapter for that vehicle, so the existing VIN
/// decoder pipeline (#812 phase 2) can pre-fill make/model/year/engine
/// without forcing the user to type 17 characters.
///
/// Bounded by [timeout] (3 seconds by default) so a stuck adapter
/// can't hang the UI. Never throws — every error path produces an
/// [ObdVinResult.failure] with a typed reason.
class Obd2VinReader {
  /// The connected [Obd2Service] used to send the Mode 09 PID 02
  /// command. The reader never opens / closes the underlying transport
  /// — that's the caller's responsibility.
  final Obd2Service service;

  /// Maximum time to wait for the response. Mirrors the bounded shape
  /// used by [TripRecordingController._readVinOnce] so a failing
  /// adapter degrades the UX rather than blocking it.
  final Duration timeout;

  Obd2VinReader({
    required this.service,
    this.timeout = const Duration(seconds: 3),
  });

  /// Send Mode 09 PID 02 and decode the response.
  ///
  /// Routes every error path through [errorLogger.log] under
  /// [ErrorLayer.background] so issues are diagnosable; never throws
  /// to the caller.
  Future<ObdVinResult> read() async {
    try {
      final raw = await service
          .sendCommand(Elm327Protocol.vinCommand)
          .timeout(timeout);
      final parsed = Elm327Protocol.parseVin(raw);
      if (parsed != null && parsed.isNotEmpty) {
        return ObdVinResult.success(parsed);
      }
      // parseVin returns null on NO DATA / ? / empty cleaned response
      // and on bytes-but-fewer-than-17-printable-chars. Distinguish:
      //   - empty / NO DATA / ? → unsupported (pre-2005 ECU)
      //   - anything else → malformed (frame corruption)
      if (_looksUnsupported(raw)) {
        return const ObdVinResult.failure(ObdVinFailureReason.unsupported);
      }
      return const ObdVinResult.failure(ObdVinFailureReason.malformed);
    } on TimeoutException catch (e, st) {
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: const {'op': 'obd2VinReader.read', 'reason': 'timeout'},
      );
      return const ObdVinResult.failure(ObdVinFailureReason.timeout);
    } catch (e, st) {
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: const {'op': 'obd2VinReader.read', 'reason': 'io'},
      );
      return const ObdVinResult.failure(ObdVinFailureReason.io);
    }
  }

  /// Heuristic for "the ECU said NO DATA" (or returned nothing at all).
  /// Matches the same set of markers [Elm327Parsers.cleanResponse]
  /// treats as a non-answer; a hit means we should classify the read
  /// as [ObdVinFailureReason.unsupported] rather than `malformed`.
  static bool _looksUnsupported(String raw) {
    final trimmed = raw
        .replaceAll('>', '')
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .trim();
    if (trimmed.isEmpty) return true;
    return trimmed.contains('NO DATA') ||
        trimmed.contains('UNABLE TO CONNECT') ||
        trimmed.contains('?');
  }
}
