import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/error_logger.dart';
import '../../consumption/data/obd2/obd2_connection_service.dart';
import '../data/obd2_vin_reader.dart';

/// Service shape exposed to the vehicle-edit UI for "Read VIN from car"
/// (#1162).
///
/// Defined as an abstract class so widget tests can swap in a fake
/// implementation without standing up the real Bluetooth stack. The
/// production implementation [Obd2VinReaderService] connects to the
/// paired adapter, runs [Obd2VinReader.read], and disconnects.
abstract class VinReaderService {
  /// Read the VIN from the adapter currently advertising itself under
  /// [pairedAdapterMac]. Implementations are responsible for opening
  /// and closing the transport — callers just await an [ObdVinResult].
  Future<ObdVinResult> readVin({required String pairedAdapterMac});
}

/// Production [VinReaderService] backed by [Obd2ConnectionService] +
/// [Obd2VinReader] (#1162).
///
/// The reader is split from the service so unit tests can drive
/// [Obd2VinReader.read] against a fake [Obd2Service] without the
/// connection plumbing — see `obd2_vin_reader_test.dart`. Widget
/// tests for the vehicle-edit screen override the service-level
/// provider directly.
class Obd2VinReaderService implements VinReaderService {
  final Obd2ConnectionService connection;

  Obd2VinReaderService({required this.connection});

  @override
  Future<ObdVinResult> readVin({required String pairedAdapterMac}) async {
    // #1351 — connect to the *paired* adapter by MAC. The previous
    // implementation called [Obd2ConnectionService.connectBest] which
    // depends on a fresh scan having run beforehand and otherwise
    // either returns null OR connects to the wrong adapter (the
    // highest-RSSI candidate from a stale [_lastRanked]). The vehicle-
    // edit screen does NOT run a scan before this button is tapped,
    // so [connectBest] could not work in practice. [connectByMac]
    // owns its own short scan window and short-circuits on the first
    // candidate matching [pairedAdapterMac] — exactly what we want.
    try {
      final service = await connection.connectByMac(pairedAdapterMac);
      if (service == null) {
        return const ObdVinResult.failure(ObdVinFailureReason.io);
      }
      try {
        final reader = Obd2VinReader(service: service);
        return await reader.read();
      } finally {
        await service.disconnect();
      }
    } catch (e, st) {
      // [Obd2VinReader.read] swallows its own errors; this catch is for
      // the connect path itself (permissions, scan timeout, adapter
      // unresponsive). Each is logged at the lower layer; we just
      // surface a typed failure to the UI. Logged here so the failed
      // connect attempt is still diagnosable.
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: const {
          'op': 'vinReaderService.readVin',
          'reason': 'connect',
        },
      );
      return const ObdVinResult.failure(ObdVinFailureReason.io);
    }
  }
}

/// Riverpod provider for the VIN-from-car reader (#1162).
///
/// Plain provider (not `@riverpod`) so widget tests can override it
/// with a fake via `overrideWithValue` without touching the connection
/// service. Default value pulls [obd2ConnectionProvider] from the
/// container — production usage wires through to the real Bluetooth
/// stack.
final vinReaderServiceProvider = Provider<VinReaderService>(
  (ref) => Obd2VinReaderService(
    connection: ref.watch(obd2ConnectionProvider),
  ),
);
