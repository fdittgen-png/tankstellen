import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../consumption/data/obd2/obd2_connection_service.dart';
import '../data/vin_adapter_pair_auto_populator.dart';
import 'vin_decoder_provider.dart';

/// Provider for the post-pair VIN auto-population orchestrator (#1399).
///
/// Exposed as a plain [Provider] (not `@riverpod`) so widget tests can
/// override it with a fake [VinAdapterPairAutoPopulator] subclass — the
/// edit-vehicle-screen tests pre-canned a fake [VinReaderService] this
/// way and we follow the same shape.
final vinAdapterPairAutoPopulatorProvider =
    Provider<VinAdapterPairAutoPopulator>(
  (ref) => VinAdapterPairAutoPopulator(
    connection: ref.watch(obd2ConnectionProvider),
    decoder: ref.watch(consentAwareVinDecoderProvider),
  ),
);
